// Narrow process-local property view. No Build identity or integrity result changes.
#include <jni.h>
#include <dlfcn.h>
#include <string.h>
#include <sys/system_properties.h>
#include "Dobby/dobby.h"

namespace {
unsigned flags;
bool attempted, installed;
using Callback = void (*)(void*, const char*, const char*, uint32_t);
int (*original_get)(const char*, char*);
int (*original_read)(const prop_info*, char*, char*);
void (*original_callback)(const prop_info*, Callback, void*);

const char* replacement(const char* name, unsigned policy) {
    if (!name) return nullptr;
    if ((policy & 2) && !strcmp(name, "persist.sys.timezone")) return "Asia/Tokyo";
    if (!(policy & 1)) return nullptr;
    if (!strcmp(name, "gsm.sim.state")) return "ABSENT";
    if (!strcmp(name, "gsm.operator.isroaming")) return "false";
    if (!strcmp(name, "gsm.current.phone-type")) return "0";
    const char* empty[] = {"gsm.sim.operator.alpha", "gsm.sim.operator.numeric", "gsm.sim.operator.iso-country",
                          "gsm.operator.alpha", "gsm.operator.numeric", "gsm.operator.iso-country"};
    for (const char* key : empty) if (!strcmp(name, key)) return "";
    return nullptr;
}
int get(const char* key, char* value) {
    const char* changed = replacement(key, __atomic_load_n(&flags, __ATOMIC_ACQUIRE));
    if (!changed || !value) return original_get(key, value);
    size_t n = strlen(changed); memcpy(value, changed, n + 1); return static_cast<int>(n);
}
int read(const prop_info* info, char* name, char* value) {
    // Keep the platform's name/buffer behavior, including long-name limitations.
    char local_name[PROP_NAME_MAX]{};
    int result = original_read(info, name ? name : local_name, value);
    if (result < 0 || !value) return result;
    const char* changed = replacement(name ? name : local_name, __atomic_load_n(&flags, __ATOMIC_ACQUIRE));
    if (!changed) return result;
    size_t n = strlen(changed); memcpy(value, changed, n + 1); return static_cast<int>(n);
}
struct State { Callback callback; void* cookie; unsigned policy; };
void callback(void* cookie, const char* name, const char* value, uint32_t serial) {
    auto* state = static_cast<State*>(cookie);
    const char* changed = replacement(name, state->policy);
    state->callback(state->cookie, name, changed ? changed : value, serial);
}
void read_callback(const prop_info* info, Callback cb, void* cookie) {
    unsigned policy = __atomic_load_n(&flags, __ATOMIC_ACQUIRE);
    if (!policy || !cb) { original_callback(info, cb, cookie); return; }
    State state{cb, cookie, policy};
    original_callback(info, callback, &state);
}
}

extern "C" JNIEXPORT jboolean JNICALL
Java_io_github_flysky701_cage_open_OpenPrivacyProperties_nativeSetPolicy(JNIEnv*, jclass, jint policy) {
    __atomic_store_n(&flags, 0u, __ATOMIC_RELEASE);
    if (policy & ~3) return false;
    if (!policy) return true;
    if (!attempted) {
        attempted = true;
        void* a = dlsym(RTLD_DEFAULT, "__system_property_get");
        void* b = dlsym(RTLD_DEFAULT, "__system_property_read");
        void* c = dlsym(RTLD_DEFAULT, "__system_property_read_callback");
        if (!a || !b || !c) return false;
        installed = DobbyHook(a, reinterpret_cast<void*>(get), reinterpret_cast<void**>(&original_get)) == 0
            && DobbyHook(b, reinterpret_cast<void*>(read), reinterpret_cast<void**>(&original_read)) == 0
            && DobbyHook(c, reinterpret_cast<void*>(read_callback), reinterpret_cast<void**>(&original_callback)) == 0;
    }
    if (!installed) return false;
    __atomic_store_n(&flags, static_cast<unsigned>(policy), __ATOMIC_RELEASE);
    return true;
}
