/* Synthetic workload only. MXC's official launcher supplies containment.
   This image never changes ACLs or creates an isolation environment. */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <windows.h>
#include <sddl.h>
#include <wincrypt.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <string.h>

typedef struct Identity { DWORD app, integrity, restricted, pid; WCHAR sid[192]; } Identity;
static BOOL join(WCHAR *out, const WCHAR *root, const WCHAR *leaf) {
    return swprintf_s(out, MAX_PATH, L"%s\\%s", root, leaf) > 0;
}
static BOOL write_file(const WCHAR *path, const char *text) {
    DWORD wrote=0, length=(DWORD)strlen(text);
    HANDLE h=CreateFileW(path,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);
    if(h==INVALID_HANDLE_VALUE)return FALSE;
    BOOL ok=WriteFile(h,text,length,&wrote,NULL)&&wrote==length&&FlushFileBuffers(h);
    CloseHandle(h);return ok;
}
static DWORD read_file(const WCHAR *path, char *text, DWORD count) {
    DWORD got=0;HANDLE h=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    if(h==INVALID_HANDLE_VALUE)return GetLastError();
    BOOL ok=ReadFile(h,text,count-1,&got,NULL);DWORD error=ok?0:GetLastError();
    CloseHandle(h);if(ok)text[got]=0;return error;
}
static BOOL write_blob(const WCHAR *path, const BYTE *data, DWORD length) {
    DWORD wrote=0;HANDLE h=CreateFileW(path,GENERIC_WRITE,0,NULL,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,NULL);
    if(h==INVALID_HANDLE_VALUE)return FALSE;
    BOOL ok=WriteFile(h,data,length,&wrote,NULL)&&wrote==length&&FlushFileBuffers(h);
    CloseHandle(h);return ok;
}
static DWORD read_blob(const WCHAR *path, BYTE *data, DWORD capacity, DWORD *length) {
    HANDLE h=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    if(h==INVALID_HANDLE_VALUE)return GetLastError();
    DWORD size=GetFileSize(h,NULL),error=0;
    if(size==INVALID_FILE_SIZE||size>capacity)error=ERROR_INSUFFICIENT_BUFFER;
    else if(!ReadFile(h,data,size,length,NULL)||*length!=size)error=GetLastError()?GetLastError():ERROR_READ_FAULT;
    CloseHandle(h);return error;
}
static BOOL persistence_probes(const WCHAR *data, const WCHAR *marker, const WCHAR *round) {
    WCHAR file[MAX_PATH],keyName[160],leaf[96],value[64];char marker8[64],report[2048];
    BOOL reopening=!wcscmp(round,L"2"),protectedOk=FALSE,decryptedOk=FALSE,matches=FALSE;
    DWORD protectError=0,blobError=0,unprotectError=0,blobSize=0;BYTE ciphertext[65536];
    WideCharToMultiByte(CP_UTF8,0,marker,-1,marker8,sizeof(marker8),NULL,NULL);
    DATA_BLOB plain={(DWORD)strlen(marker8),(BYTE*)marker8},encrypted={0,NULL},decrypted={0,NULL};
    join(file,data,L"dpapi-synthetic.bin");
    if(!reopening) {
        protectedOk=CryptProtectData(&plain,L"Cage synthetic random marker",NULL,NULL,NULL,CRYPTPROTECT_UI_FORBIDDEN,&encrypted);
        if(!protectedOk)protectError=GetLastError();
        else if(!write_blob(file,encrypted.pbData,encrypted.cbData))blobError=GetLastError();
        if(encrypted.pbData)LocalFree(encrypted.pbData);
    }
    if(!blobError)blobError=read_blob(file,ciphertext,sizeof(ciphertext),&blobSize);
    if(!blobError) {
        encrypted.pbData=ciphertext;encrypted.cbData=blobSize;
        decryptedOk=CryptUnprotectData(&encrypted,NULL,NULL,NULL,NULL,CRYPTPROTECT_UI_FORBIDDEN,&decrypted);
        if(!decryptedOk)unprotectError=GetLastError();
        else matches=decrypted.cbData==plain.cbData&&!memcmp(decrypted.pbData,plain.pbData,plain.cbData);
        if(decrypted.pbData){SecureZeroMemory(decrypted.pbData,decrypted.cbData);LocalFree(decrypted.pbData);}
    }
    swprintf_s(keyName,160,L"Software\\CageMxcSynthetic\\%s",marker);
    HKEY key=NULL;DWORD disposition=0,type=0,size=sizeof(value);LSTATUS regError=0,openError=0,setError=0,queryError=0;BOOL registryMatches=FALSE;
    if(reopening)regError=openError=RegOpenKeyExW(HKEY_CURRENT_USER,keyName,0,KEY_QUERY_VALUE,&key);
    else {
        regError=openError=RegCreateKeyExW(HKEY_CURRENT_USER,keyName,0,NULL,REG_OPTION_NON_VOLATILE,KEY_SET_VALUE|KEY_QUERY_VALUE,NULL,&key,&disposition);
        if(!regError&&disposition!=REG_CREATED_NEW_KEY)regError=ERROR_ALREADY_EXISTS;
        if(!regError)regError=setError=RegSetValueExW(key,L"RandomSyntheticMarker",0,REG_SZ,(const BYTE*)marker,((DWORD)wcslen(marker)+1)*sizeof(WCHAR));
    }
    if(!regError) {
        ZeroMemory(value,sizeof(value));regError=queryError=RegQueryValueExW(key,L"RandomSyntheticMarker",NULL,&type,(BYTE*)value,&size);
        registryMatches=!regError&&type==REG_SZ&&size==((DWORD)wcslen(marker)+1)*sizeof(WCHAR)&&!wcscmp(value,marker);
    }
    if(key)RegCloseKey(key);
    snprintf(report,sizeof(report),"{\"round\":%ls,\"pid\":%lu,\"dpapi\":{\"protectAttempted\":%s,\"protected\":%s,\"protectError\":%lu,\"blobReadError\":%lu,\"encryptedBytes\":%lu,\"decrypted\":%s,\"unprotectError\":%lu,\"payloadMatches\":%s,\"passed\":%s},\"registry\":{\"createAttempted\":%s,\"disposition\":%lu,\"openOrCreateError\":%ld,\"setError\":%ld,\"queryError\":%ld,\"error\":%ld,\"payloadMatches\":%s,\"passed\":%s}}",round,GetCurrentProcessId(),reopening?"false":"true",protectedOk?"true":"false",protectError,blobError,blobSize,decryptedOk?"true":"false",unprotectError,matches?"true":"false",matches&&(reopening||protectedOk)?"true":"false",reopening?"false":"true",disposition,openError,setError,queryError,regError,registryMatches?"true":"false",registryMatches?"true":"false");
    swprintf_s(leaf,96,L"supplemental-%s.json",round);join(file,data,leaf);
    return write_file(file,report);
}
static BOOL identity(HANDLE process, Identity *result) {
    HANDLE token=NULL;BYTE buffer[4096];DWORD bytes=0;LPWSTR sid=NULL;BOOL ok=FALSE;
    ZeroMemory(result,sizeof(*result));result->pid=GetProcessId(process);
    wcscpy_s(result->sid,192,L"none");
    if(!OpenProcessToken(process,TOKEN_QUERY,&token))return FALSE;
    if(!GetTokenInformation(token,TokenIsAppContainer,&result->app,sizeof(DWORD),&bytes))goto done;
    if(result->app) {
        if(!GetTokenInformation(token,TokenAppContainerSid,buffer,sizeof(buffer),&bytes))goto done;
        PSID value=((TOKEN_APPCONTAINER_INFORMATION*)buffer)->TokenAppContainer;
        if(!value||!ConvertSidToStringSidW(value,&sid))goto done;
        if(wcslen(sid)>=192)goto done;wcscpy_s(result->sid,192,sid);
    }
    if(!GetTokenInformation(token,TokenIntegrityLevel,buffer,sizeof(buffer),&bytes))goto done;
    PSID label=((TOKEN_MANDATORY_LABEL*)buffer)->Label.Sid;
    result->integrity=*GetSidSubAuthority(label,(DWORD)(*GetSidSubAuthorityCount(label)-1));
    result->restricted=IsTokenRestricted(token);ok=TRUE;
done:
    if(sid)LocalFree(sid);if(token)CloseHandle(token);return ok;
}
static WCHAR *command_line(int argc, const WCHAR **argv) {
    size_t n=1,at=0;int i;
    for(i=0;i<argc;i++)n+=2*wcslen(argv[i])+4;
    if(n>32760)return NULL;WCHAR *out=calloc(n,sizeof(WCHAR));if(!out)return NULL;
    for(i=0;i<argc;i++) {
        const WCHAR *p=argv[i];size_t slashes=0;if(i)out[at++]=L' ';out[at++]=L'"';
        while(*p){if(*p==L'\\'){slashes++;p++;continue;}while(slashes){out[at++]=L'\\';if(*p==L'"')out[at++]=L'\\';slashes--;}if(*p==L'"')out[at++]=L'\\';out[at++]=*p++;}
        while(slashes){out[at++]=L'\\';out[at++]=L'\\';slashes--;}out[at++]=L'"';
    }
    return out;
}
int wmain(int argc,WCHAR **argv) {
    /* role dataDir hostDir round randomMarker synthetic-only [persistence] */
    BOOL supplemental=argc==8&&!wcscmp(argv[7],L"persistence");
    if((argc!=7&&!supplemental)||wcscmp(argv[6],L"synthetic-only")||wcslen(argv[5])!=32)return 10;
    BOOL child=!wcscmp(argv[1],L"child"),reopen=!wcscmp(argv[4],L"2");
    if(!child&&wcscmp(argv[1],L"parent"))return 11;
    const WCHAR *data=argv[2],*host=argv[3],*round=argv[4],*marker=argv[5];
    WCHAR file[MAX_PATH],leaf[96],exe[MAX_PATH],binary[MAX_PATH];char text[512],marker8[64],sid8[192],json[3072];Identity self;
    if(!identity(GetCurrentProcess(),&self))return 12;
    WideCharToMultiByte(CP_UTF8,0,marker,-1,marker8,sizeof(marker8),NULL,NULL);
    WideCharToMultiByte(CP_UTF8,0,self.sid,-1,sid8,sizeof(sid8),NULL,NULL);
    GetModuleFileNameW(NULL,exe,MAX_PATH);wcscpy_s(binary,MAX_PATH,exe);WCHAR *slash=wcsrchr(binary,L'\\');if(!slash)return 18;*slash=0;
    join(file,binary,L"bin-ro-sentinel.txt");DWORD readonlyRead=read_file(file,text,sizeof(text));BOOL readonlyContent=!readonlyRead&&!strcmp(text,"synthetic read-only binary directory marker");
    swprintf_s(leaf,96,L"bin-must-not-create-%s-%s.txt",argv[1],round);join(file,binary,leaf);
    HANDLE deniedBinary=CreateFileW(file,GENERIC_WRITE,0,NULL,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,NULL);
    DWORD readonlyWrite=deniedBinary==INVALID_HANDLE_VALUE?GetLastError():0;if(deniedBinary!=INVALID_HANDLE_VALUE)CloseHandle(deniedBinary);
    join(file,host,L"host-sentinel.txt");DWORD hostRead=read_file(file,text,sizeof(text));
    join(file,data,L"persistent.txt");DWORD prior=read_file(file,text,sizeof(text));
    BOOL persistence=(child||reopen)?prior==0&&!strcmp(text,marker8):prior==ERROR_FILE_NOT_FOUND;
    BOOL ownWrite=child?TRUE:write_file(file,marker8),inherited=TRUE;DWORD childPID=0,childExit=0,spawnError=0;
    if(!child) {
        swprintf_s(leaf,96,L"round%s.ready",round);join(file,data,leaf);if(!write_file(file,"ready"))return 13;
        swprintf_s(leaf,96,L"round%s.continue",round);join(file,data,leaf);ULONGLONG deadline=GetTickCount64()+15000;
        while(GetFileAttributesW(file)==INVALID_FILE_ATTRIBUTES&&GetTickCount64()<deadline)Sleep(20);
        if(GetFileAttributesW(file)==INVALID_FILE_ATTRIBUTES)return 14;
    }
    swprintf_s(leaf,96,L"late-%s.txt",round);join(file,host,leaf);DWORD lateRead=read_file(file,text,sizeof(text));
    join(file,host,L"must-not-create.txt");HANDLE denied=CreateFileW(file,GENERIC_WRITE,0,NULL,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,NULL);
    DWORD hostWrite=denied==INVALID_HANDLE_VALUE?GetLastError():0;if(denied!=INVALID_HANDLE_VALUE)CloseHandle(denied);
    if(!child) {
        const WCHAR *args[]={exe,L"child",data,host,round,marker,L"synthetic-only"};WCHAR *command=command_line(7,args);
        STARTUPINFOW si;PROCESS_INFORMATION pi;ZeroMemory(&si,sizeof(si));ZeroMemory(&pi,sizeof(pi));si.cb=sizeof(si);
        if(!command||!CreateProcessW(exe,command,NULL,NULL,FALSE,CREATE_NO_WINDOW|CREATE_SUSPENDED,NULL,data,&si,&pi)){inherited=FALSE;spawnError=GetLastError();}
        else {
            Identity other;childPID=pi.dwProcessId;inherited=identity(pi.hProcess,&other)&&self.app==other.app&&self.integrity==other.integrity&&self.restricted==other.restricted&&!wcscmp(self.sid,other.sid);
            if(inherited&&ResumeThread(pi.hThread)!=(DWORD)-1&&WaitForSingleObject(pi.hProcess,10000)==WAIT_OBJECT_0){GetExitCodeProcess(pi.hProcess,&childExit);inherited=childExit==0;}
            else {TerminateProcess(pi.hProcess,20);WaitForSingleObject(pi.hProcess,3000);inherited=FALSE;}
            CloseHandle(pi.hThread);CloseHandle(pi.hProcess);
        }
        free(command);
        if(supplemental&&!persistence_probes(data,marker,round))return 17;
    } else {
        swprintf_s(leaf,96,L"child-%s.txt",round);join(file,data,leaf);ownWrite=write_file(file,marker8);
    }
    BOOL passed=hostRead==ERROR_ACCESS_DENIED&&lateRead==ERROR_ACCESS_DENIED&&hostWrite==ERROR_ACCESS_DENIED&&readonlyContent&&readonlyWrite==ERROR_ACCESS_DENIED&&persistence&&ownWrite&&inherited;
    snprintf(json,sizeof(json),"{\"role\":\"%s\",\"pid\":%lu,\"appContainer\":%lu,\"sid\":\"%s\",\"integrity\":%lu,\"restricted\":%lu,\"hostReadError\":%lu,\"lateHostReadError\":%lu,\"hostWriteError\":%lu,\"readonlyReadError\":%lu,\"readonlyWriteError\":%lu,\"readonlyContentMatches\":%s,\"ownPersistence\":%s,\"ownWrite\":%s,\"childInheritedTokenAndBehavior\":%s,\"childPID\":%lu,\"childExit\":%lu,\"spawnError\":%lu,\"passed\":%s}",child?"child":"parent",self.pid,self.app,sid8,self.integrity,self.restricted,hostRead,lateRead,hostWrite,readonlyRead,readonlyWrite,readonlyContent?"true":"false",persistence?"true":"false",ownWrite?"true":"false",inherited?"true":"false",childPID,childExit,spawnError,passed?"true":"false");
    swprintf_s(leaf,96,L"%s-%s.json",argv[1],round);join(file,data,leaf);
    if(!write_file(file,json))return 15;printf("%s\n",json);return passed?0:16;
}
