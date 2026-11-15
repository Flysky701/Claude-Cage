#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <wchar.h>

/* Synthetic console only. This executable never launches a shell or connects. */
int wmain(int argc, wchar_t **argv) {
    HANDLE token = NULL;
    DWORD appcontainer = 0, bytes = 0;
    CONSOLE_SCREEN_BUFFER_INFO before = {0}, after = {0};
    wchar_t line[128] = {0};
    DWORD read = 0;
    if (argc != 2 || !OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) return 2;
    BOOL identity = GetTokenInformation(token, TokenIsAppContainer, &appcontainer, sizeof(appcontainer), &bytes);
    CloseHandle(token);
    if (!identity || !appcontainer) return 3;
    if (!GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &before)) return 4;
    printf("CAGE_MXC_TERMINAL_READY pid=%lu initial=%dx%d\n", GetCurrentProcessId(),
        before.srWindow.Right-before.srWindow.Left+1, before.srWindow.Bottom-before.srWindow.Top+1);
    fflush(stdout);
    if (!ReadConsoleW(GetStdHandle(STD_INPUT_HANDLE), line, 127, &read, NULL)) return 5;
    if (!GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &after)) return 6;
    for (DWORD n=0;n<read;n++) if (line[n]==L'\r'||line[n]==L'\n') {line[n]=0;break;}
    FILE *report = _wfopen(argv[1], L"wb");
    if (!report) return 7;
    fprintf(report,"{\"appContainer\":true,\"pid\":%lu,\"received\":\"%ls\",\"initialColumns\":%d,\"initialRows\":%d,\"columns\":%d,\"rows\":%d}\n",
        GetCurrentProcessId(),line,before.srWindow.Right-before.srWindow.Left+1,
        before.srWindow.Bottom-before.srWindow.Top+1,after.srWindow.Right-after.srWindow.Left+1,
        after.srWindow.Bottom-after.srWindow.Top+1);
    fclose(report);
    puts("CAGE_MXC_TERMINAL_READ_AND_RESIZE_COMPLETE");
    fflush(stdout);
    return 0;
}
