#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0A00
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <sddl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Independent bounded loopback transport probe. It changes no network policy.
 * Usage: tcp-listen|tcp-client address port nonce result.json
 * A listener writes result.json.ready with its actual port before accepting.
 * Success requires the exact nonce in both directions, not a TCP handshake.
 */
static const char *stage = "arguments";
static DWORD error_code;
static int is_container = -1;
static char container_sid[256];

static void identity(void) {
    HANDLE token = NULL;
    DWORD needed = 0, value = 0;
    BYTE *buffer = NULL;
    LPSTR sid = NULL;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) return;
    if (GetTokenInformation(token, TokenIsAppContainer, &value, sizeof(value), &needed))
        is_container = (int)value;
    GetTokenInformation(token, TokenAppContainerSid, NULL, 0, &needed);
    if (needed && (buffer = (BYTE *)malloc(needed)) != NULL &&
        GetTokenInformation(token, TokenAppContainerSid, buffer, needed, &needed)) {
        TOKEN_APPCONTAINER_INFORMATION *info = (TOKEN_APPCONTAINER_INFORMATION *)buffer;
        if (info->TokenAppContainer && ConvertSidToStringSidA(info->TokenAppContainer, &sid)) {
            strncpy_s(container_sid, sizeof(container_sid), sid, _TRUNCATE);
            LocalFree(sid);
        }
    }
    free(buffer);
    CloseHandle(token);
}

static int record(const wchar_t *path, int ok, unsigned short port, int bytes) {
    FILE *file = NULL;
    if (_wfopen_s(&file, path, L"wb") || !file) return 0;
    fprintf(file, "{\"ok\":%s,\"stage\":\"%s\",\"error\":%lu,"
        "\"pid\":%lu,\"appContainer\":%d,\"sid\":\"%s\","
        "\"port\":%u,\"bytes\":%d}\n", ok ? "true" : "false", stage,
        (unsigned long)error_code, (unsigned long)GetCurrentProcessId(),
        is_container, container_sid, (unsigned int)port, bytes);
    fclose(file);
    return 1;
}

static int await_socket(SOCKET socket, int writing, DWORD timeout_ms) {
    fd_set ready, failed;
    struct timeval timeout;
    int result;
    FD_ZERO(&ready); FD_SET(socket, &ready);
    FD_ZERO(&failed); FD_SET(socket, &failed);
    timeout.tv_sec = (long)(timeout_ms / 1000);
    timeout.tv_usec = (long)((timeout_ms % 1000) * 1000);
    result = select(0, writing ? NULL : &ready, writing ? &ready : NULL, &failed, &timeout);
    if (result == SOCKET_ERROR) { error_code = (DWORD)WSAGetLastError(); return 0; }
    if (!result) { error_code = WSAETIMEDOUT; return 0; }
    if (FD_ISSET(socket, &failed)) {
        int socket_error = 0, size = sizeof(socket_error);
        getsockopt(socket, SOL_SOCKET, SO_ERROR, (char *)&socket_error, &size);
        error_code = socket_error ? (DWORD)socket_error : WSAECONNABORTED;
        return 0;
    }
    return 1;
}

static int transfer(SOCKET socket, const char *nonce, int writing) {
    size_t length = strlen(nonce), done = 0;
    char buffer[256];
    ULONGLONG deadline = GetTickCount64() + 5000;
    while (done < length) {
        int count;
        ULONGLONG now = GetTickCount64();
        if (now >= deadline || !await_socket(socket, writing, (DWORD)(deadline - now))) {
            if (now >= deadline) error_code = WSAETIMEDOUT;
            return 0;
        }
        count = writing ? send(socket, nonce + done, (int)(length - done), 0)
                        : recv(socket, buffer + done, (int)(length - done), 0);
        if (count == SOCKET_ERROR) {
            error_code = (DWORD)WSAGetLastError();
            if (error_code == WSAEWOULDBLOCK) continue;
            return 0;
        }
        if (!count) { error_code = WSAECONNRESET; return 0; }
        done += (size_t)count;
    }
    if (!writing && memcmp(buffer, nonce, length)) { error_code = ERROR_INVALID_DATA; return 0; }
    error_code = 0;
    return 1;
}

int wmain(int argc, wchar_t **argv) {
    WSADATA data;
    SOCKADDR_STORAGE address;
    SOCKET socket = INVALID_SOCKET, peer = INVALID_SOCKET;
    int family, address_size, listener, ok = 0, bytes = 0;
    unsigned long entered_port;
    unsigned short port = 0;
    u_long nonblocking = 1;
    char nonce[256];
    wchar_t ready_path[32768];
    identity();
    if (argc != 6) return 2;
    listener = wcscmp(argv[1], L"tcp-listen") == 0;
    if (!listener && wcscmp(argv[1], L"tcp-client") != 0) goto finish;
    entered_port = wcstoul(argv[3], NULL, 10);
    if (entered_port > 65535 || (!listener && !entered_port)) goto finish;
    port = (unsigned short)entered_port;
    if (!WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, argv[4], -1, nonce, sizeof(nonce), NULL, NULL)
        || !nonce[0] || strlen(nonce) > 200) goto finish;
    memset(&address, 0, sizeof(address));
    family = wcschr(argv[2], L':') ? AF_INET6 : AF_INET;
    address.ss_family = (ADDRESS_FAMILY)family;
    address_size = family == AF_INET6 ? sizeof(SOCKADDR_IN6) : sizeof(SOCKADDR_IN);
    if (family == AF_INET6) {
        SOCKADDR_IN6 *v6 = (SOCKADDR_IN6 *)&address;
        v6->sin6_port = htons(port);
        if (InetPtonW(family, argv[2], &v6->sin6_addr) != 1) goto finish;
    } else {
        SOCKADDR_IN *v4 = (SOCKADDR_IN *)&address;
        v4->sin_port = htons(port);
        if (InetPtonW(family, argv[2], &v4->sin_addr) != 1) goto finish;
    }
    stage = "startup";
    error_code = (DWORD)WSAStartup(MAKEWORD(2, 2), &data);
    if (error_code) goto finish;
    stage = "socket";
    socket = WSASocketW(family, SOCK_STREAM, IPPROTO_TCP, NULL, 0, WSA_FLAG_NO_HANDLE_INHERIT);
    if (socket == INVALID_SOCKET) { error_code = (DWORD)WSAGetLastError(); goto cleanup; }
    stage = "nonblocking";
    if (ioctlsocket(socket, FIONBIO, &nonblocking)) { error_code = (DWORD)WSAGetLastError(); goto cleanup; }
    if (listener) {
        int exclusive = 1;
        stage = "exclusive";
        if (setsockopt(socket, SOL_SOCKET, SO_EXCLUSIVEADDRUSE, (char *)&exclusive, sizeof(exclusive))) {
            error_code = (DWORD)WSAGetLastError(); goto cleanup;
        }
        stage = "bind";
        if (bind(socket, (SOCKADDR *)&address, address_size)) { error_code = (DWORD)WSAGetLastError(); goto cleanup; }
        stage = "listen";
        if (listen(socket, 3)) { error_code = (DWORD)WSAGetLastError(); goto cleanup; }
        stage = "getsockname";
        if (getsockname(socket, (SOCKADDR *)&address, &address_size)) { error_code = (DWORD)WSAGetLastError(); goto cleanup; }
        port = ntohs(family == AF_INET6 ? ((SOCKADDR_IN6 *)&address)->sin6_port : ((SOCKADDR_IN *)&address)->sin_port);
        stage = "listening";
        if (swprintf_s(ready_path, _countof(ready_path), L"%ls.ready", argv[5]) < 0 || !record(ready_path, 1, port, 0)) {
            error_code = ERROR_WRITE_FAULT; goto cleanup;
        }
        stage = "accept";
        if (!await_socket(socket, 0, 10000)) goto cleanup;
        peer = accept(socket, NULL, NULL);
        if (peer == INVALID_SOCKET) { error_code = (DWORD)WSAGetLastError(); goto cleanup; }
        stage = "receive-nonce";
        if (!transfer(peer, nonce, 0)) goto cleanup;
        stage = "echo-nonce";
        if (!transfer(peer, nonce, 1)) goto cleanup;
    } else {
        int socket_error = 0, size = sizeof(socket_error);
        stage = "connect";
        if (connect(socket, (SOCKADDR *)&address, address_size)) {
            error_code = (DWORD)WSAGetLastError();
            if (error_code != WSAEWOULDBLOCK) goto cleanup;
            if (!await_socket(socket, 1, 5000)) goto cleanup;
            if (getsockopt(socket, SOL_SOCKET, SO_ERROR, (char *)&socket_error, &size) || socket_error) {
                error_code = socket_error ? (DWORD)socket_error : (DWORD)WSAGetLastError(); goto cleanup;
            }
        }
        stage = "send-nonce";
        if (!transfer(socket, nonce, 1)) goto cleanup;
        stage = "receive-echo";
        if (!transfer(socket, nonce, 0)) goto cleanup;
    }
    ok = 1; bytes = (int)strlen(nonce); error_code = 0; stage = "complete";
cleanup:
    if (peer != INVALID_SOCKET) closesocket(peer);
    if (socket != INVALID_SOCKET) closesocket(socket);
    WSACleanup();
finish:
    if (!record(argv[5], ok, port, bytes)) return 3;
    return ok ? 0 : 1;
}
