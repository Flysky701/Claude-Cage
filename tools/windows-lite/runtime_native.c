/* Cage-owned boxed terminal gate and per-session boundary probe. */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <winhttp.h>

typedef LONG (*QueryProcess)(HANDLE,WCHAR*,WCHAR*,WCHAR*,ULONG*);
static BOOL identity(const WCHAR *expected) {
    HMODULE module=GetModuleHandleW(L"SbieDll.dll");
    QueryProcess query=module?(QueryProcess)(void*)GetProcAddress(module,"SbieApi_QueryProcess"):NULL;
    WCHAR box[128]={0};
    return query && !query((HANDLE)(ULONG_PTR)GetCurrentProcessId(),box,NULL,NULL,NULL) && !wcscmp(box,expected);
}
static int hold_probe(int argc,WCHAR **argv) {
    if(argc!=6||!identity(argv[3]))return 70;
    WSADATA init;WSAStartup(MAKEWORD(2,2),&init);SOCKET s=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    SOCKADDR_IN target={0};target.sin_family=AF_INET;target.sin_addr.s_addr=htonl(INADDR_LOOPBACK);target.sin_port=htons((USHORT)_wtoi(argv[4]));
    DWORD timeout=4000;setsockopt(s,SOL_SOCKET,SO_RCVTIMEO,(char*)&timeout,sizeof(timeout));
    char challenge[100],request[512],response[1024]={0};WideCharToMultiByte(CP_UTF8,0,argv[5],-1,challenge,100,NULL,NULL);
    if(connect(s,(SOCKADDR*)&target,sizeof(target)))return 71;
    int n=sprintf_s(request,512,"GET http://cage-session.invalid/hold/%s HTTP/1.1\r\nHost: cage-session.invalid\r\n\r\n",challenge);send(s,request,n,0);
    int used=0;while(used<1023 && !strstr(response,"\r\n\r\n")){if(recv(s,response+used,1,0)!=1)return 72;used++;}
    char initial[100]={0};used=0;n=(int)strlen(challenge);while(used<n){int got=recv(s,initial+used,n-used,0);if(got<=0)return 73;used+=got;}
    if(strcmp(initial,challenge))return 74;
    FILE *out=NULL;_wfopen_s(&out,argv[2],L"wb");if(!out)return 75;
    fprintf(out,"{\"pid\":%lu,\"boxed\":true,\"connected\":true,\"disconnected\":false}",GetCurrentProcessId());fclose(out);
    ULONGLONG deadline=GetTickCount64()+30000;BOOL disconnected=FALSE;
    while(GetTickCount64()<deadline){char value='x',answer=0;if(send(s,&value,1,0)!=1||recv(s,&answer,1,0)!=1||answer!=value){disconnected=TRUE;break;}Sleep(100);}
    closesocket(s);_wfopen_s(&out,argv[2],L"wb");if(!out)return 76;
    fprintf(out,"{\"pid\":%lu,\"boxed\":true,\"connected\":true,\"disconnected\":%s}",GetCurrentProcessId(),disconnected?"true":"false");fclose(out);return disconnected?0:77;
}
static int connect_port(int port) {
    SOCKET s=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    SOCKADDR_IN target={0}; target.sin_family=AF_INET; target.sin_addr.s_addr=htonl(INADDR_LOOPBACK); target.sin_port=htons((USHORT)port);
    u_long nonblocking=1; ioctlsocket(s,FIONBIO,&nonblocking);
    int result=connect(s,(SOCKADDR*)&target,sizeof(target));
    if(result && WSAGetLastError()==WSAEWOULDBLOCK) {
        fd_set writes,errors; FD_ZERO(&writes);FD_ZERO(&errors);FD_SET(s,&writes);FD_SET(s,&errors);
        struct timeval wait={2,0}; select(0,NULL,&writes,&errors,&wait);
        int error=1,length=sizeof(error); getsockopt(s,SOL_SOCKET,SO_ERROR,(char*)&error,&length);
        result=FD_ISSET(s,&writes)&&!error?0:-1;
    }
    closesocket(s); return result==0;
}
static int probe(int argc,WCHAR **argv) {
    if(argc!=11) return 90;
    WSADATA init; WSAStartup(MAKEWORD(2,2),&init);
    BOOL boxed=identity(argv[3]);
    HANDLE file=CreateFileW(argv[4],GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,0,NULL);
    BOOL host=file!=INVALID_HANDLE_VALUE; if(host)CloseHandle(file);
    HKEY key=NULL;BOOL host_registry=FALSE,registry_before=FALSE,registry_write=FALSE;
    WCHAR prior[200]={0};DWORD prior_size=sizeof(prior),kind=0;
    if(RegOpenKeyExW(HKEY_CURRENT_USER,argv[8],0,KEY_QUERY_VALUE,&key)==ERROR_SUCCESS) {
        host_registry=RegQueryValueExW(key,L"HostOnly",NULL,&kind,(BYTE*)prior,&prior_size)==ERROR_SUCCESS;
        prior_size=sizeof(prior);prior[0]=0;
        registry_before=RegQueryValueExW(key,L"BoxOnly",NULL,&kind,(BYTE*)prior,&prior_size)==ERROR_SUCCESS&&!wcscmp(prior,argv[7]);
        RegCloseKey(key);
    }
    BOOL file_before=FALSE,file_write=FALSE;WCHAR path[32768];wcscpy_s(path,32768,argv[9]);
    file=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,0,NULL);
    if(file!=INVALID_HANDLE_VALUE){DWORD got=0;ZeroMemory(prior,sizeof(prior));file_before=ReadFile(file,prior,sizeof(prior)-2,&got,NULL)&&!wcscmp(prior,argv[7]);CloseHandle(file);}
    WCHAR *slash=wcsrchr(path,L'\\');if(slash){*slash=0;CreateDirectoryW(path,NULL);}
    file=CreateFileW(argv[9],GENERIC_WRITE,0,NULL,CREATE_ALWAYS,0,NULL);
    if(file!=INVALID_HANDLE_VALUE){DWORD written=0;file_write=WriteFile(file,argv[7],(DWORD)(2*(wcslen(argv[7])+1)),&written,NULL);CloseHandle(file);}
    if(RegCreateKeyExW(HKEY_CURRENT_USER,argv[8],0,NULL,0,KEY_SET_VALUE,NULL,&key,NULL)==ERROR_SUCCESS){registry_write=RegSetValueExW(key,L"BoxOnly",0,REG_SZ,(const BYTE*)argv[7],(DWORD)(2*(wcslen(argv[7])+1)))==ERROR_SUCCESS;RegCloseKey(key);}
    int direct=connect_port(_wtoi(argv[5]));
    SOCKET s=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    SOCKADDR_IN target={0};target.sin_family=AF_INET;target.sin_addr.s_addr=htonl(INADDR_LOOPBACK);target.sin_port=htons((USHORT)_wtoi(argv[6]));
    DWORD timeout=4000;setsockopt(s,SOL_SOCKET,SO_RCVTIMEO,(char*)&timeout,sizeof(timeout));
    char nonce[100],request[512],response[4096]={0};
    WideCharToMultiByte(CP_UTF8,0,argv[7],-1,nonce,sizeof(nonce),NULL,NULL);
    BOOL proxy=FALSE,business=FALSE;DWORD business_error=0,business_stage=0;
    if(!connect(s,(SOCKADDR*)&target,sizeof(target))) {
        int n=sprintf_s(request,sizeof(request),"GET http://cage-session.invalid/%s HTTP/1.1\r\nHost: cage-session.invalid\r\nConnection: close\r\n\r\n",nonce);
        send(s,request,n,0);int used=0,got;
        while(used<(int)sizeof(response)-1 && (got=recv(s,response+used,(int)sizeof(response)-1-used,0))>0)used+=got;
        proxy=strstr(response,"200 OK")&&strstr(response,nonce);
    }
    closesocket(s);
    WCHAR endpoint[80];swprintf_s(endpoint,80,L"127.0.0.1:%d",_wtoi(argv[6]));
    HINTERNET http=WinHttpOpen(L"CageBoundary/1",WINHTTP_ACCESS_TYPE_NAMED_PROXY,endpoint,L"",0);
    if(http) {
        WinHttpSetTimeouts(http,2000,2000,2000,3000);DWORD retries=0;WinHttpSetOption(http,WINHTTP_OPTION_CONNECT_RETRIES,&retries,sizeof(retries));
        HINTERNET conn=WinHttpConnect(http,L"1.1.1.1",443,0);
        if(conn) {
            HINTERNET requestHandle=WinHttpOpenRequest(conn,L"GET",L"/cdn-cgi/trace",NULL,NULL,NULL,WINHTTP_FLAG_SECURE);
            if(requestHandle) {
                DWORD status=0,length=sizeof(status);char body[4096]={0};DWORD used=0;
                business_stage=1;
                if(WinHttpSendRequest(requestHandle,NULL,0,NULL,0,0,0)&&(business_stage=2)&&WinHttpReceiveResponse(requestHandle,NULL)&&
                   WinHttpQueryHeaders(requestHandle,WINHTTP_QUERY_STATUS_CODE|WINHTTP_QUERY_FLAG_NUMBER,NULL,&status,&length,NULL)&&status==200&&
                   WinHttpReadData(requestHandle,body,sizeof(body)-1,&used))business=used>0&&strstr(body,"ip=")!=NULL;
                business_error=GetLastError();
                WinHttpCloseHandle(requestHandle);
            }WinHttpCloseHandle(conn);
        }WinHttpCloseHandle(http);
    }
    FILE *out=NULL;_wfopen_s(&out,argv[2],L"wb");
    if(!out)return 91;
    fprintf(out,"{\"pid\":%lu,\"boxed\":%s,\"hostReadable\":%s,\"directConnected\":%s,\"proxyResponded\":%s,\"businessResponded\":%s,\"businessError\":%lu,\"businessStage\":%lu,\"hostRegistryReadable\":%s,\"fileBefore\":%s,\"registryBefore\":%s,\"fileWrite\":%s,\"registryWrite\":%s}",GetCurrentProcessId(),boxed?"true":"false",host?"true":"false",direct?"true":"false",proxy?"true":"false",business?"true":"false",business_error,business_stage,host_registry?"true":"false",file_before?"true":"false",registry_before?"true":"false",file_write?"true":"false",registry_write?"true":"false");fclose(out);
    return boxed&&!host&&!direct&&proxy?0:92;
}
int wmain(int argc,WCHAR **argv) {
    if(argc>1&&!wcscmp(argv[1],L"--hold"))return hold_probe(argc,argv);
    if(argc==11&&!wcscmp(argv[1],L"--probe-tree")) {
        WCHAR image[32768],command[32768];GetModuleFileNameW(NULL,image,32768);
        swprintf_s(command,32768,L"\"%s\" --probe \"%s.child\" \"%s\" \"%s\" %s %s %s \"%s\" \"%s\" %s",image,argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],argv[8],argv[9],argv[10]);
        STARTUPINFOW start={0};start.cb=sizeof(start);PROCESS_INFORMATION child={0};
        if(!CreateProcessW(image,command,NULL,NULL,FALSE,CREATE_NO_WINDOW,NULL,NULL,&start,&child))return 93;
        CloseHandle(child.hThread);DWORD wait=WaitForSingleObject(child.hProcess,25000);
        if(wait!=WAIT_OBJECT_0){TerminateProcess(child.hProcess,94);CloseHandle(child.hProcess);return 94;}
        CloseHandle(child.hProcess);return probe(argc,argv);
    }
    if(argc>1&&!wcscmp(argv[1],L"--probe"))return probe(argc,argv);
    /* argv: --terminal report gate expected-box command-line */
    if(argc!=6||wcscmp(argv[1],L"--terminal")||!identity(argv[4]))return 80;
    FILE *out=NULL;_wfopen_s(&out,argv[2],L"wb");if(!out)return 81;
    fprintf(out,"{\"pid\":%lu,\"boxed\":true}",GetCurrentProcessId());fclose(out);
    ULONGLONG deadline=GetTickCount64()+15000;
    while(GetFileAttributesW(argv[3])==INVALID_FILE_ATTRIBUTES) {if(GetTickCount64()>deadline)return 82;Sleep(30);}
    /* The trusted host attached this process to a kill-on-close Job before
       creating the one-use gate. Children inherit the Job and console. */
    STARTUPINFOW start={0};start.cb=sizeof(start);
    PROCESS_INFORMATION child={0};WCHAR *command=_wcsdup(argv[5]);
    BOOL ok=CreateProcessW(NULL,command,NULL,NULL,TRUE,0,NULL,NULL,&start,&child);free(command);
    if(!ok)return 83;
    CloseHandle(child.hThread);WaitForSingleObject(child.hProcess,INFINITE);
    DWORD result=1;GetExitCodeProcess(child.hProcess,&result);CloseHandle(child.hProcess);return (int)result;
}
