/* Box-only ConPTY transport. A runtime lease must authorize the child before
   any shell starts. No external process attachment or host-shell fallback. */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <shellapi.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#ifndef PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE
#define PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE 0x00020016
#endif
#define MAX_FRAME 65536u
typedef HRESULT (WINAPI *CreatePC)(COORD,HANDLE,HANDLE,DWORD,HANDLE*);
typedef HRESULT (WINAPI *ResizePC)(HANDLE,COORD);
typedef void (WINAPI *ClosePC)(HANDLE);
typedef LONG (__cdecl *QueryBox)(HANDLE,WCHAR*,WCHAR*,WCHAR*,ULONG*);

typedef struct Bridge {
    SOCKET socket;
    CRITICAL_SECTION send_lock;
    HANDLE console, input, output, process, reader;
    ResizePC resize;
    ClosePC close_console;
} Bridge;

static BOOL transfer(SOCKET socket, void *data, DWORD length, BOOL writing) {
    char *bytes=(char*)data;
    while(length) {
        int n=writing?send(socket,bytes,(int)length,0):recv(socket,bytes,(int)length,0);
        if(n<=0)return FALSE;
        bytes+=n;length-=(DWORD)n;
    }
    return TRUE;
}

static BOOL frame(Bridge *bridge,char type,const void *payload,DWORD length) {
    unsigned char header[5];BOOL ok;
    header[0]=(unsigned char)type;
    header[1]=(unsigned char)length;header[2]=(unsigned char)(length>>8);
    header[3]=(unsigned char)(length>>16);header[4]=(unsigned char)(length>>24);
    EnterCriticalSection(&bridge->send_lock);
    ok=transfer(bridge->socket,header,5,TRUE) && (!length || transfer(bridge->socket,(void*)payload,length,TRUE));
    LeaveCriticalSection(&bridge->send_lock);
    return ok;
}

static BOOL receive_frame(Bridge *bridge,char *type,unsigned char *payload,DWORD *length) {
    unsigned char header[5];
    if(!transfer(bridge->socket,header,5,FALSE))return FALSE;
    *type=(char)header[0];
    *length=(DWORD)header[1]|((DWORD)header[2]<<8)|((DWORD)header[3]<<16)|((DWORD)header[4]<<24);
    if(*length>MAX_FRAME)return FALSE;
    return !*length || transfer(bridge->socket,payload,*length,FALSE);
}

static BOOL identifier(const WCHAR *text,size_t maximum,BOOL hex_only) {
    size_t i,n=wcslen(text);
    if(!n || n>maximum)return FALSE;
    for(i=0;i<n;i++) {
        WCHAR c=text[i];
        if(c>=L'0'&&c<=L'9')continue;
        if(c>=L'a'&&c<=(hex_only?L'f':L'z'))continue;
        if(!hex_only&&((c>=L'A'&&c<=L'Z')||c==L'_'||c==L'-'))continue;
        return FALSE;
    }
    return TRUE;
}

static WCHAR *command_line(int argc,WCHAR **argv,int first) {
    size_t needed=1,at=0;int i;
    for(i=first;i<argc;i++)needed+=2*wcslen(argv[i])+4;
    if(needed>32760)return NULL;
    WCHAR *out=(WCHAR*)calloc(needed,sizeof(WCHAR));
    if(!out)return NULL;
    for(i=first;i<argc;i++) {
        const WCHAR *p=argv[i];size_t slashes=0;
        if(i!=first)out[at++]=L' ';
        out[at++]=L'"';
        while(*p) {
            if(*p==L'\\'){slashes++;p++;continue;}
            while(slashes){out[at++]=L'\\';if(*p==L'"')out[at++]=L'\\';slashes--;}
            if(*p==L'"')out[at++]=L'\\';
            out[at++]=*p++;
        }
        while(slashes){out[at++]=L'\\';out[at++]=L'\\';slashes--;}
        out[at++]=L'"';
    }
    return out;
}

static BOOL report_identity(const WCHAR *path,const char *json,DWORD length) {
    DWORD written=0;
    HANDLE file=CreateFileW(path,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,NULL);
    if(file==INVALID_HANDLE_VALUE)return FALSE;
    BOOL ok=WriteFile(file,json,length,&written,NULL)&&written==length&&FlushFileBuffers(file);
    CloseHandle(file);return ok;
}

static DWORD WINAPI read_output(void *value) {
    Bridge *bridge=(Bridge*)value;
    unsigned char buffer[16384];DWORD length;BOOL connected=TRUE;
    while(ReadFile(bridge->output,buffer,sizeof(buffer),&length,NULL)&&length) {
        if(connected&&!frame(bridge,'O',buffer,length))connected=FALSE;
        // Continue draining after disconnect so ClosePseudoConsole cannot block.
    }
    if(connected) {
        DWORD error=GetLastError();
        if(error!=ERROR_BROKEN_PIPE && error!=ERROR_SUCCESS) {
            char message[96];int count=snprintf(message,sizeof(message),"Boxed console output unavailable (%lu)",error);
            frame(bridge,'E',message,(DWORD)count);
        }
    }
    return 0;
}

static DWORD WINAPI wait_child(void *value) {
    Bridge *bridge=(Bridge*)value;DWORD exit_code=1;unsigned char bytes[4];
    WaitForSingleObject(bridge->process,INFINITE);
    GetExitCodeProcess(bridge->process,&exit_code);
    bridge->close_console(bridge->console);
    WaitForSingleObject(bridge->reader,INFINITE);
    bytes[0]=(unsigned char)exit_code;bytes[1]=(unsigned char)(exit_code>>8);
    bytes[2]=(unsigned char)(exit_code>>16);bytes[3]=(unsigned char)(exit_code>>24);
    frame(bridge,'X',bytes,4);
    shutdown(bridge->socket,SD_BOTH);
    return 0;
}

static BOOL start_child(Bridge *bridge,CreatePC create_console,COORD size,int argc,WCHAR **argv,int first,const WCHAR *expected_box) {
    HANDLE input_read=NULL,output_write=NULL;
    STARTUPINFOEXW startup;PROCESS_INFORMATION process;SIZE_T bytes=0;
    WCHAR *command=NULL;BOOL ok=FALSE,attributes_initialized=FALSE;HRESULT hr;
    SECURITY_ATTRIBUTES pipe_security={sizeof(SECURITY_ATTRIBUTES),NULL,TRUE};
    ZeroMemory(&startup,sizeof(startup));ZeroMemory(&process,sizeof(process));
    if(!CreatePipe(&input_read,&bridge->input,&pipe_security,0)||!CreatePipe(&bridge->output,&output_write,&pipe_security,0))goto done;
    if(!SetHandleInformation(bridge->input,HANDLE_FLAG_INHERIT,0)||!SetHandleInformation(bridge->output,HANDLE_FLAG_INHERIT,0))goto done;
    hr=create_console(size,input_read,output_write,0,&bridge->console);
    if(FAILED(hr))goto done;
    // Keep the console-side pipe ends alive through child initialization.
    InitializeProcThreadAttributeList(NULL,1,0,&bytes);
    startup.lpAttributeList=(LPPROC_THREAD_ATTRIBUTE_LIST)malloc(bytes);
    if(!startup.lpAttributeList||!InitializeProcThreadAttributeList(startup.lpAttributeList,1,0,&bytes))goto done;
    attributes_initialized=TRUE;
    startup.StartupInfo.cb=sizeof(startup);
    startup.StartupInfo.dwFlags=STARTF_USESTDHANDLES;
    if(!UpdateProcThreadAttribute(startup.lpAttributeList,0,PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE,bridge->console,sizeof(HANDLE),NULL,NULL))goto done;
    command=command_line(argc,argv,first);
    if(!command)goto done;
    if(!CreateProcessW(argv[first],command,NULL,NULL,FALSE,EXTENDED_STARTUPINFO_PRESENT|CREATE_SUSPENDED,NULL,NULL,&startup.StartupInfo,&process))goto done;
    {
        WCHAR box[128]={0};ULONG session=0;
        QueryBox query=(QueryBox)(void*)GetProcAddress(GetModuleHandleW(L"SbieDll.dll"),"SbieApi_QueryProcess");
        if(!query||query((HANDLE)(ULONG_PTR)process.dwProcessId,box,NULL,NULL,&session)||_wcsicmp(box,expected_box)) {
            TerminateProcess(process.hProcess,1);goto done;
        }
    }
    bridge->process=process.hProcess;process.hProcess=NULL;
    bridge->reader=CreateThread(NULL,0,read_output,bridge,0,NULL);
    if(!bridge->reader){TerminateProcess(bridge->process,1);goto done;}
    if(ResumeThread(process.hThread)==(DWORD)-1){TerminateProcess(bridge->process,1);goto done;}
    ok=TRUE;
done:
    if(process.hThread)CloseHandle(process.hThread);
    if(process.hProcess)CloseHandle(process.hProcess);
    if(startup.lpAttributeList){if(attributes_initialized)DeleteProcThreadAttributeList(startup.lpAttributeList);free(startup.lpAttributeList);}
    free(command);
    if(input_read)CloseHandle(input_read);
    if(output_write)CloseHandle(output_write);
    return ok;
}

int wmain(int argc,WCHAR **argv) {
    const WCHAR *expected_box=NULL,*lease=NULL,*token=NULL,*report=NULL;
    unsigned long port=0,cols=100,rows=30;int first=0,i,result=1;
    WCHAR actual_box[128]={0};ULONG session=0;char box8[128],lease8[128],token8[128],hello[768];
    WSADATA wsa;Bridge bridge;HANDLE waiter=NULL;BOOL winsock=FALSE,lock=FALSE;
    unsigned char payload[MAX_FRAME];DWORD length;char type;
    ZeroMemory(&bridge,sizeof(bridge));bridge.socket=INVALID_SOCKET;
    for(i=1;i<argc;i++) {
        if(!wcscmp(argv[i],L"--")){first=i+1;break;}
        if(i+1>=argc)goto done;
        if(!wcscmp(argv[i],L"--box"))expected_box=argv[++i];
        else if(!wcscmp(argv[i],L"--lease"))lease=argv[++i];
        else if(!wcscmp(argv[i],L"--token"))token=argv[++i];
        else if(!wcscmp(argv[i],L"--report"))report=argv[++i];
        else {
            WCHAR *end=NULL;unsigned long value=wcstoul(argv[i+1],&end,10);
            if(!end||*end)goto done;
            if(!wcscmp(argv[i],L"--port"))port=value;
            else if(!wcscmp(argv[i],L"--cols"))cols=value;
            else if(!wcscmp(argv[i],L"--rows"))rows=value;
            else goto done;
            i++;
        }
    }
    if(!first||first>=argc||!expected_box||!lease||!token||!report||port<1||port>65535||cols<2||cols>=600||rows<2||rows>=400)goto done;
    if(!identifier(expected_box,64,FALSE)||!identifier(lease,96,FALSE)||wcslen(token)!=64||!identifier(token,64,TRUE))goto done;
    if(!(wcslen(argv[first])>2&&argv[first][1]==L':'&&(argv[first][2]==L'\\'||argv[first][2]==L'/'))&&wcsncmp(argv[first],L"\\\\",2))goto done;
    {
        HMODULE sbie=GetModuleHandleW(L"SbieDll.dll");
        QueryBox query=sbie?(QueryBox)(void*)GetProcAddress(sbie,"SbieApi_QueryProcess"):NULL;
        if(!query||query((HANDLE)(ULONG_PTR)GetCurrentProcessId(),actual_box,NULL,NULL,&session)||_wcsicmp(actual_box,expected_box))goto done;
    }
    WideCharToMultiByte(CP_UTF8,0,actual_box,-1,box8,sizeof(box8),NULL,NULL);
    WideCharToMultiByte(CP_UTF8,0,lease,-1,lease8,sizeof(lease8),NULL,NULL);
    WideCharToMultiByte(CP_UTF8,0,token,-1,token8,sizeof(token8),NULL,NULL);
    i=snprintf(hello,sizeof(hello),"{\"leaseId\":\"%s\",\"token\":\"%s\",\"pid\":%lu,\"boxName\":\"%s\"}",lease8,token8,GetCurrentProcessId(),box8);
    if(i<=0||i>=(int)sizeof(hello)||!report_identity(report,hello,(DWORD)i))goto done;
    if(WSAStartup(MAKEWORD(2,2),&wsa))goto done;
    winsock=TRUE;InitializeCriticalSection(&bridge.send_lock);lock=TRUE;
    bridge.socket=WSASocketW(AF_INET,SOCK_STREAM,IPPROTO_TCP,NULL,0,WSA_FLAG_NO_HANDLE_INHERIT);
    if(bridge.socket==INVALID_SOCKET)goto done;
    {
        SOCKADDR_IN address;DWORD timeout=20000;
        ZeroMemory(&address,sizeof(address));address.sin_family=AF_INET;address.sin_port=htons((u_short)port);address.sin_addr.s_addr=htonl(INADDR_LOOPBACK);
        setsockopt(bridge.socket,SOL_SOCKET,SO_RCVTIMEO,(const char*)&timeout,sizeof(timeout));
        setsockopt(bridge.socket,SOL_SOCKET,SO_SNDTIMEO,(const char*)&timeout,sizeof(timeout));
        if(connect(bridge.socket,(SOCKADDR*)&address,sizeof(address)))goto done;
    }
    if(!frame(&bridge,'H',hello,(DWORD)i)||!receive_frame(&bridge,&type,payload,&length)||type!='G'||length)goto done;
    {
        HMODULE kernel=GetModuleHandleW(L"kernel32.dll");
        CreatePC create_console=(CreatePC)(void*)GetProcAddress(kernel,"CreatePseudoConsole");
        bridge.resize=(ResizePC)(void*)GetProcAddress(kernel,"ResizePseudoConsole");
        bridge.close_console=(ClosePC)(void*)GetProcAddress(kernel,"ClosePseudoConsole");
        COORD size={(SHORT)cols,(SHORT)rows};DWORD timeout=0;
        if(!create_console||!bridge.resize||!bridge.close_console||!start_child(&bridge,create_console,size,argc,argv,first,expected_box)) {
            const char *error="Boxed terminal could not start";frame(&bridge,'E',error,(DWORD)strlen(error));goto done;
        }
        setsockopt(bridge.socket,SOL_SOCKET,SO_RCVTIMEO,(const char*)&timeout,sizeof(timeout));
        waiter=CreateThread(NULL,0,wait_child,&bridge,0,NULL);
        if(!waiter)goto done;
        if(!frame(&bridge,'B',NULL,0))goto done;
    }
    while(receive_frame(&bridge,&type,payload,&length)) {
        if(type=='I') {
            DWORD at=0,written;
            while(at<length) {
                if(!WriteFile(bridge.input,payload+at,length-at,&written,NULL)||!written)goto done;
                at+=written;
            }
        } else if(type=='R'&&length==4) {
            COORD size={(SHORT)(payload[0]|payload[1]<<8),(SHORT)(payload[2]|payload[3]<<8)};
            if(size.X<2||size.X>=600||size.Y<2||size.Y>=400||FAILED(bridge.resize(bridge.console,size)))goto done;
        } else if(type=='C'&&!length)break;
        else goto done;
    }
    result=0;
done:
    if(bridge.process)TerminateProcess(bridge.process,1);
    if(bridge.socket!=INVALID_SOCKET)shutdown(bridge.socket,SD_BOTH);
    if(waiter){WaitForSingleObject(waiter,INFINITE);CloseHandle(waiter);}
    else if(bridge.console&&bridge.close_console)bridge.close_console(bridge.console);
    if(bridge.reader){WaitForSingleObject(bridge.reader,INFINITE);CloseHandle(bridge.reader);}
    if(bridge.process)CloseHandle(bridge.process);
    if(bridge.input)CloseHandle(bridge.input);
    if(bridge.output)CloseHandle(bridge.output);
    if(bridge.socket!=INVALID_SOCKET)closesocket(bridge.socket);
    if(lock)DeleteCriticalSection(&bridge.send_lock);
    if(winsock)WSACleanup();
    return result;
}
