/* Independent AppContainer feasibility probe. Synthetic files and this image
   only; it does not launch user applications or grant networking capabilities. */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <userenv.h>
#include <sddl.h>
#include <aclapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <string.h>

typedef struct Identity {
    DWORD app_container, integrity, capabilities, pid;
    WCHAR sid[192];
} Identity;

static BOOL path_join(WCHAR *out,size_t count,const WCHAR *root,const WCHAR *leaf) {
    return swprintf_s(out,count,L"%s\\%s",root,leaf)>0;
}
static BOOL write_bytes(const WCHAR *path,const char *data) {
    DWORD written=0;size_t length=strlen(data);
    HANDLE file=CreateFileW(path,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);
    if(file==INVALID_HANDLE_VALUE)return FALSE;
    BOOL ok=WriteFile(file,data,(DWORD)length,&written,NULL)&&written==length&&FlushFileBuffers(file);
    CloseHandle(file);return ok;
}
static DWORD read_bytes(const WCHAR *path,char *data,DWORD length) {
    DWORD read=0;HANDLE file=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    if(file==INVALID_HANDLE_VALUE)return GetLastError();
    BOOL ok=ReadFile(file,data,length-1,&read,NULL);DWORD error=ok?0:GetLastError();
    CloseHandle(file);if(ok)data[read]=0;return error;
}
static BOOL identity(HANDLE process,Identity *result) {
    HANDLE token=NULL;DWORD bytes=0;BYTE buffer[4096];LPWSTR sid=NULL;BOOL ok=FALSE;
    ZeroMemory(result,sizeof(*result));result->pid=GetProcessId(process);
    if(!OpenProcessToken(process,TOKEN_QUERY,&token))return FALSE;
    if(!GetTokenInformation(token,TokenIsAppContainer,&result->app_container,sizeof(DWORD),&bytes))goto done;
    if(!GetTokenInformation(token,TokenAppContainerSid,buffer,sizeof(buffer),&bytes))goto done;
    if(!((TOKEN_APPCONTAINER_INFORMATION*)buffer)->TokenAppContainer)goto done;
    if(!ConvertSidToStringSidW(((TOKEN_APPCONTAINER_INFORMATION*)buffer)->TokenAppContainer,&sid))goto done;
    if(wcslen(sid)>=sizeof(result->sid)/sizeof(WCHAR))goto done;
    wcscpy_s(result->sid,sizeof(result->sid)/sizeof(WCHAR),sid);
    if(!GetTokenInformation(token,TokenIntegrityLevel,buffer,sizeof(buffer),&bytes))goto done;
    {PSID label=((TOKEN_MANDATORY_LABEL*)buffer)->Label.Sid;result->integrity=*GetSidSubAuthority(label,(DWORD)(*GetSidSubAuthorityCount(label)-1));}
    if(!GetTokenInformation(token,TokenCapabilities,buffer,sizeof(buffer),&bytes))goto done;
    result->capabilities=((TOKEN_GROUPS*)buffer)->GroupCount;
    ok=TRUE;
done:
    if(sid)LocalFree(sid);if(token)CloseHandle(token);return ok;
}
static WCHAR *quote_command(int argc,const WCHAR **argv) {
    size_t needed=1,at=0;int i;
    for(i=0;i<argc;i++)needed+=2*wcslen(argv[i])+4;
    if(needed>32760)return NULL;
    WCHAR *out=calloc(needed,sizeof(WCHAR));if(!out)return NULL;
    for(i=0;i<argc;i++) {
        const WCHAR *p=argv[i];size_t slashes=0;
        if(i)out[at++]=L' ';out[at++]=L'"';
        while(*p){if(*p==L'\\'){slashes++;p++;continue;}while(slashes){out[at++]=L'\\';if(*p==L'"')out[at++]=L'\\';slashes--;}if(*p==L'"')out[at++]=L'\\';out[at++]=*p++;}
        while(slashes){out[at++]=L'\\';out[at++]=L'\\';slashes--;}out[at++]=L'"';
    }
    return out;
}
static BOOL grant_directory(const WCHAR *path,PSID sid,DWORD access) {
    PACL old_acl=NULL,new_acl=NULL;PSECURITY_DESCRIPTOR descriptor=NULL;EXPLICIT_ACCESSW entry;DWORD error;
    ZeroMemory(&entry,sizeof(entry));entry.grfAccessPermissions=access;entry.grfAccessMode=GRANT_ACCESS;
    entry.grfInheritance=SUB_CONTAINERS_AND_OBJECTS_INHERIT;
    entry.Trustee.TrusteeForm=TRUSTEE_IS_SID;entry.Trustee.TrusteeType=TRUSTEE_IS_UNKNOWN;entry.Trustee.ptstrName=(LPWSTR)sid;
    error=GetNamedSecurityInfoW((LPWSTR)path,SE_FILE_OBJECT,DACL_SECURITY_INFORMATION,NULL,NULL,&old_acl,NULL,&descriptor);
    if(!error)error=SetEntriesInAclW(1,&entry,old_acl,&new_acl);
    if(!error)error=SetNamedSecurityInfoW((LPWSTR)path,SE_FILE_OBJECT,DACL_SECURITY_INFORMATION,NULL,NULL,new_acl,NULL);
    if(new_acl)LocalFree(new_acl);if(descriptor)LocalFree(descriptor);
    if(error)SetLastError(error);return error==0;
}
static BOOL low_integrity_directory(const WCHAR *path) {
    PSECURITY_DESCRIPTOR descriptor=NULL;PACL label=NULL;BOOL present=FALSE,defaulted=FALSE;DWORD error=0;
    if(!ConvertStringSecurityDescriptorToSecurityDescriptorW(L"S:(ML;OICI;NW;;;LW)",SDDL_REVISION_1,&descriptor,NULL))return FALSE;
    if(!GetSecurityDescriptorSacl(descriptor,&present,&label,&defaulted)||!present)error=ERROR_INVALID_SECURITY_DESCR;
    if(!error)error=SetNamedSecurityInfoW((LPWSTR)path,SE_FILE_OBJECT,LABEL_SECURITY_INFORMATION,NULL,NULL,NULL,label);
    LocalFree(descriptor);if(error)SetLastError(error);return error==0;
}
static BOOL grant_owner_control(const WCHAR *path) {
    HANDLE token=NULL;BYTE user[1024];DWORD bytes=0;BOOL ok=FALSE;
    if(!OpenProcessToken(GetCurrentProcess(),TOKEN_QUERY,&token))return FALSE;
    if(GetTokenInformation(token,TokenUser,user,sizeof(user),&bytes))ok=grant_directory(path,((TOKEN_USER*)user)->User.Sid,FILE_ALL_ACCESS);
    CloseHandle(token);return ok;
}
static HANDLE new_job(void) {
    HANDLE job=CreateJobObjectW(NULL,NULL);JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits;
    if(!job)return NULL;ZeroMemory(&limits,sizeof(limits));limits.BasicLimitInformation.LimitFlags=JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if(!SetInformationJobObject(job,JobObjectExtendedLimitInformation,&limits,sizeof(limits))){CloseHandle(job);return NULL;}return job;
}
static BOOL same_identity(const Identity *value,const WCHAR *expected) {
    return value->app_container==1&&!wcscmp(value->sid,expected)&&value->integrity==SECURITY_MANDATORY_LOW_RID&&value->capabilities==0;
}
static int inside(int argc,WCHAR **argv) {
    /* --inside role dataDir hostDir expectedSID round token */
    if(argc!=9)return 10;
    const WCHAR *role=argv[2],*data=argv[3],*host=argv[4],*expected=argv[5],*round=argv[6],*token=argv[7];
    if(wcslen(token)!=32||wcscmp(argv[8],L"synthetic-only"))return 11;
    Identity self;WCHAR file[MAX_PATH],leaf[96];char text[256],token8[64],sid8[192],json[2048];
    if(!identity(GetCurrentProcess(),&self)||!same_identity(&self,expected))return 12;
    WideCharToMultiByte(CP_UTF8,0,token,-1,token8,sizeof(token8),NULL,NULL);
    WideCharToMultiByte(CP_UTF8,0,self.sid,-1,sid8,sizeof(sid8),NULL,NULL);
    path_join(file,MAX_PATH,host,L"host-sentinel.txt");DWORD host_read=read_bytes(file,text,sizeof(text));
    path_join(file,MAX_PATH,data,L"persistent.txt");DWORD previous=read_bytes(file,text,sizeof(text));
    BOOL reopened=!wcscmp(round,L"2"),child=!wcscmp(role,L"child");
    BOOL persistent=(reopened||child)?previous==0&&!strcmp(text,token8):previous==ERROR_FILE_NOT_FOUND;
    BOOL own_write=TRUE,child_ok=TRUE;DWORD late_error=0,write_error=0,child_pid=0,child_exit=0;
    if(!child) {
        own_write=write_bytes(file,token8);
        swprintf_s(leaf,96,L"round%s.ready",round);path_join(file,MAX_PATH,data,leaf);
        if(!write_bytes(file,"ready"))return 13;
        swprintf_s(leaf,96,L"round%s.continue",round);path_join(file,MAX_PATH,data,leaf);
        ULONGLONG until=GetTickCount64()+15000;
        while(GetFileAttributesW(file)==INVALID_FILE_ATTRIBUTES&&GetTickCount64()<until)Sleep(20);
        if(GetFileAttributesW(file)==INVALID_FILE_ATTRIBUTES)return 14;
        swprintf_s(leaf,96,L"late-%s.txt",round);path_join(file,MAX_PATH,host,leaf);late_error=read_bytes(file,text,sizeof(text));
        path_join(file,MAX_PATH,host,L"must-not-create.txt");
        HANDLE forbidden=CreateFileW(file,GENERIC_WRITE,0,NULL,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,NULL);
        write_error=forbidden==INVALID_HANDLE_VALUE?GetLastError():0;if(forbidden!=INVALID_HANDLE_VALUE)CloseHandle(forbidden);
        WCHAR exe[MAX_PATH];GetModuleFileNameW(NULL,exe,MAX_PATH);
        const WCHAR *args[]={exe,L"--inside",L"child",data,host,expected,round,token,L"synthetic-only"};
        WCHAR *command=quote_command(9,args);STARTUPINFOW startup;PROCESS_INFORMATION process;ZeroMemory(&startup,sizeof(startup));ZeroMemory(&process,sizeof(process));startup.cb=sizeof(startup);
        if(!command||!CreateProcessW(exe,command,NULL,NULL,FALSE,CREATE_NO_WINDOW|CREATE_SUSPENDED,NULL,data,&startup,&process))child_ok=FALSE;
        else {
            Identity inherited;child_pid=process.dwProcessId;
            child_ok=identity(process.hProcess,&inherited)&&same_identity(&inherited,expected);
            if(child_ok&&ResumeThread(process.hThread)!=(DWORD)-1&&WaitForSingleObject(process.hProcess,10000)==WAIT_OBJECT_0){GetExitCodeProcess(process.hProcess,&child_exit);child_ok=child_exit==0;}
            else {TerminateProcess(process.hProcess,20);child_ok=FALSE;}
            CloseHandle(process.hThread);CloseHandle(process.hProcess);
        }
        free(command);
    } else {
        swprintf_s(leaf,96,L"child-%s.txt",round);path_join(file,MAX_PATH,data,leaf);own_write=write_bytes(file,token8);
    }
    BOOL passed=host_read==ERROR_ACCESS_DENIED&&persistent&&own_write&&child_ok&&(child||(late_error==ERROR_ACCESS_DENIED&&write_error==ERROR_ACCESS_DENIED));
    snprintf(json,sizeof(json),"{\"role\":\"%s\",\"pid\":%lu,\"appContainer\":%lu,\"sid\":\"%s\",\"integrity\":%lu,\"capabilityCount\":%lu,\"hostReadError\":%lu,\"lateHostReadError\":%lu,\"hostWriteError\":%lu,\"ownPersistence\":%s,\"ownWrite\":%s,\"childInherited\":%s,\"childPID\":%lu,\"childExit\":%lu,\"passed\":%s}",child?"child":"parent",self.pid,self.app_container,sid8,self.integrity,self.capabilities,host_read,late_error,write_error,persistent?"true":"false",own_write?"true":"false",child_ok?"true":"false",child_pid,child_exit,passed?"true":"false");
    swprintf_s(leaf,96,L"%s-%s.json",role,round);path_join(file,MAX_PATH,data,leaf);
    if(!write_bytes(file,json))return 15;return passed?0:16;
}
static int host_round(const WCHAR *exe,const WCHAR *data,const WCHAR *host,PSID sid,const WCHAR *sid_text,const WCHAR *round,const WCHAR *token) {
    SIZE_T bytes=0;STARTUPINFOEXW startup;PROCESS_INFORMATION process;SECURITY_CAPABILITIES capabilities;HANDLE job=NULL;WCHAR *command=NULL;BOOL attrs=FALSE;int result=30;DWORD error=0,exit_code=0;
    const char *stage="attributes";
    ZeroMemory(&startup,sizeof(startup));ZeroMemory(&process,sizeof(process));ZeroMemory(&capabilities,sizeof(capabilities));
    const WCHAR *args[]={exe,L"--inside",L"parent",data,host,sid_text,round,token,L"synthetic-only"};command=quote_command(9,args);
    InitializeProcThreadAttributeList(NULL,1,0,&bytes);startup.lpAttributeList=malloc(bytes);
    if(!command||!startup.lpAttributeList||!InitializeProcThreadAttributeList(startup.lpAttributeList,1,0,&bytes))goto done;
    attrs=TRUE;capabilities.AppContainerSid=sid;startup.StartupInfo.cb=sizeof(startup);
    if(!UpdateProcThreadAttribute(startup.lpAttributeList,0,PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES,&capabilities,sizeof(capabilities),NULL,NULL))goto done;
    WCHAR environment[4096],windows_dir[MAX_PATH];GetWindowsDirectoryW(windows_dir,MAX_PATH);
    int at=swprintf_s(environment,4096,L"SystemRoot=%s",windows_dir)+1;
    at+=swprintf_s(environment+at,4096-at,L"windir=%s",windows_dir)+1;
    at+=swprintf_s(environment+at,4096-at,L"SystemDrive=%.2s",windows_dir)+1;
    at+=swprintf_s(environment+at,4096-at,L"PATH=%s\\System32;%s",windows_dir,windows_dir)+1;
    at+=swprintf_s(environment+at,4096-at,L"LOCALAPPDATA=%s",data)+1;
    at+=swprintf_s(environment+at,4096-at,L"APPDATA=%s",data)+1;
    at+=swprintf_s(environment+at,4096-at,L"TEMP=%s",data)+1;
    at+=swprintf_s(environment+at,4096-at,L"TMP=%s",data)+1;
    at+=swprintf_s(environment+at,4096-at,L"USERPROFILE=%s",data)+1;environment[at]=0;
    stage="job";job=new_job();if(!job)goto done;
    stage="createProcess";
    if(!CreateProcessW(exe,command,NULL,NULL,FALSE,EXTENDED_STARTUPINFO_PRESENT|CREATE_UNICODE_ENVIRONMENT|CREATE_NO_WINDOW|CREATE_SUSPENDED,environment,data,&startup.StartupInfo,&process))goto done;
    stage="tokenCheck";
    {Identity child;if(!identity(process.hProcess,&child)||!same_identity(&child,sid_text)){SetLastError(ERROR_INVALID_TOKEN);goto done;}}
    stage="jobAssign";if(!AssignProcessToJobObject(job,process.hProcess))goto done;
    stage="resume";if(ResumeThread(process.hThread)==(DWORD)-1)goto done;
    stage="run";
    {
        WCHAR file[MAX_PATH],leaf[96];ULONGLONG deadline=GetTickCount64()+15000;
        swprintf_s(leaf,96,L"round%s.ready",round);path_join(file,MAX_PATH,data,leaf);
        while(GetFileAttributesW(file)==INVALID_FILE_ATTRIBUTES&&GetTickCount64()<deadline&&WaitForSingleObject(process.hProcess,0)==WAIT_TIMEOUT)Sleep(20);
        if(GetFileAttributesW(file)==INVALID_FILE_ATTRIBUTES){GetExitCodeProcess(process.hProcess,&exit_code);fprintf(stderr,"round ready failed: exit=%lu\n",exit_code);SetLastError(ERROR_TIMEOUT);goto done;}
        swprintf_s(leaf,96,L"late-%s.txt",round);path_join(file,MAX_PATH,host,leaf);if(!write_bytes(file,"new synthetic host-only marker"))goto done;
        swprintf_s(leaf,96,L"round%s.continue",round);path_join(file,MAX_PATH,data,leaf);if(!write_bytes(file,"continue"))goto done;
        if(WaitForSingleObject(process.hProcess,20000)!=WAIT_OBJECT_0){SetLastError(ERROR_TIMEOUT);goto done;}
        if(!GetExitCodeProcess(process.hProcess,&exit_code))goto done;
        result=exit_code?31:0;
    }
done:
    error=result?GetLastError():0;
    if(result&&process.hProcess)TerminateProcess(process.hProcess,30);
    if(job)CloseHandle(job);
    if(process.hProcess){WaitForSingleObject(process.hProcess,3000);CloseHandle(process.hProcess);}
    if(process.hThread)CloseHandle(process.hThread);
    if(attrs)DeleteProcThreadAttributeList(startup.lpAttributeList);free(startup.lpAttributeList);free(command);
    printf("{\"stage\":\"round\",\"operation\":\"%s\",\"round\":\"%ls\",\"result\":%d,\"win32Error\":%lu,\"exitCode\":%lu}\n",stage,round,result,error,exit_code);fflush(stdout);
    return result;
}
static int host_main(int argc,WCHAR **argv) {
    /* root must be a new, caller-created experiment directory. */
    if(argc!=5||wcscmp(argv[1],L"--host")||wcsncmp(argv[3],L"Cage.Feasibility.",17)||wcslen(argv[4])!=32)return 40;
    WCHAR bin[MAX_PATH],data[MAX_PATH],host[MAX_PATH],profile_file[MAX_PATH],exe[MAX_PATH],own[MAX_PATH];
    if(!path_join(bin,MAX_PATH,argv[2],L"bin")||!path_join(data,MAX_PATH,argv[2],L"data")||!path_join(host,MAX_PATH,argv[2],L"host-private"))return 41;
    if(!CreateDirectoryW(bin,NULL)||!CreateDirectoryW(data,NULL)||!CreateDirectoryW(host,NULL))return 42;
    GetModuleFileNameW(NULL,own,MAX_PATH);path_join(exe,MAX_PATH,bin,L"CageAppContainerProbe.exe");if(!CopyFileW(own,exe,TRUE))return 43;
    path_join(profile_file,MAX_PATH,host,L"host-sentinel.txt");if(!write_bytes(profile_file,"synthetic host-only marker"))return 44;
    PSID sid=NULL;LPWSTR sid_text=NULL;HRESULT hr=CreateAppContainerProfile(argv[3],argv[3],L"Cage synthetic isolation feasibility test",NULL,0,&sid);
    if(FAILED(hr)){printf("{\"stage\":\"createProfile\",\"hresult\":%lu}\n",(DWORD)hr);return 45;}
    if(!ConvertSidToStringSidW(sid,&sid_text))return 46;
    char sid8[192],name8[128],json[1024];WideCharToMultiByte(CP_UTF8,0,sid_text,-1,sid8,sizeof(sid8),NULL,NULL);WideCharToMultiByte(CP_UTF8,0,argv[3],-1,name8,sizeof(name8),NULL,NULL);
    snprintf(json,sizeof(json),"{\"name\":\"%s\",\"sid\":\"%s\",\"capabilityCount\":0,\"networkCapability\":false,\"loopbackExemption\":false,\"profileRetained\":true}",name8,sid8);
    path_join(profile_file,MAX_PATH,argv[2],L"profile.json");if(!write_bytes(profile_file,json))return 47;
    printf("{\"stage\":\"profileCreated\",\"name\":\"%s\"}\n",name8);fflush(stdout);
    int result=48;
    if(!grant_directory(bin,sid,FILE_GENERIC_READ|FILE_GENERIC_EXECUTE)){printf("{\"stage\":\"binaryAcl\",\"error\":%lu}\n",GetLastError());goto done;}
    if(!grant_directory(data,sid,FILE_GENERIC_READ|FILE_GENERIC_WRITE|FILE_TRAVERSE|DELETE)){printf("{\"stage\":\"dataAcl\",\"error\":%lu}\n",GetLastError());goto done;}
    /* Only this freshly created data directory receives the creating user's
       WRITE_OWNER right, needed to assign a lower integrity label. */
    if(!grant_owner_control(data)){printf("{\"stage\":\"newDataOwnerAcl\",\"error\":%lu}\n",GetLastError());goto done;}
    if(!low_integrity_directory(data)){printf("{\"stage\":\"lowIntegrity\",\"error\":%lu}\n",GetLastError());goto done;}
    result=host_round(exe,data,host,sid,sid_text,L"1",argv[4]);
    if(!result)result=host_round(exe,data,host,sid,sid_text,L"2",argv[4]);
done:
    LocalFree(sid_text);FreeSid(sid);return result;
}
int wmain(int argc,WCHAR **argv) {
    if(argc>1&&!wcscmp(argv[1],L"--inside"))return inside(argc,argv);
    return host_main(argc,argv);
}
