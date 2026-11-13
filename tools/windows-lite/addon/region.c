/* Scoped x64 application compatibility add-on for Sandboxie Plus 1.18.8. */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <wchar.h>
#include <stdint.h>
#include <string.h>

static DYNAMIC_TIME_ZONE_INFORMATION tokyo;
static USHORT dns_port;
static char dns_ticket[65];
static INT (WSAAPI *system_lookup)(PCWSTR, PCWSTR, const ADDRINFOW *, PADDRINFOW *);
static VOID (WSAAPI *system_free)(PADDRINFOW);
static DWORD (WINAPI *system_dynamic)(PDYNAMIC_TIME_ZONE_INFORMATION);
static DWORD (WINAPI *system_zone)(LPTIME_ZONE_INFORMATION);
static VOID (WINAPI *system_local)(LPSYSTEMTIME);

static DWORD WINAPI box_dynamic(PDYNAMIC_TIME_ZONE_INFORMATION zone) {
    if (!zone) return system_dynamic(zone);
    *zone = tokyo;
    return TIME_ZONE_ID_UNKNOWN; /* Tokyo has no current DST transition. */
}

static DWORD WINAPI box_zone(LPTIME_ZONE_INFORMATION zone) {
    if (!zone) return system_zone(zone);
    memcpy(zone, &tokyo, sizeof(*zone));
    return TIME_ZONE_ID_UNKNOWN;
}

static VOID WINAPI box_local(LPSYSTEMTIME local) {
    if (!local) { system_local(local); return; }
    SYSTEMTIME utc;
    GetSystemTime(&utc);
    SystemTimeToTzSpecificLocalTimeEx(&tokyo, &utc, local);
}

/* Protocol: UTF-8 DNS name line, then status/count followed by packed IPs.
   Only the broker, outside the box, knows the saved SOCKS credentials. */
static BOOL transfer(SOCKET s, void *p, int n, BOOL writing) {
    char *buf = p;
    while (n > 0) {
        int done = writing ? send(s, buf, n, 0) : recv(s, buf, n, 0);
        if (done <= 0) return FALSE;
        buf += done;
        n -= done;
    }
    return TRUE;
}

typedef struct entry {
    ADDRINFOW ai;
    SOCKADDR_STORAGE addr;
    WCHAR canonical[256];
} entry;

typedef struct allocation {
    struct allocation *next;
    entry rows[64];
} allocation;
static SRWLOCK list_lock = SRWLOCK_INIT;
static allocation *allocations;

static VOID WSAAPI box_free(PADDRINFOW ai) {
    AcquireSRWLockExclusive(&list_lock);
    allocation **link = &allocations;
    while (*link && &(*link)->rows[0].ai != ai) link = &(*link)->next;
    allocation *owned = *link;
    if (owned) *link = owned->next;
    ReleaseSRWLockExclusive(&list_lock);
    if (owned) HeapFree(GetProcessHeap(), 0, owned);
    else system_free(ai);
}

static int numeric_rows(allocation *mem, int *count, int family, BYTE *bytes,
                        const WCHAR *service, const ADDRINFOW *hints) {
    WCHAR ip[64];
    ADDRINFOW numeric = {0};
    if (hints) numeric = *hints;
    numeric.ai_family = family;
    numeric.ai_flags = (numeric.ai_flags & ~AI_CANONNAME) | AI_NUMERICHOST;
    if (!InetNtopW(family, bytes, ip, 64)) return WSAEINVAL;
    PADDRINFOW native = NULL;
    int error = system_lookup(ip, service, &numeric, &native);
    if (error) return error;
    for (PADDRINFOW r = native; r; r = r->ai_next) {
        if (*count >= 64 || !r->ai_addr || r->ai_addrlen > sizeof(SOCKADDR_STORAGE)) {
            error = WSA_NOT_ENOUGH_MEMORY;
            break;
        }
        entry *e = &mem->rows[*count];
        e->ai = *r;
        memcpy(&e->addr, r->ai_addr, r->ai_addrlen);
        e->ai.ai_addr = (SOCKADDR *)&e->addr;
        e->ai.ai_next = NULL;
        e->ai.ai_canonname = NULL;
        e->ai.ai_flags = hints ? hints->ai_flags : 0;
        if (*count) mem->rows[*count - 1].ai.ai_next = &e->ai;
        ++*count;
    }
    system_free(native);
    return error;
}

static INT WSAAPI box_lookup(PCWSTR name, PCWSTR service, const ADDRINFOW *hints, PADDRINFOW *out) {
    if (!out) return WSAEFAULT;
    *out = NULL;
    /* Numeric-only requests and passive/wildcard endpoints cannot cause DNS. */
    if (!name || (hints && (hints->ai_flags & AI_NUMERICHOST)))
        return system_lookup(name, service, hints, out);
    IN6_ADDR ip6; IN_ADDR ip4;
    if (InetPtonW(AF_INET, name, &ip4) == 1 || InetPtonW(AF_INET6, name, &ip6) == 1) {
        ADDRINFOW numeric = {0};
        if (hints) numeric = *hints;
        numeric.ai_flags |= AI_NUMERICHOST;
        return system_lookup(name, service, &numeric, out);
    }
    int wanted = hints ? hints->ai_family : AF_UNSPEC;
    if (wanted != AF_UNSPEC && wanted != AF_INET && wanted != AF_INET6) return WSAEAFNOSUPPORT;
    char query[260];
    int n = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, name, -1, query, sizeof(query)-1, NULL, NULL);
    if (n <= 1) return WSAHOST_NOT_FOUND;
    for (int i=0;i<n-1;i++) {
        unsigned char c = (unsigned char)query[i];
        if (!(c=='.' || c=='-' || (c>='0'&&c<='9') || (c>='a'&&c<='z') || (c>='A'&&c<='Z')))
            return WSAHOST_NOT_FOUND;
    }
    query[n-1] = '\n';
    SOCKET sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == INVALID_SOCKET) return WSATRY_AGAIN;
    DWORD timeout = 30000;
    setsockopt(sock,SOL_SOCKET,SO_RCVTIMEO,(char*)&timeout,sizeof(timeout));
    setsockopt(sock,SOL_SOCKET,SO_SNDTIMEO,(char*)&timeout,sizeof(timeout));
    SOCKADDR_IN dest = {0};
    dest.sin_family = AF_INET; dest.sin_port = htons(dns_port);
    dest.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    int error = WSATRY_AGAIN, count = 0;
    allocation *mem = NULL;
    BYTE header[2], record[17];
    if (connect(sock,(SOCKADDR*)&dest,sizeof(dest)) ||
        !transfer(sock,dns_ticket,64,TRUE) || !transfer(sock,query,n,TRUE) || !transfer(sock,header,2,FALSE)) goto done;
    if (header[0] == 3) { error=WSAHOST_NOT_FOUND; goto done; }
    if (header[0] || header[1]>64) goto done;
    mem=HeapAlloc(GetProcessHeap(),HEAP_ZERO_MEMORY,sizeof(*mem));
    if (!mem) { error=WSA_NOT_ENOUGH_MEMORY; goto done; }
    for (int i=0;i<header[1];i++) {
        if (!transfer(sock,record,1,FALSE)) goto done;
        int family = record[0]==4 ? AF_INET : record[0]==6 ? AF_INET6 : -1;
        if (family<0 || !transfer(sock,record+1,family==AF_INET?4:16,FALSE)) goto done;
        if (wanted!=AF_UNSPEC && wanted!=family) continue;
        int rc=numeric_rows(mem,&count,family,record+1,service,hints);
        if (rc) { error=rc; goto done; }
    }
    if (!count) {error=WSANO_DATA;goto done;}
    if (hints && (hints->ai_flags & AI_CANONNAME)) {
        wcsncpy(mem->rows[0].canonical,name,255);
        mem->rows[0].ai.ai_canonname=mem->rows[0].canonical;
    }
    AcquireSRWLockExclusive(&list_lock);
    mem->next=allocations; allocations=mem;
    ReleaseSRWLockExclusive(&list_lock);
    *out=&mem->rows[0].ai; mem=NULL; error=0;
done:
    closesocket(sock);
    if(mem) HeapFree(GetProcessHeap(),0,mem);
    if(error) WSASetLastError(error);
    return error;
}

__declspec(dllexport) void WINAPI InjectDllMain(HINSTANCE sbie, ULONG_PTR unused) {
    (void)unused;
    typedef LONG (*QueryProcess)(HANDLE,WCHAR*,WCHAR*,WCHAR*,ULONG*);
    typedef void *(*BoxHook)(const char*,void*,void*,HMODULE);
    QueryProcess query=(QueryProcess)(void*)GetProcAddress(sbie,"SbieApi_QueryProcess");
    BoxHook adapt=(BoxHook)(void*)GetProcAddress(sbie,"SbieDll_Hook");
    /* Sandboxie supplies these values for this box. There is no external attach interface. */
    typedef LONG (*QueryConf)(const WCHAR *,const WCHAR *,ULONG,WCHAR *,ULONG);
    QueryConf conf=(QueryConf)(void*)GetProcAddress(sbie,"SbieApi_QueryConf");
    WCHAR box[40]={0}, actual[32768], expected[16384], port[16]={0}, ticket[65]={0};
    SetEnvironmentVariableW(L"CAGE_LITE_STATUS",L"box");
    if (!query || !adapt || !conf ||
        query((HANDLE)(ULONG_PTR)GetCurrentProcessId(),box,NULL,NULL,NULL)!=0 ||
        wcsncmp(box,L"CageLite_",9) != 0) return;
    SetEnvironmentVariableW(L"CAGE_LITE_STATUS",L"image");
    DWORD n=GetModuleFileNameW(NULL,actual,32768);
    if (!n || n>=32768) return;
    /* Only explicitly registered full image paths in this box receive the adapter. */
    BOOL selected=FALSE;
    for (ULONG index=0; index<64; ++index) {
        if (conf(box,L"CageLiteImage",0x20000000UL | index,expected,sizeof(expected))!=0)
            break;
        if (!_wcsicmp(actual,expected)) { selected=TRUE; break; }
    }
    if (!selected) return;
    SetEnvironmentVariableW(L"CAGE_LITE_STATUS",L"route");
    if (conf(box,L"CageLiteDnsPort",0,port,sizeof(port))!=0 ||
        conf(box,L"CageLiteDnsTicket",0,ticket,sizeof(ticket))!=0 || wcslen(ticket)!=64) return;
    SetEnvironmentVariableW(L"CAGE_LITE_STATUS",L"port");
    WCHAR *end=NULL;
    unsigned long parsed=wcstoul(port,&end,10);
    if (!end || *end || parsed==0 || parsed>65535) return;
    dns_port=(USHORT)parsed;
    for (size_t i=0;i<64;i++) {
        if ((ticket[i]<L'0' || ticket[i]>L'9') && (ticket[i]<L'a' || ticket[i]>L'f')) return;
        dns_ticket[i]=(char)ticket[i];
    }
    SetEnvironmentVariableW(L"CAGE_LITE_STATUS",L"modules");
    HMODULE k=GetModuleHandleW(L"kernel32.dll"), w=GetModuleHandleW(L"ws2_32.dll");
    if (!k || !w) return;
    DWORD index=0;
    while (EnumDynamicTimeZoneInformation(index++,&tokyo)==ERROR_SUCCESS) {
        if (!wcscmp(tokyo.TimeZoneKeyName,L"Tokyo Standard Time")) break;
    }
    if (wcscmp(tokyo.TimeZoneKeyName,L"Tokyo Standard Time")) return;
    system_dynamic=adapt("GetDynamicTimeZoneInformation",(void*)GetProcAddress(k,"GetDynamicTimeZoneInformation"),box_dynamic,k);
    system_zone=adapt("GetTimeZoneInformation",(void*)GetProcAddress(k,"GetTimeZoneInformation"),box_zone,k);
    system_local=adapt("GetLocalTime",(void*)GetProcAddress(k,"GetLocalTime"),box_local,k);
    system_free=adapt("FreeAddrInfoW",(void*)GetProcAddress(w,"FreeAddrInfoW"),box_free,w);
    if (system_free)
        system_lookup=adapt("GetAddrInfoW",(void*)GetProcAddress(w,"GetAddrInfoW"),box_lookup,w);
    if (system_dynamic && system_zone && system_local && system_free && system_lookup)
        SetEnvironmentVariableW(L"CAGE_LITE_STATUS",L"ready");
}
