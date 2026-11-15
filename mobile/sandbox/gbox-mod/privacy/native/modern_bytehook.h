#pragma once

// API36 uses a separately packaged upstream implementation. The original
// VLite ByteHook 1.0.8 fails its linker initialization on the inspected phone.
// Never retry, reset, patch or replace that engine's state/table.
bool modern_api;
void* modern_bytehook_handle;
void* modern_shadowhook_handle;

static bool modern_owner(void* symbol, const char* name, uintptr_t* base) {
    Dl_info owner{};
    if (!symbol || !dladdr(symbol, &owner) || !owner.dli_fname) return false;
    const char* slash = strrchr(owner.dli_fname, '/');
    if (strcmp(slash ? slash + 1 : owner.dli_fname, name) != 0) return false;
    uintptr_t found = reinterpret_cast<uintptr_t>(owner.dli_fbase);
    if (!arm_header(found) || (*base && *base != found)) return false;
    *base = found;
    return true;
}

static bool bind_modern_api() {
    char sdk[PROP_VALUE_MAX]{}, bridge[PROP_VALUE_MAX]{};
    __system_property_get("ro.build.version.sdk", sdk);
    __system_property_get("ro.dalvik.vm.native.bridge", bridge);
    if (strcmp(sdk, "36") || (*bridge && strcmp(bridge, "0"))) return false;
    // C-only initialization is an upstream supported interface; JNI_OnLoad
    // registration for upstream Java classes is intentionally not involved.
    // Both handles are process lifetime; unloading active trampolines is unsafe.
    if (!modern_shadowhook_handle)
        modern_shadowhook_handle = dlopen("libshadowhook.so", RTLD_NOW | RTLD_LOCAL);
    if (!modern_shadowhook_handle) { log("modern.shadowhook.load.failed"); return false; }
    auto shadow_version = reinterpret_cast<const char* (*)()>(dlsym(modern_shadowhook_handle, "shadowhook_get_version"));
    auto shadow_init = reinterpret_cast<int (*)(int, bool)>(dlsym(modern_shadowhook_handle, "shadowhook_init"));
    uintptr_t shadow_base = 0;
    if (!modern_owner(reinterpret_cast<void*>(shadow_version), "libshadowhook.so", &shadow_base)
        || !modern_owner(reinterpret_cast<void*>(shadow_init), "libshadowhook.so", &shadow_base)
        || strcmp(shadow_version(), "shadowhook version 2.0.1")) return false;
    int shadow_result = shadow_init(0, false);
    if (shadow_result) { stage("modern.shadowhook.init.failed", shadow_result); return false; }
    if (!modern_bytehook_handle)
        modern_bytehook_handle = dlopen("libbytehook.so", RTLD_NOW | RTLD_LOCAL);
    if (!modern_bytehook_handle) { log("modern.bytehook.load.failed"); return false; }
    BytehookApi candidate{};
    uintptr_t base = 0;
#define MODERN_SYMBOL(field, symbol) \
    candidate.field = reinterpret_cast<decltype(candidate.field)>(dlsym(modern_bytehook_handle, symbol)); \
    if (!modern_owner(reinterpret_cast<void*>(candidate.field), "libbytehook.so", &base)) return false
    MODERN_SYMBOL(version, "bytehook_get_version");
    MODERN_SYMBOL(init, "bytehook_init");
    MODERN_SYMBOL(single, "bytehook_hook_single");
    MODERN_SYMBOL(partial, "bytehook_hook_partial");
    MODERN_SYMBOL(all, "bytehook_hook_all");
    MODERN_SYMBOL(unhook, "bytehook_unhook");
    MODERN_SYMBOL(ignore, "bytehook_add_ignore");
    MODERN_SYMBOL(mode, "bytehook_get_mode");
    MODERN_SYMBOL(debug, "bytehook_get_debug");
    MODERN_SYMBOL(set_debug, "bytehook_set_debug");
    MODERN_SYMBOL(recordable, "bytehook_get_recordable");
    MODERN_SYMBOL(set_recordable, "bytehook_set_recordable");
    MODERN_SYMBOL(records, "bytehook_get_records");
    MODERN_SYMBOL(dump, "bytehook_dump_records");
    MODERN_SYMBOL(previous, "bytehook_get_prev_func");
    MODERN_SYMBOL(pop, "bytehook_pop_stack");
    MODERN_SYMBOL(return_address, "bytehook_get_return_address");
    MODERN_SYMBOL(add_dlopen, "bytehook_add_dlopen_callback");
    MODERN_SYMBOL(del_dlopen, "bytehook_del_dlopen_callback");
#undef MODERN_SYMBOL
    if (strcmp(candidate.version(), "bytehook version 1.1.2")) return false;
    int result = candidate.init(0, false);
    if (result || candidate.mode() != 0) { stage("modern.bytehook.init.failed", result); return false; }
    api = candidate;
    modern_api = true;
    log("modern.bytehook.1_1_2.ready");
    return true;
}
