#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <sddl.h>
#include <stdio.h>
#include <wchar.h>

typedef DWORD (WINAPI *FinalPath)(HANDLE, LPWSTR, DWORD, DWORD);
typedef DWORD (WINAPI *CompatStatus)(void *);
static int passed = 1;
static void check(const char *name, int value) {
    printf("%s=%s\n", name, value ? "true" : "false");
    if (!value) passed = 0;
}
static int equal_call(FinalPath raw, HANDLE file, DWORD flags) {
    WCHAR one[32768] = L"", two[32768] = L"";
    SetLastError(1234); DWORD a = raw(file, one, 32768, flags), ae = GetLastError();
    SetLastError(1234); DWORD b = GetFinalPathNameByHandleW(file, two, 32768, flags), be = GetLastError();
    return a == b && (a ? !wcscmp(one, two) : ae == be);
}
int wmain(int argc, WCHAR **argv) {
    if (argc != 3) return 2;
    HANDLE token = NULL;
    DWORD value = 0, bytes = 0;
    check("tokenOpened", OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token));
    check("isAppContainer", GetTokenInformation(token, TokenIsAppContainer, &value, sizeof(value), &bytes) && value == 1);
    BYTE info[2048];
    check("capabilityCountZero", GetTokenInformation(token, TokenCapabilities, info, sizeof(info), &bytes) && ((TOKEN_GROUPS *)info)->GroupCount == 0);
    WCHAR *sid = NULL;
    BOOL package = GetTokenInformation(token, TokenAppContainerSid, info, sizeof(info), &bytes)
        && ConvertSidToStringSidW(((TOKEN_APPCONTAINER_INFORMATION *)info)->TokenAppContainer, &sid);
    check("exactPackageSid", package && !wcscmp(sid, argv[1]));
    if (sid) LocalFree(sid);
    if (token) CloseHandle(token);

    FinalPath raw = (FinalPath)(void *)GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "GetFinalPathNameByHandleW");
    CompatStatus status = (CompatStatus)(void *)GetProcAddress(GetModuleHandleW(L"NativePathCompat.dll"), "NativePathCompatStatus");
    check("singleMainImageImportInstalled", status && (status(NULL) & 1));
    WCHAR cwd[32768], final[32768], expected[32768];
    check("getCurrentDirectory", GetCurrentDirectoryW(32768, cwd) != 0);
    HANDLE current = CreateFileW(cwd, FILE_READ_ATTRIBUTES, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    check("openCurrentDirectory", current != INVALID_HANDLE_VALUE);
    SetLastError(0);
    DWORD before = raw(current, final, 32768, 0), before_error = GetLastError();
    check("originalDosFailureIsAccessDenied", !before && before_error == ERROR_ACCESS_DENIED);
    _snwprintf(expected, 32768, L"\\\\?\\%ls", cwd);
    DWORD count = GetFinalPathNameByHandleW(current, final, 32768, 0);
    check("cwdDosFallback", count == wcslen(expected) && !_wcsicmp(final, expected));
    WCHAR small[1] = { L'X' };
    check("nullBufferRequiredSize", GetFinalPathNameByHandleW(current, NULL, 0, 0) == count + 1);
    check("shortBufferRequiredSize", GetFinalPathNameByHandleW(current, small, 1, 0) == count + 1 && small[0] == L'X');
    check("exactLengthNeedsNull", GetFinalPathNameByHandleW(current, final, count, 0) == count + 1);
    check("openedDosFallback", GetFinalPathNameByHandleW(current, final, 32768, FILE_NAME_OPENED) == count && !_wcsicmp(final, expected));
    check("volumeNoneUnchanged", equal_call(raw, current, VOLUME_NAME_NONE));
    check("volumeNoneOpenedUnchanged", equal_call(raw, current, VOLUME_NAME_NONE | FILE_NAME_OPENED));
    check("volumeGuidUnchanged", equal_call(raw, current, VOLUME_NAME_GUID));
    check("volumeNtUnchanged", equal_call(raw, current, VOLUME_NAME_NT));
    check("invalidFlagsUnchanged", equal_call(raw, current, 0x40000000));
    check("invalidHandleUnchanged", equal_call(raw, INVALID_HANDLE_VALUE, 0));
    CreateDirectoryW(L"other-directory", NULL);
    HANDLE other = CreateFileW(L"other-directory", FILE_READ_ATTRIBUTES, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    check("differentDirectoryUnchanged", other != INVALID_HANDLE_VALUE && equal_call(raw, other, 0));
    if (other != INVALID_HANDLE_VALUE) CloseHandle(other);
    HANDLE regular = CreateFileW(L"ordinary.txt", GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    check("regularFileUnchanged", regular != INVALID_HANDLE_VALUE && equal_call(raw, regular, 0));
    if (regular != INVALID_HANDLE_VALUE) CloseHandle(regular);
    HANDLE secret = CreateFileW(argv[2], GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    DWORD private_error = GetLastError();
    check("privateFileStillDenied", secret == INVALID_HANDLE_VALUE && private_error == ERROR_ACCESS_DENIED);
    if (secret != INVALID_HANDLE_VALUE) CloseHandle(secret);
    check("systemExportStillUnchanged", !raw(current, final, 32768, 0) && GetLastError() == ERROR_ACCESS_DENIED);
    check("fallbackWasExercised", status && (status(NULL) >> 8) >= 5);
    if (current != INVALID_HANDLE_VALUE) CloseHandle(current);
    printf("passed=%s\n", passed ? "true" : "false");
    return passed ? 0 : 1;
}
