/* First-party blocking Winsock client. It never reads proxy configuration. */
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

static WCHAR output_directory[32768], executable_directory[32768];
static WCHAR stage[32], role[32], nonce[80];
static unsigned short ports[3];

static int exchange(SOCKET socket, const char *challenge, int target) {
    char request[256], expected[256], response[256];
    int length = _snprintf_s(request, sizeof(request), _TRUNCATE, "%s\n", challenge);
    _snprintf_s(expected, sizeof(expected), _TRUNCATE, "ACK:%d:%s\n", target, challenge);
    for (int offset = 0; offset < length;) {
        int count = send(socket, request + offset, length - offset, 0);
        if (count <= 0) return 0;
        offset += count;
    }
    int count = 0;
    while (count < (int)sizeof(response) - 1) {
        int received = recv(socket, response + count, 1, 0);
        if (received <= 0) return 0;
        if (response[count++] == '\n') break;
    }
    response[count] = 0;
    if (strcmp(response, expected)) { WSASetLastError(WSAECONNRESET); return 0; }
    return 1;
}

static SOCKET attempt(int target, const char *challenge, int *success, int *error) {
    SOCKET socket_handle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    *success = 0; *error = 0;
    if (socket_handle == INVALID_SOCKET) { *error = WSAGetLastError(); return INVALID_SOCKET; }
    DWORD timeout = 1500;
    setsockopt(socket_handle, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
    setsockopt(socket_handle, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));
    SOCKADDR_IN address = {0};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons(ports[target]);
    if (connect(socket_handle, (SOCKADDR *)&address, sizeof(address)) == 0 && exchange(socket_handle, challenge, target)) {
        *success = 1;
        return socket_handle;
    }
    *error = WSAGetLastError();
    closesocket(socket_handle);
    return INVALID_SOCKET;
}

static int publish(const WCHAR *phase, const int success[3], const int errors[3], const int existing[2]) {
    WCHAR final_path[32768], temporary[32768], box[64] = {0};
    char box_utf8[256] = {0}, role_utf8[64], phase_utf8[64];
    _snwprintf_s(final_path, 32768, _TRUNCATE, L"%s\\%s-%s.json", output_directory, role, phase);
    _snwprintf_s(temporary, 32768, _TRUNCATE, L"%s.tmp", final_path);
    HMODULE sandbox = GetModuleHandleW(L"SbieDll.dll");
    typedef LONG (*QueryProcess)(HANDLE, WCHAR *, WCHAR *, WCHAR *, ULONG *);
    QueryProcess query = sandbox ? (QueryProcess)(void *)GetProcAddress(sandbox, "SbieApi_QueryProcess") : NULL;
    if (query) query((HANDLE)(ULONG_PTR)GetCurrentProcessId(), box, NULL, NULL, NULL);
    WideCharToMultiByte(CP_UTF8, 0, box, -1, box_utf8, sizeof(box_utf8), NULL, NULL);
    WideCharToMultiByte(CP_UTF8, 0, role, -1, role_utf8, sizeof(role_utf8), NULL, NULL);
    WideCharToMultiByte(CP_UTF8, 0, phase, -1, phase_utf8, sizeof(phase_utf8), NULL, NULL);
    HMODULE adapter = GetModuleHandleW(L"CageSyncProxy.dll");
    typedef DWORD (WINAPI *Status)(void);
    Status status = adapter ? (Status)(void *)GetProcAddress(adapter, "CageSyncStatus") : NULL;
    Status diagnostic = adapter ? (Status)(void *)GetProcAddress(adapter, "CageSyncStage") : NULL;
    DWORD ready = status ? status() : 0;
    FILE *file = _wfopen(temporary, L"wb");
    if (!file) return 0;
    fprintf(file, "{\"pid\":%lu,\"box\":\"%s\",\"role\":\"%s\",\"phase\":\"%s\","
            "\"adapter_loaded\":%s,\"adapter_stage\":%lu,\"adapter_ready\":%s,\"success\":[%d,%d,%d],\"errors\":[%d,%d,%d],\"existing_after_cut\":[%d,%d]}\n",
            GetCurrentProcessId(), box_utf8, role_utf8, phase_utf8, adapter ? "true" : "false", diagnostic ? diagnostic() : 0,
            ready == GetCurrentProcessId() ? "true" : "false",
            success[0], success[1], success[2], errors[0], errors[1], errors[2], existing[0], existing[1]);
    int ok = !ferror(file) && fflush(file) == 0;
    fclose(file);
    return ok && MoveFileExW(temporary, final_path, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
}

static HANDLE spawn(const WCHAR *image, const WCHAR *next_stage, const WCHAR *next_role) {
    WCHAR path[32768], command[32768];
    _snwprintf_s(path, 32768, _TRUNCATE, L"%s\\%s", executable_directory, image);
    _snwprintf_s(command, 32768, _TRUNCATE, L"\"%s\" \"%s\" %s %s %hu %hu %hu probe %s",
                 path, output_directory, next_stage, next_role, ports[0], ports[1], ports[2], nonce);
    STARTUPINFOW startup = {0}; PROCESS_INFORMATION process = {0};
    startup.cb = sizeof(startup); startup.dwFlags = STARTF_USESHOWWINDOW; startup.wShowWindow = SW_HIDE;
    if (!CreateProcessW(path, command, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, executable_directory, &startup, &process)) return NULL;
    CloseHandle(process.hThread);
    return process.hProcess;
}

int wmain(int argc, WCHAR **argv) {
    if (argc != 9 || wcslen(argv[1]) > 30000 || wcslen(argv[2]) > 30 || wcslen(argv[3]) > 30 || wcslen(argv[8]) > 70) return 2;
    wcscpy_s(output_directory, 32768, argv[1]); wcscpy_s(stage, 32, argv[2]);
    wcscpy_s(role, 32, argv[3]); wcscpy_s(nonce, 80, argv[8]);
    for (int i = 0; i < 3; i++) {
        unsigned long port = wcstoul(argv[4 + i], NULL, 10);
        if (!port || port > 65535) return 2;
        ports[i] = (unsigned short)port;
    }
    /* argv[7] is a fixed reserved word; it prevents accidental execution with
       arguments from an unrelated application entry. */
    if (wcscmp(argv[7], L"probe")) return 2;
    DWORD path_length = GetModuleFileNameW(NULL, executable_directory, 32768);
    if (!path_length || path_length >= 32768) return 2;
    WCHAR *separator = wcsrchr(executable_directory, L'\\'); if (!separator) return 2; *separator = 0;
    WSADATA winsock; if (WSAStartup(MAKEWORD(2, 2), &winsock)) return 3;
    HANDLE child = NULL;
    BOOL online = !wcscmp(stage, L"online");
    if (online && !wcscmp(role, L"parent")) child = spawn(L"SyncChild.exe", stage, L"child");
    if (online && !wcscmp(role, L"child")) child = spawn(L"SyncGrandchild.exe", stage, L"grandchild");
    if (online && wcscmp(role, L"grandchild") && !child) { WSACleanup(); return 4; }
    char ascii_nonce[80], ascii_role[40], challenge[220];
    WideCharToMultiByte(CP_UTF8, 0, nonce, -1, ascii_nonce, sizeof(ascii_nonce), NULL, NULL);
    WideCharToMultiByte(CP_UTF8, 0, role, -1, ascii_role, sizeof(ascii_role), NULL, NULL);
    SOCKET sockets[3]; int success[3] = {0}, errors[3] = {0}, existing[2] = {-1, -1};
    for (int i = 0; i < 3; i++) {
        _snprintf_s(challenge, sizeof(challenge), _TRUNCATE, "%s:%s:initial:%d", ascii_nonce, ascii_role, i);
        sockets[i] = attempt(i, challenge, &success[i], &errors[i]);
    }
    if (!publish(stage, success, errors, existing)) return 5;
    if (online) {
        WCHAR signal[32768]; _snwprintf_s(signal, 32768, _TRUNCATE, L"%s\\cut.signal", output_directory);
        ULONGLONG until = GetTickCount64() + 45000;
        while (GetFileAttributesW(signal) == INVALID_FILE_ATTRIBUTES) {
            if (GetTickCount64() > until) return 6;
            Sleep(40);
        }
        for (int i = 0; i < 2; i++) {
            _snprintf_s(challenge, sizeof(challenge), _TRUNCATE, "%s:%s:existing-after-cut:%d", ascii_nonce, ascii_role, i);
            existing[i] = sockets[i] != INVALID_SOCKET && exchange(sockets[i], challenge, i);
        }
        for (int i = 0; i < 3; i++) {
            if (sockets[i] != INVALID_SOCKET) closesocket(sockets[i]);
            _snprintf_s(challenge, sizeof(challenge), _TRUNCATE, "%s:%s:fresh-after-cut:%d", ascii_nonce, ascii_role, i);
            sockets[i] = attempt(i, challenge, &success[i], &errors[i]);
        }
        if (!publish(L"after-cut", success, errors, existing)) return 5;
        if (!wcscmp(role, L"parent")) {
            HANDLE late = spawn(L"SyncChild.exe", L"after-cut", L"late");
            if (!late || WaitForSingleObject(late, 15000) != WAIT_OBJECT_0) return 7;
            CloseHandle(late);
        }
    }
    for (int i = 0; i < 3; i++) if (sockets[i] != INVALID_SOCKET) closesocket(sockets[i]);
    int code = 0;
    if (child) {
        DWORD child_code = 1;
        if (WaitForSingleObject(child, 15000) != WAIT_OBJECT_0 || !GetExitCodeProcess(child, &child_code)) code = 8;
        else if (child_code) code = (int)child_code;
        CloseHandle(child);
    }
    WSACleanup();
    return code;
}
