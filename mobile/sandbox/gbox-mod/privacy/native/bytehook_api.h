#pragma once

#include <stdbool.h>

// ABI of the original engine's ByteHook 1.0.8 table, returned by Native.getBhookApi.
// Source: https://github.com/bytedance/bhook/blob/v1.0.8/bytehook/src/main/cpp/include/bytehook.h
// This module neither reinitializes ByteHook nor changes its global mode.
using HookStub = void*;
using HookResult = void (*)(HookStub, int, const char*, const char*, void*, void*, void*);
using CallerFilter = bool (*)(const char*, void*);
using BeforeDlopen = void (*)(const char*, void*);
using AfterDlopen = void (*)(const char*, int, void*);

struct BytehookApi {
    const char* (*version)();
    int (*init)(int, bool);
    HookStub (*single)(const char*, const char*, const char*, void*, HookResult, void*);
    HookStub (*partial)(CallerFilter, void*, const char*, const char*, void*, HookResult, void*);
    HookStub (*all)(const char*, const char*, void*, HookResult, void*);
    int (*unhook)(HookStub);
    int (*ignore)(const char*);
    int (*mode)();
    bool (*debug)();
    void (*set_debug)(bool);
    bool (*recordable)();
    void (*set_recordable)(bool);
    char* (*records)(unsigned int);
    void (*dump)(int, unsigned int);
    void* (*previous)(void*);
    void (*pop)(void*);
    void* (*return_address)();
    void (*add_dlopen)(BeforeDlopen, AfterDlopen, void*);
    void (*del_dlopen)(BeforeDlopen, AfterDlopen, void*);
};

static_assert(sizeof(BytehookApi) == 19 * sizeof(void*), "Unexpected ByteHook table size");
