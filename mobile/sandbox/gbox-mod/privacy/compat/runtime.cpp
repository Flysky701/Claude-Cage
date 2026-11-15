// MuMu Android 12 / ARM64 compatibility for the original VLite JNI installer.
// This preserves VLite's callbacks and changes only how they retain and install
// native methods. Offsets/ABI/profile are guarded by the separate loader gate.
#include <jni.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <android/log.h>
#include <dlfcn.h>

#ifndef CAGE_CRITICAL_NATIVE_VALIDATED
// Probe05 validates Java -> ARM CriticalNative -> raw host primitive entry.
// Probe04's nested ARM JNI CallStaticIntMethod path remains a known failure.
// This module is a guarded diagnostic candidate, not general ABI compatibility.
#define CAGE_CRITICAL_NATIVE_VALIDATED 1
#endif

namespace {
constexpr unsigned NATIVE = 0x100, STATIC = 8, CRITICAL = 0x00100000;
constexpr size_t ART_SIZE = 32, JNI_SLOT = 16, QUICK_SLOT = 24;
struct Region { uintptr_t start, end; uint64_t offset; char permissions[5], path[512]; };
struct Hook {
    const char *id, *class_name, *name, *signature, *arguments;
    bool is_static, attempted_by_core, critical, expected_native;
    uintptr_t callback_rva, slot_rva;
    void* adapter;
    jclass clazz = nullptr;
    jmethodID method = nullptr;
    jobject backup = nullptr;
    void* copy = nullptr;
    uintptr_t art = 0, original_native = 0, original_quick = 0;
    uintptr_t installed_entry = 0;
    uint32_t class_ref = 0, dex_index = 0;
    bool is_native = false, installed = false;
    unsigned index = 0;
};
struct Auxiliary { const char* name; jmethodID method; uintptr_t original; unsigned bit; uintptr_t slot_rva; };
static Auxiliary auxiliary[] = {{"getCallingPid", 0, 0, 1, 0xe2848}, {"getCallingWorkSourceUid", 0, 0, 2, 0xe2850}};
static uintptr_t core_base;
static JavaVM* java_vm;
static bool prepared, failed;
static unsigned auxiliary_reads;
static pthread_key_t recursion_key;
static jclass object_class, method_class, integer_class, long_class, boolean_class;
static jclass invocation_exception, illegal_state;
static jmethodID invoke_method, set_accessible, get_loader, get_modifiers, get_cause;
static jmethodID integer_box, long_box, boolean_box, integer_value, long_value, boolean_value;
static jfieldID art_field;

static void note(const char* status, const char* id) {
    __android_log_print(ANDROID_LOG_INFO, "CageNativeCompat", "%s %s", status, id ? id : "");
}
static bool fail(const char* reason, const char* id = 0) {
    __atomic_store_n(&failed, true, __ATOMIC_RELEASE);
    __android_log_print(ANDROID_LOG_ERROR, "CageNativeCompat", "FAIL %s %s", reason, id ? id : "");
    return false;
}
static bool pending(JNIEnv* env, const char* reason, const char* id = 0) {
    if (!env->ExceptionCheck()) return false;
    env->ExceptionClear();
    fail(reason, id);
    return true;
}
static bool region_for(uintptr_t address, size_t length, Region* out) {
    if (!length || address > UINTPTR_MAX - length) return false;
    FILE* file = fopen("/proc/self/maps", "r");
    if (!file) return false;
    char line[1024]; bool found = false;
    while (fgets(line, sizeof(line), file)) {
        unsigned long start = 0, end = 0, offset = 0;
        char permissions[5] = {}; int position = 0;
        if (sscanf(line, "%lx-%lx %4s %lx %*s %*s %n", &start, &end, permissions, &offset, &position) < 4) continue;
        if (address < start || address + length > end) continue;
        char* path = line + position;
        while (*path == ' ') ++path;
        path[strcspn(path, "\r\n")] = 0;
        out->start = start; out->end = end; out->offset = offset;
        memcpy(out->permissions, permissions, sizeof(permissions));
        snprintf(out->path, sizeof(out->path), "%s", path);
        found = true; break;
    }
    fclose(file); return found;
}
static bool read_mapped(uintptr_t address, void* out, size_t length) {
    Region region;
    if (!region_for(address, length, &region) || !strchr(region.permissions, 'r')) return false;
    memcpy(out, (void*)address, length); return true;
}
static uint64_t le(const unsigned char* bytes, size_t length) {
    uint64_t result = 0;
    for (size_t i = 0; i < length; ++i) result |= (uint64_t)bytes[i] << (i * 8);
    return result;
}
static bool host_elf(uintptr_t base, uintptr_t entry, const Region& map) {
    unsigned char header[64], ph[128 * 56];
    if (!read_mapped(base, header, sizeof(header)) || memcmp(header, "\x7f" "ELF", 4) || header[4] != 2 || header[5] != 1 || le(header + 18, 2) != 62) return false;
    uint64_t offset = le(header + 32, 8);
    unsigned size = le(header + 54, 2), count = le(header + 56, 2);
    if (size != 56 || !count || count > 128 || offset > 1024 * 1024 || offset > UINTPTR_MAX - base || !read_mapped(base + offset, ph, size * count)) return false;
    uintptr_t bias = 0; bool have_bias = false;
    for (unsigned i = 0; i < count; ++i) {
        const unsigned char* p = ph + i * size;
        if (le(p, 4) == 1 && le(p + 8, 8) == 0 && le(p + 32, 8) >= 64 && base >= le(p + 16, 8)) {
            bias = base - le(p + 16, 8); have_bias = true; break;
        }
    }
    if (!have_bias) return false;
    for (unsigned i = 0; i < count; ++i) {
        const unsigned char* p = ph + i * size;
        uint64_t address = le(p + 16, 8), bytes = le(p + 32, 8);
        if (le(p, 4) != 1 || !(le(p + 4, 4) & 1) || address > UINTPTR_MAX - bias) continue;
        uintptr_t start = bias + address;
        if (entry >= start && entry - start < bytes && le(p + 8, 8) + entry - start == map.offset + entry - map.start) return true;
    }
    return false;
}
static bool host_entry(uintptr_t entry) {
    Region map;
    if (!region_for(entry, 16, &map) || !strchr(map.permissions, 'r') || !strchr(map.permissions, 'x')) return false;
    // Android's PT_LOAD virtual address can differ from its file offset. The
    // dladdr base is also only a candidate: prove it against the actual mapping.
    Dl_info info = {};
    uintptr_t base = 0;
    if (dladdr((void*)entry, &info) && info.dli_fbase) {
        base = (uintptr_t)info.dli_fbase;
        if (host_elf(base, entry, map)) return true;
    }
    return map.start >= map.offset && map.start - map.offset != base && host_elf(map.start - map.offset, entry, map);
}

static bool auxiliary_slots_writable() {
    // The separate gate checks the exact original Binder callback/installer.
    // Prove that their two data slots belong to this core's RW PT_LOAD as well
    // as a currently writable private mapping; no mprotect or code edit occurs.
    unsigned char header[64], ph[128 * 56];
    if (!read_mapped(core_base, header, sizeof(header)) || memcmp(header, "\x7f" "ELF", 4)
            || header[4] != 2 || header[5] != 1 || le(header + 18, 2) != 183) return false;
    uint64_t offset = le(header + 32, 8);
    unsigned size = le(header + 54, 2), count = le(header + 56, 2);
    if (size != 56 || !count || count > 128 || offset > 1024 * 1024
            || offset > UINTPTR_MAX - core_base || !read_mapped(core_base + offset, ph, size * count)) return false;
    bool same_data_segment = false;
    for (unsigned index = 0; index < count; ++index) {
        const unsigned char* segment = ph + index * size;
        uint64_t start = le(segment + 16, 8), bytes = le(segment + 40, 8);
        if (le(segment, 4) == 1 && (le(segment + 4, 4) & 6) == 6
                && start <= 0xe2848 && bytes >= 16 && 0xe2848 - start <= bytes - 16)
            same_data_segment = true;
    }
    if (!same_data_segment) return false;
    for (const Auxiliary& item : auxiliary) {
        if (core_base > UINTPTR_MAX - item.slot_rva) return false;
        uintptr_t address = core_base + item.slot_rva;
        Region region;
        if ((address & (sizeof(uintptr_t) - 1)) || !region_for(address, sizeof(uintptr_t), &region)
                || region.permissions[0] != 'r' || region.permissions[1] != 'w' || region.permissions[3] != 'p')
            return false;
    }
    return true;
}

static bool publish_binder_auxiliary() {
    if (!auxiliary_slots_writable()) return fail("Binder auxiliary slot mapping");
    // Both originals have already passed validate_critical_original during
    // prepare. Check all slots before publishing either; the original installer
    // subsequently reads and stores these same pointers in its existing order.
    for (const Auxiliary& item : auxiliary) {
        if (!item.method || !item.original || !host_entry(item.original))
            return fail("Binder auxiliary prepared original unavailable", item.name);
        uintptr_t current = __atomic_load_n(reinterpret_cast<uintptr_t*>(core_base + item.slot_rva), __ATOMIC_ACQUIRE);
        if (current && current != item.original) return fail("Binder auxiliary slot changed before publication", item.name);
    }
    for (const Auxiliary& item : auxiliary)
        __atomic_store_n(reinterpret_cast<uintptr_t*>(core_base + item.slot_rva), item.original, __ATOMIC_RELEASE);
    // Make both dependencies visible before RegisterNatives exposes the UID
    // callback to Binder threads. The callback continues to use original LDRs.
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
    for (const Auxiliary& item : auxiliary) {
        if (__atomic_load_n(reinterpret_cast<uintptr_t*>(core_base + item.slot_rva), __ATOMIC_ACQUIRE) != item.original)
            return fail("Binder auxiliary publication readback", item.name);
        note("BINDER_AUXILIARY_SLOT_READY", item.name);
    }
    return true;
}
static jclass root_class(JNIEnv* env, const char* name) {
    if (env->ExceptionCheck()) return 0;
    jclass local = env->FindClass(name);
    if (!local || env->ExceptionCheck()) return 0;
    jclass global = (jclass)env->NewGlobalRef(local);
    env->DeleteLocalRef(local); return global;
}
static bool cache_java(JNIEnv* env) {
    object_class = root_class(env, "java/lang/Object");
    method_class = root_class(env, "java/lang/reflect/Method");
    integer_class = root_class(env, "java/lang/Integer");
    long_class = root_class(env, "java/lang/Long");
    boolean_class = root_class(env, "java/lang/Boolean");
    invocation_exception = root_class(env, "java/lang/reflect/InvocationTargetException");
    illegal_state = root_class(env, "java/lang/IllegalStateException");
    if (pending(env, "java classes") || !object_class || !method_class || !integer_class || !long_class || !boolean_class || !invocation_exception || !illegal_state) return fail("java classes unavailable");
    jclass executable = env->FindClass("java/lang/reflect/Executable");
    if (pending(env, "Executable class") || !executable) return false;
    jclass class_class = env->FindClass("java/lang/Class");
    if (pending(env, "metadata classes") || !executable || !class_class) return false;
#define CACHE_JNI(target, expression) do { \
    target = (expression); \
    if (pending(env, "java cache", #target) || !target) return fail("java cache unavailable", #target); \
} while (0)
    CACHE_JNI(art_field, env->GetFieldID(executable, "artMethod", "J"));
    CACHE_JNI(invoke_method, env->GetMethodID(method_class, "invoke", "(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;"));
    CACHE_JNI(set_accessible, env->GetMethodID(method_class, "setAccessible", "(Z)V"));
    CACHE_JNI(get_modifiers, env->GetMethodID(method_class, "getModifiers", "()I"));
    CACHE_JNI(get_loader, env->GetMethodID(class_class, "getClassLoader", "()Ljava/lang/ClassLoader;"));
    CACHE_JNI(get_cause, env->GetMethodID(invocation_exception, "getCause", "()Ljava/lang/Throwable;"));
    CACHE_JNI(integer_box, env->GetStaticMethodID(integer_class, "valueOf", "(I)Ljava/lang/Integer;"));
    CACHE_JNI(long_box, env->GetStaticMethodID(long_class, "valueOf", "(J)Ljava/lang/Long;"));
    CACHE_JNI(boolean_box, env->GetStaticMethodID(boolean_class, "valueOf", "(Z)Ljava/lang/Boolean;"));
    CACHE_JNI(integer_value, env->GetMethodID(integer_class, "intValue", "()I"));
    CACHE_JNI(long_value, env->GetMethodID(long_class, "longValue", "()J"));
    CACHE_JNI(boolean_value, env->GetMethodID(boolean_class, "booleanValue", "()Z"));
#undef CACHE_JNI
    env->DeleteLocalRef(executable); env->DeleteLocalRef(class_class);
    return true;
}
static bool metadata(JNIEnv* env, jclass clazz, jmethodID method, bool is_static,
                     uintptr_t* art, unsigned char* snapshot, jobject* reflected) {
    *reflected = env->ToReflectedMethod(clazz, method, is_static ? JNI_TRUE : JNI_FALSE);
    if (pending(env, "ToReflectedMethod") || !*reflected) return false;
    *art = (uintptr_t)env->GetLongField(*reflected, art_field);
    if (pending(env, "artMethod pointer") || !*art || !read_mapped(*art, snapshot, ART_SIZE)) return fail("metadata unreadable");
    uint32_t flags; memcpy(&flags, snapshot + 4, 4);
    if (!(flags & NATIVE) || !!(flags & STATIC) != is_static) return fail("metadata native/static mismatch");
    return true;
}
static bool validate_critical_original(JNIEnv* env, jclass clazz, jmethodID method, uintptr_t original, const char* id) {
    // All three Binder originals are still unmodified here. Never use this JNI
    // check on the replaced method: that nested path is the Probe04 limitation.
    jint baseline = env->CallStaticIntMethod(clazz, method);
    if (pending(env, "CriticalNative baseline", id)) return false;
    const JNINativeInterface* table = env->functions;
    jint value = ((jint (*)())original)();
    if (env->functions != table || value != baseline) return fail("CriticalNative raw original comparison", id);
    if (pending(env, "CriticalNative original JNI health", id)) return false;
    note("VALIDATED raw CriticalNative original", id); return true;
}
static bool backup(JNIEnv* env, Hook& hook, jobject ordinary, const unsigned char* snapshot) {
    Region class_map, quick_map;
    if (!region_for(hook.class_ref, 8, &class_map) || !strchr(class_map.permissions, 'r') || !strstr(class_map.path, "boot") || !strstr(class_map.path, ".art")) return fail("class is not immutable boot image", hook.id);
    if (!region_for(hook.original_quick, 1, &quick_map) || !strchr(quick_map.permissions, 'x')) return fail("quick entry is not executable", hook.id);
    jobject loader = env->CallObjectMethod(hook.clazz, get_loader);
    if (pending(env, "class loader", hook.id)) return false;
    jobject boot_loader = env->CallObjectMethod(object_class, get_loader);
    if (pending(env, "bootstrap loader", hook.id) || !env->IsSameObject(loader, boot_loader)) return fail("unexpected class loader", hook.id);
    env->DeleteLocalRef(loader); env->DeleteLocalRef(boot_loader);
    jobject independent = env->ToReflectedMethod(hook.clazz, hook.method, hook.is_static ? JNI_TRUE : JNI_FALSE);
    if (pending(env, "independent reflection", hook.id) || !independent || env->IsSameObject(independent, ordinary)) return fail("reflection object is aliased", hook.id);
    env->CallVoidMethod(independent, set_accessible, JNI_TRUE);
    if (pending(env, "setAccessible", hook.id)) return false;
    if (posix_memalign(&hook.copy, 8, ART_SIZE) || !hook.copy) return fail("backup allocation", hook.id);
    memcpy(hook.copy, snapshot, ART_SIZE);
    hook.backup = env->NewGlobalRef(independent);
    if (pending(env, "backup root", hook.id) || !hook.backup) return false;
    env->SetLongField(hook.backup, art_field, (jlong)(uintptr_t)hook.copy);
    if (pending(env, "independent metadata pointer", hook.id) || (uintptr_t)env->GetLongField(ordinary, art_field) != hook.art) return fail("original reflection pointer changed", hook.id);
    env->DeleteLocalRef(independent);
    return true;
}
static bool intact(JNIEnv* env, const Hook& hook) {
    if (hook.critical) return true;
    if (!hook.backup || !hook.copy || (uintptr_t)hook.copy == hook.art || env->GetObjectRefType(hook.backup) != JNIGlobalRefType || env->GetObjectRefType(hook.clazz) != JNIGlobalRefType) return false;
    if ((uintptr_t)env->GetLongField(hook.backup, art_field) != (uintptr_t)hook.copy || env->ExceptionCheck()) return false;
    const uint32_t* words = (const uint32_t*)hook.copy;
    return words[0] == hook.class_ref && words[2] == hook.dex_index && (words[1] & NATIVE) &&
        *(uintptr_t*)((char*)hook.copy + JNI_SLOT) == hook.original_native && *(uintptr_t*)((char*)hook.copy + QUICK_SLOT) == hook.original_quick;
}
static bool registered_metadata(const Hook& hook) {
    uint32_t header[4]; uintptr_t entry = 0; Region executable;
    const unsigned expected = NATIVE | (hook.is_static ? STATIC : 0) | (hook.critical ? CRITICAL : 0);
    return read_mapped(hook.art, header, sizeof(header)) && read_mapped(hook.art + JNI_SLOT, &entry, sizeof(entry)) &&
        header[0] == hook.class_ref && header[2] == hook.dex_index &&
        (header[1] & (NATIVE | STATIC | CRITICAL)) == expected &&
        entry && entry == hook.installed_entry && entry != hook.original_native && entry != core_base + hook.callback_rva &&
        region_for(entry, 1, &executable) && strchr(executable.permissions, 'x');
}
static void unwrap_target_exception(JNIEnv* env) {
    jthrowable thrown = env->ExceptionOccurred();
    env->ExceptionClear();
    if (env->IsInstanceOf(thrown, invocation_exception)) {
        jthrowable cause = (jthrowable)env->CallObjectMethod(thrown, get_cause);
        if (!env->ExceptionCheck() && cause) { env->Throw(cause); return; }
        env->ExceptionClear();
    }
    env->Throw(thrown);
}
struct RecursionGuard {
    uintptr_t previous;
    explicit RecursionGuard(uintptr_t value) : previous(value) {}
    ~RecursionGuard() { pthread_setspecific(recursion_key, (void*)previous); }
};
static jobject invoke_backup(JNIEnv* env, Hook& hook, jobject receiver, const jvalue* values) {
    uintptr_t previous = (uintptr_t)pthread_getspecific(recursion_key);
    uintptr_t bit = (uintptr_t)1 << hook.index;
    if ((previous & bit) || !hook.backup) {
        fail("backup recursion or absent backup", hook.id);
        env->ThrowNew(illegal_state, "Cage native backup recursion or unavailable method"); return 0;
    }
    RecursionGuard guard(previous);
    if (pthread_setspecific(recursion_key, (void*)(previous | bit))) {
        env->ThrowNew(illegal_state, "Cage native backup thread state unavailable"); return 0;
    }
    if (env->PushLocalFrame(32) != JNI_OK) return 0;
    size_t count = strlen(hook.arguments);
    jobjectArray args = env->NewObjectArray(count, object_class, 0);
    if (!args || env->ExceptionCheck()) { env->PopLocalFrame(0); return 0; }
    for (size_t i = 0; i < count; ++i) {
        jobject value = 0; bool boxed = true;
        switch (hook.arguments[i]) {
            case 'I': value = env->CallStaticObjectMethod(integer_class, integer_box, values[i].i); break;
            case 'J': value = env->CallStaticObjectMethod(long_class, long_box, values[i].j); break;
            case 'Z': value = env->CallStaticObjectMethod(boolean_class, boolean_box, values[i].z); break;
            default: value = values[i].l; boxed = false; break;
        }
        if (env->ExceptionCheck()) { env->PopLocalFrame(0); return 0; }
        env->SetObjectArrayElement(args, i, value);
        if (boxed && value) env->DeleteLocalRef(value);
        if (env->ExceptionCheck()) { env->PopLocalFrame(0); return 0; }
    }
    jobject result = env->CallObjectMethod(hook.backup, invoke_method, hook.is_static ? (jobject)0 : receiver, args);
    if (env->ExceptionCheck()) { unwrap_target_exception(env); env->PopLocalFrame(0); return 0; }
    return env->PopLocalFrame(result);
}
static jint unbox_int(JNIEnv* env, jobject result) {
    if (env->ExceptionCheck()) return 0;
    if (!result) { env->ThrowNew(illegal_state, "Cage native integer result missing"); return 0; }
    jint value = env->CallIntMethod(result, integer_value); env->DeleteLocalRef(result); return value;
}
static jlong unbox_long(JNIEnv* env, jobject result) {
    if (env->ExceptionCheck()) return 0;
    if (!result) { env->ThrowNew(illegal_state, "Cage native long result missing"); return 0; }
    jlong value = env->CallLongMethod(result, long_value); env->DeleteLocalRef(result); return value;
}
static jboolean unbox_boolean(JNIEnv* env, jobject result) {
    if (env->ExceptionCheck()) return JNI_FALSE;
    if (!result) { env->ThrowNew(illegal_state, "Cage native boolean result missing"); return JNI_FALSE; }
    jboolean value = env->CallBooleanMethod(result, boolean_value); env->DeleteLocalRef(result); return value;
}

#include "typed_adapters.inc"

static bool prepare_hook(JNIEnv* env, Hook& hook, unsigned index) {
    hook.index = index;
    hook.clazz = root_class(env, hook.class_name);
    if (pending(env, "framework class", hook.id) || !hook.clazz) return fail("framework class unavailable", hook.id);
    hook.method = hook.is_static ? env->GetStaticMethodID(hook.clazz, hook.name, hook.signature) : env->GetMethodID(hook.clazz, hook.name, hook.signature);
    if (!hook.method || env->ExceptionCheck()) {
        env->ExceptionClear();
        if (hook.expected_native) return fail("required framework method absent", hook.id);
        note("SKIP absent", hook.id); return true;
    }
    jobject reflected = env->ToReflectedMethod(hook.clazz, hook.method, hook.is_static ? JNI_TRUE : JNI_FALSE);
    if (pending(env, "method reflection", hook.id) || !reflected) return false;
    jint modifiers = env->CallIntMethod(reflected, get_modifiers);
    if (pending(env, "method modifiers", hook.id)) return false;
    if (!(modifiers & NATIVE)) {
        env->DeleteLocalRef(reflected);
        if (hook.expected_native) return fail("required framework method is not native", hook.id);
        note("SKIP Java wrapper", hook.id); return true;
    }
    hook.is_native = true;
    if (!hook.attempted_by_core) { env->DeleteLocalRef(reflected); note("SKIP SDK gate", hook.id); return true; }
    unsigned char snapshot[ART_SIZE];
    hook.art = (uintptr_t)env->GetLongField(reflected, art_field);
    if (pending(env, "method metadata", hook.id) || !read_mapped(hook.art, snapshot, sizeof(snapshot))) return fail("method metadata unreadable", hook.id);
    uint32_t flags; memcpy(&flags, snapshot + 4, 4);
    memcpy(&hook.class_ref, snapshot, 4); memcpy(&hook.dex_index, snapshot + 8, 4);
    memcpy(&hook.original_native, snapshot + JNI_SLOT, sizeof(uintptr_t));
    memcpy(&hook.original_quick, snapshot + QUICK_SLOT, sizeof(uintptr_t));
    if (!(flags & NATIVE) || !!(flags & STATIC) != hook.is_static || !!(flags & CRITICAL) != hook.critical) return fail("native ABI flags mismatch", hook.id);
    if (!host_entry(hook.original_native)) return fail("native entry x86 mapping not proven", hook.id);
    if (hook.critical) {
        if (!CAGE_CRITICAL_NATIVE_VALIDATED) return fail("CriticalNative experiment not validated", hook.id);
        if ((flags & 0x00080000) || !validate_critical_original(env, hook.clazz, hook.method, hook.original_native, hook.id)) return false;
    } else if (!backup(env, hook, reflected, snapshot) || !intact(env, hook)) return fail("backup verification", hook.id);
    env->DeleteLocalRef(reflected); note("PREPARED", hook.id); return true;
}

} // namespace

extern "C" bool cage_compat_prepare(JNIEnv* env, JavaVM* vm, uintptr_t base) {
    if (prepared) return !__atomic_load_n(&failed, __ATOMIC_ACQUIRE) && core_base == base;
    if (sizeof(void*) != 8 || !base || !vm) return fail("invalid runtime profile");
    core_base = base; java_vm = vm;
    if (pthread_key_create(&recursion_key, 0)) return fail("thread state key");
    if (!cache_java(env)) return fail("java cache");
    for (unsigned i = 0; i < sizeof(hooks) / sizeof(hooks[0]); ++i) if (!prepare_hook(env, hooks[i], i)) return false;
    jclass binder = env->FindClass("android/os/Binder");
    if (pending(env, "Binder auxiliary class") || !binder) return false;
    for (Auxiliary& item : auxiliary) {
        item.method = env->GetStaticMethodID(binder, item.name, "()I");
        if (pending(env, "Binder auxiliary lookup", item.name) || !item.method) return false;
        uintptr_t art; unsigned char snapshot[ART_SIZE]; jobject reflected;
        if (!metadata(env, binder, item.method, true, &art, snapshot, &reflected)) return false;
        uint32_t flags; memcpy(&flags, snapshot + 4, 4);
        memcpy(&item.original, snapshot + JNI_SLOT, sizeof(uintptr_t));
        env->DeleteLocalRef(reflected);
        if (!(flags & CRITICAL) || (flags & 0x00080000) || !host_entry(item.original) || !CAGE_CRITICAL_NATIVE_VALIDATED) return fail("Binder auxiliary ABI or mapping", item.name);
        if (!validate_critical_original(env, binder, item.method, item.original, item.name)) return false;
        note("PREPARED auxiliary", item.name);
    }
    env->DeleteLocalRef(binder); prepared = true; note("PREPARE_COMPLETE", ""); return true;
}

extern "C" bool cage_compat_hook(JNIEnv* env, jclass clazz, const char* name, const char* signature,
                                 bool is_static, void** original_slot, void* replacement) {
    if (!prepared || __atomic_load_n(&failed, __ATOMIC_ACQUIRE)) return false;
    Hook* found = 0;
    for (Hook& hook : hooks) {
        if ((uintptr_t)original_slot == core_base + hook.slot_rva && (uintptr_t)replacement == core_base + hook.callback_rva) { found = &hook; break; }
    }
    if (!found || !name || !signature || strcmp(name, found->name) || strcmp(signature, found->signature) ||
        is_static != found->is_static || !env->IsSameObject(clazz, found->clazz)) return fail("unrecognized installer call");
    Hook& hook = *found;
    // Repeat the original lookup/modifier decision at the actual install point.
    jmethodID id = is_static ? env->GetStaticMethodID(clazz, name, signature) : env->GetMethodID(clazz, name, signature);
    if (!id || env->ExceptionCheck()) { env->ExceptionClear(); note("SKIP absent", hook.id); return false; }
    jobject reflected = env->ToReflectedMethod(clazz, id, is_static ? JNI_TRUE : JNI_FALSE);
    if (pending(env, "install reflection", hook.id) || !reflected) return false;
    jint modifiers = env->CallIntMethod(reflected, get_modifiers);
    env->DeleteLocalRef(reflected);
    if (pending(env, "install modifiers", hook.id)) return false;
    if (!(modifiers & NATIVE)) { note("SKIP Java wrapper", hook.id); return false; }
    if (!hook.is_native || !hook.attempted_by_core || id != hook.method || !intact(env, hook)) return fail("method changed since preparation", hook.id);
    if (hook.installed) return true;
    if (hook.slot_rva == 0xe2840 && hook.callback_rva == 0x2a7d4 && !publish_binder_auxiliary()) return false;
    void* saved = *original_slot;
    *original_slot = hook.critical ? (void*)hook.original_native : hook.adapter;
    JNINativeMethod registration = {const_cast<char*>(name), const_cast<char*>(signature), replacement};
    jint result = env->RegisterNatives(clazz, &registration, 1);
    if (pending(env, "RegisterNatives", hook.id) || result != JNI_OK) { *original_slot = saved; return fail("registration failed", hook.id); }
    if (!read_mapped(hook.art + JNI_SLOT, &hook.installed_entry, sizeof(hook.installed_entry)) || !registered_metadata(hook)) return fail("registered metadata or bridge entry invalid", hook.id);
    hook.installed = true; note("INSTALLED", hook.id); return true;
}

extern "C" void* cage_compat_get_original(jmethodID id) {
    if (!prepared || __atomic_load_n(&failed, __ATOMIC_ACQUIRE)) return 0;
    for (const Auxiliary& item : auxiliary) if (id == item.method) {
        auxiliary_reads |= item.bit; note("READ auxiliary", item.name); return (void*)item.original;
    }
    fail("unrecognized auxiliary method ID"); return 0;
}

extern "C" bool cage_compat_verify(JNIEnv* env) {
    if (!prepared || __atomic_load_n(&failed, __ATOMIC_ACQUIRE)) return false;
    unsigned required = 0, installed = 0;
    for (const Hook& hook : hooks) if (hook.is_native && hook.attempted_by_core) {
        ++required;
        if (!hook.installed || !intact(env, hook) || !registered_metadata(hook)) return fail("required installation, method metadata or backup invalid", hook.id);
        void* expected = hook.critical ? (void*)hook.original_native : hook.adapter;
        if (*(void**)(core_base + hook.slot_rva) != expected) return fail("original adapter slot changed", hook.id);
        ++installed;
    }
    if (auxiliary_reads != 3) return fail("Binder auxiliary reads incomplete");
    if (!auxiliary_slots_writable()) return fail("Binder auxiliary final mapping");
    for (const Auxiliary& item : auxiliary) {
        if (__atomic_load_n(reinterpret_cast<uintptr_t*>(core_base + item.slot_rva), __ATOMIC_ACQUIRE) != item.original)
            return fail("Binder auxiliary final slot mismatch", item.name);
    }
    note("BINDER_AUXILIARY_FINAL_SLOTS_MATCH", "");
    __android_log_print(ANDROID_LOG_INFO, "CageNativeCompat", "VERIFY_COMPLETE installed=%u required=%u auxiliary=2", installed, required);
    return !pending(env, "final verification");
}
