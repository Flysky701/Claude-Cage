// Narrow Git-for-Windows candidate: the main image's single named import only.
// No file access, token, ACL, child injection or system DLL code is changed.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wchar.h>
#include <string.h>

typedef DWORD (WINAPI *FinalPath)(HANDLE, LPWSTR, DWORD, DWORD);
static FinalPath original_path;
static volatile LONG fallbacks;
static DWORD installed;

static BOOL same_directory(HANDLE a, HANDLE b) {
    BY_HANDLE_FILE_INFORMATION x, y;
    return GetFileInformationByHandle(a, &x) && GetFileInformationByHandle(b, &y)
        && (x.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        && (y.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        && x.dwVolumeSerialNumber == y.dwVolumeSerialNumber
        && x.nFileIndexHigh == y.nFileIndexHigh && x.nFileIndexLow == y.nFileIndexLow;
}

static DWORD WINAPI current_directory_path(HANDLE file, LPWSTR output, DWORD capacity, DWORD flags) {
    DWORD result = original_path(file, output, capacity, flags);
    DWORD original_error = GetLastError();
    if (result || original_error != ERROR_ACCESS_DENIED || (flags != 0 && flags != FILE_NAME_OPENED))
        return result;

    // Large buffers live on the heap rather than Git's frequently used stack.
    WCHAR *memory = HeapAlloc(GetProcessHeap(), 0, 3 * 32768 * sizeof(WCHAR));
    HANDLE current = INVALID_HANDLE_VALUE;
    if (!memory) goto unchanged;
    WCHAR *cwd = memory, *relative = memory + 32768, *recheck = memory + 65536;
    DWORD length = GetCurrentDirectoryW(32768, cwd);
    if (!length || length >= 32764 || cwd[1] != L':' || cwd[2] != L'\\'
        || !((cwd[0] >= L'A' && cwd[0] <= L'Z') || (cwd[0] >= L'a' && cwd[0] <= L'z')))
        goto unchanged;
    current = CreateFileW(cwd, FILE_READ_ATTRIBUTES, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    if (current == INVALID_HANDLE_VALUE || !same_directory(file, current)) goto unchanged;

    // A normal permission-checked, volume-free query must agree with the cwd
    // suffix. Refuse junction/mount/subst aliases instead of guessing a drive.
    DWORD normalized = original_path(file, relative, 32768, flags | VOLUME_NAME_NONE);
    if (!normalized || normalized >= 32768 || _wcsicmp(relative, cwd + 2)) goto unchanged;
    DWORD second_length = GetCurrentDirectoryW(32768, recheck);
    if (second_length != length || wcscmp(cwd, recheck)) goto unchanged;
    if (!output && capacity) goto unchanged;

    // DOS-mode final paths have the extended-length prefix. The API's short
    // buffer result includes NUL; its successful result excludes NUL.
    DWORD final_length = normalized + 6;
    InterlockedIncrement(&fallbacks);
    if (capacity <= final_length) {
        result = final_length + 1;
        original_error = ERROR_INSUFFICIENT_BUFFER;
    } else {
        output[0] = L'\\'; output[1] = L'\\'; output[2] = L'?'; output[3] = L'\\';
        output[4] = cwd[0]; output[5] = L':';
        memcpy(output + 6, relative, (normalized + 1) * sizeof(WCHAR));
        result = final_length;
        original_error = ERROR_SUCCESS;
    }
unchanged:
    if (current != INVALID_HANDLE_VALUE) CloseHandle(current);
    if (memory) HeapFree(GetProcessHeap(), 0, memory);
    SetLastError(original_error);
    return result;
}

__declspec(dllexport) DWORD WINAPI NativePathCompatStatus(void *unused) {
    (void)unused;
    return installed | ((DWORD)InterlockedCompareExchange(&fallbacks, 0, 0) << 8);
}

static BOOL install_main_import(void) {
    WCHAR executable[32768];
    if (!GetModuleFileNameW(NULL, executable, 32768)) return FALSE;
    WCHAR *base = wcsrchr(executable, L'\\');
    if (!base || _wcsicmp(base + 1, L"git.exe")) return FALSE;
    HANDLE token;
    DWORD is_container = 0, bytes = 0;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) return FALSE;
    BOOL valid = GetTokenInformation(token, TokenIsAppContainer, &is_container, sizeof(is_container), &bytes);
    CloseHandle(token);
    if (!valid || !is_container) return FALSE;

    BYTE *image = (BYTE *)GetModuleHandleW(NULL);
    IMAGE_DOS_HEADER *dos = (IMAGE_DOS_HEADER *)image;
    IMAGE_NT_HEADERS *nt = (IMAGE_NT_HEADERS *)(image + dos->e_lfanew);
    DWORD rva = nt->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
    if (!rva) return FALSE;
    original_path = (FinalPath)(void *)GetProcAddress(GetModuleHandleW(L"kernel32.dll"), "GetFinalPathNameByHandleW");
    if (!original_path) return FALSE;
    ULONG_PTR *slot = NULL;
    for (IMAGE_IMPORT_DESCRIPTOR *entry = (IMAGE_IMPORT_DESCRIPTOR *)(image + rva); entry->Name; ++entry) {
        if (!entry->OriginalFirstThunk) continue;
        IMAGE_THUNK_DATA *names = (IMAGE_THUNK_DATA *)(image + entry->OriginalFirstThunk);
        IMAGE_THUNK_DATA *iat = (IMAGE_THUNK_DATA *)(image + entry->FirstThunk);
        for (; names->u1.AddressOfData; ++names, ++iat) {
            if (IMAGE_SNAP_BY_ORDINAL(names->u1.Ordinal)) continue;
            IMAGE_IMPORT_BY_NAME *name = (IMAGE_IMPORT_BY_NAME *)(image + names->u1.AddressOfData);
            if (strcmp((const char *)name->Name, "GetFinalPathNameByHandleW")) continue;
            if (slot || iat->u1.Function != (ULONG_PTR)original_path) return FALSE;
            slot = &iat->u1.Function;
        }
    }
    if (!slot) return FALSE;
    DWORD protection, ignored;
    if (!VirtualProtect(slot, sizeof(*slot), PAGE_READWRITE, &protection)) return FALSE;
    InterlockedExchangePointer((PVOID volatile *)slot, (PVOID)current_directory_path);
    if (!VirtualProtect(slot, sizeof(*slot), protection, &ignored)) {
        InterlockedExchangePointer((PVOID volatile *)slot, (PVOID)original_path);
        return FALSE;
    }
    installed = 1;
    return TRUE;
}

BOOL WINAPI DllMain(HINSTANCE self, DWORD reason, LPVOID reserved) {
    (void)self; (void)reserved;
    if (reason == DLL_PROCESS_ATTACH) return install_main_import();
    return TRUE;
}
