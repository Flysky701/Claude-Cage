/* Controlled x64 blocking TCP experiment. This is not an application runtime. */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

static int (WSAAPI *original_connect)(SOCKET, const struct sockaddr *, int);
static USHORT proxy_port;
static char proxy_user[64], proxy_password[128];
static DWORD initialized_pid;
static DWORD initialization_stage;

static int socket_error(int code) {
    WSASetLastError(code);
    return SOCKET_ERROR;
}

static BOOL exact_transfer(SOCKET socket, char *buffer, int length, BOOL writing) {
    ULONGLONG deadline = GetTickCount64() + 5000;
    while (length > 0) {
        if (GetTickCount64() >= deadline) { WSASetLastError(WSAETIMEDOUT); return FALSE; }
        int count = writing ? send(socket, buffer, length, 0) : recv(socket, buffer, length, 0);
        if (count <= 0) return FALSE;
        buffer += count;
        length -= count;
    }
    return TRUE;
}

static int WSAAPI proxy_connect(SOCKET socket, const struct sockaddr *address, int length) {
    SOCKADDR_IN target, proxy = {0};
    int type = 0, type_size = sizeof(type);
    if (!initialized_pid || !original_connect) return socket_error(WSAEACCES);
    if (length < (int)sizeof(target)) return socket_error(WSAEINVAL);
    __try {
        if (!address || address->sa_family != AF_INET) return socket_error(WSAEAFNOSUPPORT);
        memcpy(&target, address, sizeof(target));
    } __except(EXCEPTION_EXECUTE_HANDLER) { return socket_error(WSAEFAULT); }
    if (getsockopt(socket, SOL_SOCKET, SO_TYPE, (char *)&type, &type_size)) return SOCKET_ERROR;
    if (type != SOCK_STREAM) return socket_error(WSAEACCES);
    if (!target.sin_port || target.sin_addr.s_addr == INADDR_ANY) return socket_error(WSAEINVAL);

    /* Tests create only blocking sockets. No attempt is made to emulate
       ConnectEx, WSAConnect, nonblocking completion or an application browser. */
    proxy.sin_family = AF_INET;
    proxy.sin_port = htons(proxy_port);
    proxy.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (original_connect(socket, (const struct sockaddr *)&proxy, sizeof(proxy))) return SOCKET_ERROR;

    DWORD old_receive = 0, old_send = 0, timeout = 2000;
    int option_size = sizeof(DWORD);
    BOOL receive_saved = !getsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, (char *)&old_receive, &option_size);
    option_size = sizeof(DWORD);
    BOOL send_saved = !getsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, (char *)&old_send, &option_size);
    int failure = WSAECONNREFUSED;
    BOOL accepted = FALSE;
    unsigned char response[4], message[260];
    size_t user_length = strlen(proxy_user), password_length = strlen(proxy_password);
    if (!receive_saved || !send_saved ||
        setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout)) ||
        setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout))) goto done;

    /* Only the experiment's temporary SOCKS credentials enter the box. */
    message[0] = 5; message[1] = 1; message[2] = 2;
    if (!exact_transfer(socket, (char *)message, 3, TRUE) ||
        !exact_transfer(socket, (char *)response, 2, FALSE)) goto done;
    if (response[0] != 5 || response[1] != 2) { failure = WSAEACCES; goto done; }
    message[0] = 1; message[1] = (unsigned char)user_length;
    memcpy(message + 2, proxy_user, user_length);
    message[2 + user_length] = (unsigned char)password_length;
    memcpy(message + 3 + user_length, proxy_password, password_length);
    if (!exact_transfer(socket, (char *)message, (int)(3 + user_length + password_length), TRUE) ||
        !exact_transfer(socket, (char *)response, 2, FALSE)) goto done;
    if (response[0] != 1 || response[1] != 0) { failure = WSAEACCES; goto done; }
    message[0] = 5; message[1] = 1; message[2] = 0; message[3] = 1;
    memcpy(message + 4, &target.sin_addr.s_addr, 4);
    memcpy(message + 8, &target.sin_port, 2);
    if (!exact_transfer(socket, (char *)message, 10, TRUE) ||
        !exact_transfer(socket, (char *)response, 4, FALSE)) goto done;
    if (response[0] != 5 || response[1] != 0 || response[2] != 0) goto done;
    int tail;
    if (response[3] == 1) tail = 6;
    else if (response[3] == 4) tail = 18;
    else if (response[3] == 3) {
        if (!exact_transfer(socket, (char *)response, 1, FALSE)) goto done;
        tail = response[0] + 2;
    } else goto done;
    if (!exact_transfer(socket, (char *)message, tail, FALSE)) goto done;
    accepted = TRUE;
done:
    if (receive_saved) setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, (char *)&old_receive, sizeof(old_receive));
    if (send_saved) setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, (char *)&old_send, sizeof(old_send));
    if (accepted) return 0;
    /* Never reconnect the original destination. Leave the application to close
       its own failed socket; shutting down prevents partial SOCKS traffic reuse. */
    shutdown(socket, SD_BOTH);
    return socket_error(failure);
}

__declspec(dllexport) DWORD WINAPI CageSyncStatus(void) { return initialized_pid; }
__declspec(dllexport) DWORD WINAPI CageSyncStage(void) { return initialization_stage; }

__declspec(dllexport) void WINAPI InjectDllMain(HINSTANCE sandbox_module, ULONG_PTR unused) {
    (void)unused;
    initialization_stage = 1;
    typedef LONG (*QueryProcess)(HANDLE, WCHAR *, WCHAR *, WCHAR *, ULONG *);
    typedef LONG (*QueryConf)(const WCHAR *, const WCHAR *, ULONG, WCHAR *, ULONG);
    typedef void *(*InstallHook)(const char *, void *, void *, HMODULE);
    QueryProcess query = (QueryProcess)(void *)GetProcAddress(sandbox_module, "SbieApi_QueryProcess");
    QueryConf conf = (QueryConf)(void *)GetProcAddress(sandbox_module, "SbieApi_QueryConf");
    InstallHook hook = (InstallHook)(void *)GetProcAddress(sandbox_module, "SbieDll_Hook");
    WCHAR box[64] = {0}, enabled[8] = {0}, actual[32768], expected[16384], port[16] = {0};
    WCHAR user[64] = {0}, password[128] = {0};
    if (!query || !conf || !hook) return;
    initialization_stage = 2;
    if (query((HANDLE)(ULONG_PTR)GetCurrentProcessId(), box, NULL, NULL, NULL) != 0 || wcsncmp(box, L"CageProbeSync_", 14) != 0) return;
    initialization_stage = 3;
    if (conf(box, L"CageSyncProbe", 0, enabled, sizeof(enabled)) != 0 || wcscmp(enabled, L"y")) return;
    initialization_stage = 4;
    DWORD count = GetModuleFileNameW(NULL, actual, 32768);
    if (!count || count >= 32768) return;
    BOOL selected = FALSE;
    for (ULONG index = 0; index < 3; index++) {
        if (conf(box, L"CageSyncImage", 0x20000000UL | index, expected, sizeof(expected)) != 0) break;
        if (!_wcsicmp(actual, expected)) { selected = TRUE; break; }
    }
    if (!selected ||
        conf(box, L"CageSyncProxyPort", 0, port, sizeof(port)) != 0 ||
        conf(box, L"CageSyncProxyUser", 0, user, sizeof(user)) != 0 ||
        conf(box, L"CageSyncProxyPassword", 0, password, sizeof(password)) != 0) return;
    initialization_stage = 5;
    WCHAR *end = NULL;
    unsigned long parsed = wcstoul(port, &end, 10);
    if (!end || *end || !parsed || parsed > 65535 || !wcslen(user) || !wcslen(password)) return;
    for (size_t i = 0; i < wcslen(user); i++) { if (user[i] < 33 || user[i] > 126) return; proxy_user[i] = (char)user[i]; }
    for (size_t i = 0; i < wcslen(password); i++) { if (password[i] < 33 || password[i] > 126) return; proxy_password[i] = (char)password[i]; }
    HMODULE winsock = GetModuleHandleW(L"ws2_32.dll");
    if (!winsock) return;
    initialization_stage = 6;
    proxy_port = (USHORT)parsed;
    original_connect = (void *)hook("connect", (void *)GetProcAddress(winsock, "connect"), proxy_connect, winsock);
    if (original_connect) initialized_pid = GetCurrentProcessId();
    initialization_stage = original_connect ? 7 : 6;
}
