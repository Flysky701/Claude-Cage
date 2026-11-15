#include "bytehook_api.h"
#include <android/log.h>
#include <dlfcn.h>
#include <elf.h>
#include <errno.h>
#include <ifaddrs.h>
#include <jni.h>
#include <limits.h>
#include <link.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/system_properties.h>

namespace {
constexpr unsigned SIM = 1, TIMEZONE = 2, VPN = 4;
constexpr size_t MAX_ROOTS = 8, MAX_INTERFACES = 32;
BytehookApi api{};
uintptr_t validated_core;
pthread_mutex_t configuration = PTHREAD_MUTEX_INITIALIZER;
unsigned enabled;
bool installed;
bool installation_failed;
char roots[MAX_ROOTS][PATH_MAX]{};
size_t root_count;
char interfaces[MAX_INTERFACES][64]{};
size_t interface_count;
using GetIfaddrs = int (*)(ifaddrs**);
using FreeIfaddrs = void (*)(ifaddrs*);
using PropertyCallback = void (*)(void*, const char*, const char*, uint32_t);
using ReadPropertyCallback = void (*)(const prop_info*, PropertyCallback, void*);
GetIfaddrs real_getifaddrs;
FreeIfaddrs real_freeifaddrs;
ReadPropertyCallback real_property_callback;
bool release_verified;
unsigned filtered_properties, filtered_interfaces, ownership_refusals;
unsigned hook_success[4]{}, hook_failure[4]{};
unsigned hook_calls[4]{};
unsigned filter_calls;
HookStub stubs[4]{};

void log(const char* message) {
    int saved = errno;
    __android_log_write(ANDROID_LOG_INFO, "CageNativePrivacy", message);
    errno = saved;
}

void stage(const char* label, size_t index) {
    char message[96];
    snprintf(message, sizeof(message), "%s.%zu", label, index);
    log(message);
}

bool readable(uintptr_t address, size_t bytes) {
    if (!address || bytes > UINTPTR_MAX - address) return false;
    FILE* file = fopen("/proc/self/maps", "re");
    if (!file) return false;
    char line[2048], permissions[5];
    unsigned long long begin, end;
    bool found = false;
    while (fgets(line, sizeof(line), file)) {
        if (sscanf(line, "%llx-%llx %4s", &begin, &end, permissions) != 3) continue;
        if (permissions[0] == 'r' && address >= begin && address + bytes <= end) {
            found = true;
            break;
        }
    }
    fclose(file);
    return found;
}

bool arm_header(uintptr_t base) {
    if (!readable(base, sizeof(Elf64_Ehdr))) return false;
    Elf64_Ehdr header;
    memcpy(&header, reinterpret_cast<void*>(base), sizeof(header));
    return memcmp(header.e_ident, ELFMAG, SELFMAG) == 0 && header.e_ident[EI_CLASS] == ELFCLASS64
        && header.e_ident[EI_DATA] == ELFDATA2LSB && header.e_machine == EM_AARCH64;
}

#include "ifaddrs_guard.h"

bool root_matches_locked(const char* path) {
    if (!path) return false;
    for (size_t i = 0; i < root_count; ++i) {
        size_t length = strlen(roots[i]);
        if (strncmp(path, roots[i], length) == 0 && (path[length] == '/' || path[length] == '!')) return true;
    }
    return false;
}

bool path_matches(const char* path) {
    pthread_mutex_lock(&configuration);
    bool result = root_matches_locked(path);
    pthread_mutex_unlock(&configuration);
    return result;
}

#include "diagnostics.h"

struct ImageQuery { const char* path; bool arm; };
int inspect_image(dl_phdr_info* info, size_t, void* opaque) {
    auto* query = static_cast<ImageQuery*>(opaque);
    if (info->dlpi_name && strcmp(info->dlpi_name, query->path) == 0) {
        query->arm = arm_header(info->dlpi_addr);
        return 1;
    }
    return 0;
}

bool caller_filter(const char* path, void*) {
    // The engine, libc, linker, our own library and host x86 images are never targets.
    bool first = __atomic_fetch_add(&filter_calls, 1u, __ATOMIC_RELAXED) == 0;
    if (first) log("filter.first.before.scope");
    bool selected = path_matches(path);
    if (first) log("filter.first.after.scope");
    if (!selected) { diagnostic_filter(path, 0); return false; }
    const char* slash = strrchr(path, '/');
    const char* name = slash ? slash + 1 : path;
    const char* excluded[] = {"libcage_privacy.so", "libcage_compat.so", "libc.so", "libdl.so",
        "liblog.so", "libnb.so", "libtcb.so", "libhoudini.so", "linker", "linker64"};
    for (const char* item : excluded)
        if (strcmp(name, item) == 0) { diagnostic_filter(path, 1); return false; }
    if (strncmp(name, "libvlite", 8) == 0 || strncmp(name, "libloader", 9) == 0) {
        diagnostic_filter(path, 1); return false;
    }
    ImageQuery query{path, false};
    log("filter.selected.before.iteratePhdr");
    dl_iterate_phdr(inspect_image, &query);
    log("filter.selected.after.iteratePhdr");
    diagnostic_filter(path, query.arm ? 3 : 2);
    return query.arm;
}

unsigned call_policy() {
    unsigned flags = __atomic_load_n(&enabled, __ATOMIC_ACQUIRE);
    if (!flags) return 0;
    Dl_info caller{};
    if (!dladdr(api.return_address(), &caller) || !path_matches(caller.dli_fname)) return 0;
    return flags;
}

struct HookFrame {
    void* return_address;
    explicit HookFrame(void* address) : return_address(address) {}
    ~HookFrame() {
        int saved = errno;
        api.pop(return_address);
        errno = saved;
    }
};

const char* property_value(const char* key, unsigned flags) {
    if (!key) return nullptr;
    if ((flags & TIMEZONE) && strcmp(key, "persist.sys.timezone") == 0) return "Asia/Tokyo";
    if (!(flags & SIM)) return nullptr;
    if (strcmp(key, "gsm.sim.state") == 0) return "ABSENT";
    if (strcmp(key, "gsm.operator.isroaming") == 0) return "false";
    if (strcmp(key, "gsm.current.phone-type") == 0) return "0";
    const char* empty_keys[] = {"gsm.sim.operator.alpha", "gsm.sim.operator.numeric",
        "gsm.sim.operator.iso-country", "gsm.operator.alpha", "gsm.operator.numeric",
        "gsm.operator.iso-country"};
    for (const char* candidate : empty_keys) if (strcmp(key, candidate) == 0) return "";
    return nullptr;
}

void note_call(size_t index, unsigned flags) {
    if (!flags || __atomic_fetch_add(&hook_calls[index], 1u, __ATOMIC_RELAXED) != 0) return;
    char message[64];
    snprintf(message, sizeof(message), "hook.%zu.selected.first.call", index);
    log(message);
}

int property_get(const char* key, char* value) {
    int saved = errno;
    HookFrame frame(__builtin_return_address(0));
    using Function = int (*)(const char*, char*);
    auto previous = reinterpret_cast<Function>(api.previous(reinterpret_cast<void*>(property_get)));
    unsigned flags = call_policy();
    note_call(0, flags);
    const char* replacement = property_value(key, flags);
    errno = saved;
    if (!replacement || !value) return previous(key, value);
    size_t length = strlen(replacement);
    memcpy(value, replacement, length + 1);
    if (__atomic_fetch_add(&filtered_properties, 1u, __ATOMIC_RELAXED) == 0) log("property.filtered.first");
    return static_cast<int>(length);
}

struct PropertyLookup { unsigned flags; const char* replacement; };
void lookup_property(void* opaque, const char* name, const char*, uint32_t) {
    auto* lookup = static_cast<PropertyLookup*>(opaque);
    lookup->replacement = property_value(name, lookup->flags);
}

int property_read(const prop_info* info, char* name, char* value) {
    int saved = errno;
    HookFrame frame(__builtin_return_address(0));
    using Function = int (*)(const prop_info*, char*, char*);
    auto previous = reinterpret_cast<Function>(api.previous(reinterpret_cast<void*>(property_read)));
    unsigned flags = call_policy();
    note_call(1, flags);
    errno = saved;
    int result = previous(info, name, value);
    saved = errno;
    PropertyLookup lookup{flags, nullptr};
    // Preserve the caller's original legacy name buffer, including its nullness
    // and Bionic's truncation behavior. The modern read supplies the complete key.
    if (result >= 0 && flags && value && real_property_callback)
        real_property_callback(info, lookup_property, &lookup);
    const char* replacement = lookup.replacement;
    if (replacement) {
        size_t length = strlen(replacement);
        memcpy(value, replacement, length + 1);
        result = static_cast<int>(length);
        if (__atomic_fetch_add(&filtered_properties, 1u, __ATOMIC_RELAXED) == 0) log("property.filtered.first");
    }
    errno = saved;
    return result;
}

struct PropertyRead { PropertyCallback callback; void* cookie; unsigned flags; };
void property_callback(void* opaque, const char* name, const char* value, uint32_t serial) {
    auto* read = static_cast<PropertyRead*>(opaque);
    const char* replacement = property_value(name, read->flags);
    if (replacement) {
        value = replacement;
        if (__atomic_fetch_add(&filtered_properties, 1u, __ATOMIC_RELAXED) == 0) log("property.filtered.first");
    }
    read->callback(read->cookie, name, value, serial);
}

void property_read_callback(const prop_info* info, PropertyCallback callback, void* cookie) {
    int saved = errno;
    HookFrame frame(__builtin_return_address(0));
    using Function = void (*)(const prop_info*, PropertyCallback, void*);
    auto previous = reinterpret_cast<Function>(api.previous(reinterpret_cast<void*>(property_read_callback)));
    unsigned flags = call_policy();
    note_call(2, flags);
    errno = saved;
    if (!flags || !callback) { previous(info, callback, cookie); return; }
    // Bionic's read callback is synchronous; this stack context cannot outlive the call.
    PropertyRead read{callback, cookie, flags};
    previous(info, property_callback, &read);
}

bool tunnel_name(const char* name) {
    if (!name) return false;
    pthread_mutex_lock(&configuration);
    bool found = false;
    for (size_t i = 0; i < interface_count; ++i)
        if (strcmp(interfaces[i], name) == 0) { found = true; break; }
    pthread_mutex_unlock(&configuration);
    if (found) return true;
    const char* prefixes[] = {"tun", "tap", "ppp", "wg", "ipsec"};
    for (const char* prefix : prefixes) {
        size_t length = strlen(prefix);
        if (strncmp(name, prefix, length) != 0 || name[length] == '\0') continue;
        const char* digit = name + length;
        while (*digit >= '0' && *digit <= '9') ++digit;
        if (*digit == '\0') return true;
    }
    return false;
}

int network_interfaces(ifaddrs** output) {
    int saved = errno;
    HookFrame frame(__builtin_return_address(0));
    auto previous = reinterpret_cast<GetIfaddrs>(api.previous(reinterpret_cast<void*>(network_interfaces)));
    unsigned flags = call_policy();
    note_call(3, flags);
    errno = saved;
    int result = previous(output);
    saved = errno;
    if (result == 0 && output && *output && (flags & VPN)) {
        if (!release_verified || previous != real_getifaddrs) {
            if (__atomic_fetch_add(&ownership_refusals, 1u, __ATOMIC_RELAXED) == 0)
                log("getifaddrs.not.filtered.ownership.unverified");
        } else {
            // Only enabled for an inspected implementation where each list node
            // is a complete allocation freed via next traversal. Surviving nodes
            // remain untouched original allocations and need no free hook.
            ifaddrs** link = output;
            while (*link) {
                ifaddrs* item = *link;
                if (tunnel_name(item->ifa_name)) {
                    *link = item->ifa_next;
                    item->ifa_next = nullptr;
                    real_freeifaddrs(item);
                    if (__atomic_fetch_add(&filtered_interfaces, 1u, __ATOMIC_RELAXED) == 0) log("getifaddrs.filtered.first");
                } else link = &item->ifa_next;
            }
        }
    }
    errno = saved;
    return result;
}

void hook_result(HookStub, int status, const char*, const char*, void*, void*, void* opaque) {
    size_t index = reinterpret_cast<uintptr_t>(opaque);
    if (index >= 4) return;
    if (status == 0) __atomic_fetch_add(&hook_success[index], 1u, __ATOMIC_RELAXED);
    else if (status != 13) __atomic_fetch_add(&hook_failure[index], 1u, __ATOMIC_RELAXED);
    if (status != 13) {
        char message[96];
        snprintf(message, sizeof(message), "hook.%zu.status=%d", index, status);
        log(message);
    }
}

bool validate_api(uintptr_t table) {
    log("api.before.tableRead");
    if (!readable(table, sizeof(api))) { log("api.reject.tableUnreadable"); return false; }
    BytehookApi candidate;
    memcpy(&candidate, reinterpret_cast<void*>(table), sizeof(candidate));
    log("api.after.tableRead");
    void* functions[] = {reinterpret_cast<void*>(candidate.version), reinterpret_cast<void*>(candidate.partial),
        reinterpret_cast<void*>(candidate.unhook),
        reinterpret_cast<void*>(candidate.mode), reinterpret_cast<void*>(candidate.previous),
        reinterpret_cast<void*>(candidate.pop), reinterpret_cast<void*>(candidate.return_address)};
    void* base = nullptr;
    size_t index = 0;
    for (void* function : functions) {
        stage("api.before.functionImage", index);
        Dl_info owner{};
        if (!function || !dladdr(function, &owner) || !arm_header(reinterpret_cast<uintptr_t>(owner.dli_fbase))) {
            stage("api.reject.functionImage", index);
            return false;
        }
        if (!base) base = owner.dli_fbase;
        else if (base != owner.dli_fbase) { stage("api.reject.functionOwner", index); return false; }
        stage("api.after.functionImage", index++);
    }
    // Exact API table of the inspected original ARM64 GBox 1.8.4.02 core.
    // Coexist relocation changes data constants, not these functions or the table ABI.
    const uintptr_t expected_offsets[] = {
        0x38dc8, 0x38dd4, 0x38ddc, 0x38de4, 0x38dec, 0x38df4, 0x38dfc,
        0x38ea0, 0x38e00, 0x38e04, 0x38e0c, 0x38e10, 0x38e18, 0x38e1c,
        0x38e20, 0x38e70, 0x38e50, 0x38ea4, 0x38ea8
    };
    uintptr_t entries[19];
    static_assert(sizeof(entries) == sizeof(candidate), "ByteHook pointer table mismatch");
    memcpy(entries, &candidate, sizeof(entries));
    uintptr_t core = reinterpret_cast<uintptr_t>(base);
    if (table != core + 0xe2290) { log("api.reject.tableAddress"); return false; }
    for (size_t slot = 0; slot < 19; ++slot) {
        if (entries[slot] != core + expected_offsets[slot]) {
            stage("api.reject.tableSlot", slot);
            return false;
        }
    }
    log("api.tableAbi.exact19Slots");
    log("api.before.version");
    const char* version = candidate.version();
    log("api.after.version");
    // The original export returns this full string; its constructor at +0x38eac
    // decodes exactly 23 bytes at +0xdcf10 with XOR 0xe4, including the NUL.
    constexpr char expected_version[] = "bytehook version 1.0.8";
    if (reinterpret_cast<uintptr_t>(version) != core + 0xdcf10
        || !readable(reinterpret_cast<uintptr_t>(version), sizeof(expected_version))) {
        log("api.reject.versionPointer");
        return false;
    }
    if (memcmp(version, expected_version, sizeof(expected_version)) != 0) {
        log("api.reject.versionBytes");
        return false;
    }
    log("api.version.exactOriginal");
    log("api.before.mode");
    bool mode_ok = candidate.mode() == 0;
    log("api.after.mode");
    if (!mode_ok) { log("api.reject.modeNotAutomatic"); return false; }
    api = candidate;
    validated_core = core;
    return true;
}

#include "load_refresh.h"

bool read_strings(JNIEnv* env, jobjectArray values, char* output, size_t stride, size_t capacity, size_t* count) {
    *count = 0;
    if (!values) return true;
    jsize size = env->GetArrayLength(values);
    if (size < 0 || static_cast<size_t>(size) > capacity) return false;
    for (jsize i = 0; i < size; ++i) {
        auto value = static_cast<jstring>(env->GetObjectArrayElement(values, i));
        if (!value) return false;
        const char* bytes = env->GetStringUTFChars(value, nullptr);
        if (!bytes) { env->DeleteLocalRef(value); return false; }
        size_t length = strlen(bytes);
        bool ok = length > 0 && length < stride;
        if (ok) memcpy(output + static_cast<size_t>(i) * stride, bytes, length + 1);
        env->ReleaseStringUTFChars(value, bytes);
        env->DeleteLocalRef(value);
        if (!ok) return false;
        ++*count;
    }
    return !env->ExceptionCheck();
}
}  // namespace

extern "C" JNIEXPORT jint JNICALL
Java_io_github_leexeo_cage_privacy_NativePrivacy_nativeBind(JNIEnv* env, jclass, jlong table,
        jobjectArray java_roots, jobjectArray java_interfaces, jint flags, jboolean synchronize_loads) {
    log("nativeBind.enter");
    __atomic_store_n(&enabled, 0u, __ATOMIC_RELEASE);
    if (installation_failed) return -4;
    char new_roots[MAX_ROOTS][PATH_MAX]{}, new_interfaces[MAX_INTERFACES][64]{};
    size_t new_root_count = 0, new_interface_count = 0;
    log("nativeBind.before.readArguments");
    if ((flags & ~7) || !read_strings(env, java_roots, &new_roots[0][0], PATH_MAX, MAX_ROOTS, &new_root_count)
        || !new_root_count || !read_strings(env, java_interfaces, &new_interfaces[0][0], 64, MAX_INTERFACES, &new_interface_count)) return -1;
    log("nativeBind.after.readArguments");
    for (size_t i = 0; i < new_root_count; ++i)
        if (strncmp(new_roots[i], "/data/", 6) != 0 || strstr(new_roots[i], "/../") || strcmp(new_roots[i], "/data") == 0) return -2;
    log("nativeBind.before.configurationLock");
    pthread_mutex_lock(&configuration);
    memcpy(roots, new_roots, sizeof(roots));
    root_count = new_root_count;
    memcpy(interfaces, new_interfaces, sizeof(interfaces));
    interface_count = new_interface_count;
    pthread_mutex_unlock(&configuration);
    log("nativeBind.after.configurationUnlock");
    if (!installed) {
        log("nativeBind.before.validateApi");
        if (!validate_api(static_cast<uintptr_t>(table))) { log("bind.bytehook.api.rejected"); return -3; }
        log("nativeBind.after.validateApi");
        log("nativeBind.before.resolveSymbols");
        real_getifaddrs = reinterpret_cast<GetIfaddrs>(dlsym(RTLD_DEFAULT, "getifaddrs"));
        real_freeifaddrs = reinterpret_cast<FreeIfaddrs>(dlsym(RTLD_DEFAULT, "freeifaddrs"));
        real_property_callback = reinterpret_cast<ReadPropertyCallback>(dlsym(RTLD_DEFAULT, "__system_property_read_callback"));
        if (!real_property_callback) { log("bind.property.callback.unavailable"); return -5; }
        log("nativeBind.after.resolveSymbols");
        log("nativeBind.before.ownershipGuard");
        release_verified = cage_ifaddrs_release_verified(reinterpret_cast<void*>(real_getifaddrs), reinterpret_cast<void*>(real_freeifaddrs));
        log("nativeBind.after.ownershipGuard");
        capture_observation(&binding_observation, -1); // before registering any privacy task
        const char* names[] = {"__system_property_get", "__system_property_read", "__system_property_read_callback", "getifaddrs"};
        void* functions[] = {reinterpret_cast<void*>(property_get), reinterpret_cast<void*>(property_read),
            reinterpret_cast<void*>(property_read_callback), reinterpret_cast<void*>(network_interfaces)};
        for (size_t i = 0; i < 4; ++i) {
            stage("nativeBind.before.partial", i);
            stubs[i] = api.partial(caller_filter, nullptr, nullptr, names[i], functions[i], hook_result, reinterpret_cast<void*>(i));
            stage("nativeBind.after.partial", i);
            if (!stubs[i]) {
                installation_failed = true;
                for (size_t previous = 0; previous < i; ++previous) api.unhook(stubs[previous]);
                log("bind.hook.request.failed");
                return -4;
            }
        }
        installed = true;
    }
    if (!load_observer_requested) {
        api.add_dlopen(nullptr, diagnostic_after_dlopen, nullptr);
        load_observer_requested = true;
        log("observation.dlopen.callback.requested");
    }
    if (synchronize_loads) {
        if (!prepare_load_refresh(env, validated_core)) return -7;
    }
    __atomic_store_n(&enabled, static_cast<unsigned>(flags), __ATOMIC_RELEASE);
    log(release_verified ? "bound.arm.plt.ownership.verified" : "bound.arm.plt.ownership.pending");
    return release_verified ? 2 : 1;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_leexeo_cage_privacy_NativePrivacy_afterNativeLoad(JNIEnv* env, jclass, jstring filename) {
    log("host.arm.callback.enter");
    if (!refresh_prepared || !__atomic_load_n(&enabled, __ATOMIC_ACQUIRE)) {
        log("host.arm.callback.skipped.inactive"); return;
    }
    after_java_load(env, filename);
    log(env->ExceptionCheck() ? "host.arm.callback.exit.exception" : "host.arm.callback.exit");
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_leexeo_cage_privacy_NativePrivacy_nativeDeactivate(JNIEnv*, jclass) {
    // Leave trampolines installed for in-flight calls; every subsequent call passes through.
    __atomic_store_n(&enabled, 0u, __ATOMIC_RELEASE);
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_leexeo_cage_privacy_NativePrivacy_nativeObserveInterface(JNIEnv* env, jclass, jstring value) {
    if (!value || !__atomic_load_n(&enabled, __ATOMIC_ACQUIRE)) return;
    const char* name = env->GetStringUTFChars(value, nullptr);
    if (!name) return;
    size_t length = strlen(name);
    if (length > 0 && length < sizeof(interfaces[0])) {
        pthread_mutex_lock(&configuration);
        bool exists = false;
        for (size_t i = 0; i < interface_count; ++i) if (strcmp(interfaces[i], name) == 0) exists = true;
        if (!exists && interface_count < MAX_INTERFACES) memcpy(interfaces[interface_count++], name, length + 1);
        pthread_mutex_unlock(&configuration);
    }
    env->ReleaseStringUTFChars(value, name);
}

extern "C" JNIEXPORT jstring JNICALL
Java_io_github_leexeo_cage_privacy_NativePrivacy_nativeDiagnostics(JNIEnv* env, jclass) {
    char status[512];
    snprintf(status, sizeof(status), "active=%u installed=%d ownership=%d hooks=%u,%u,%u,%u calls=%u,%u,%u,%u failures=%u,%u,%u,%u properties=%u interfaces=%u ownershipRefusals=%u",
        __atomic_load_n(&enabled, __ATOMIC_ACQUIRE), installed, release_verified,
        __atomic_load_n(&hook_success[0], __ATOMIC_RELAXED), __atomic_load_n(&hook_success[1], __ATOMIC_RELAXED),
        __atomic_load_n(&hook_success[2], __ATOMIC_RELAXED), __atomic_load_n(&hook_success[3], __ATOMIC_RELAXED),
        __atomic_load_n(&hook_calls[0], __ATOMIC_RELAXED), __atomic_load_n(&hook_calls[1], __ATOMIC_RELAXED),
        __atomic_load_n(&hook_calls[2], __ATOMIC_RELAXED), __atomic_load_n(&hook_calls[3], __ATOMIC_RELAXED),
        __atomic_load_n(&hook_failure[0], __ATOMIC_RELAXED), __atomic_load_n(&hook_failure[1], __ATOMIC_RELAXED),
        __atomic_load_n(&hook_failure[2], __ATOMIC_RELAXED), __atomic_load_n(&hook_failure[3], __ATOMIC_RELAXED),
        __atomic_load_n(&filtered_properties, __ATOMIC_RELAXED), __atomic_load_n(&filtered_interfaces, __ATOMIC_RELAXED),
        __atomic_load_n(&ownership_refusals, __ATOMIC_RELAXED));
    return env->NewStringUTF(status);
}

extern "C" JNIEXPORT jstring JNICALL
Java_io_github_leexeo_cage_privacy_NativePrivacy_nativeCapture(JNIEnv* env, jclass, jint sequence) {
    if (!__atomic_load_n(&enabled, __ATOMIC_ACQUIRE)) return env->NewStringUTF("inactive\n");
    if (sequence == -1) return env->NewStringUTF(binding_observation.bytes);
    ObservationText observation;
    capture_observation(&observation, sequence);
    return env->NewStringUTF(observation.bytes);
}
