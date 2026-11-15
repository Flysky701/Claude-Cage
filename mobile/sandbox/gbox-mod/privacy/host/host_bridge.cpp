// Verified MuMu API31/32 loader path. Java permits installation only after
// selected-guest/context/native compatibility checks and ARM refresh preparation.
// No copied ArtMethod, reflection invocation, or modified FindClass policy.
#include <jni.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dlfcn.h>
#include <elf.h>
#include <android/log.h>

#if !defined(__x86_64__)
#error The helper must execute as a true host x86_64 JNI library.
#endif

namespace {
constexpr size_t kArtSize = 32, kJniSlot = 16, kQuickSlot = 24;
constexpr uint32_t kNative = 0x100, kStatic = 8, kFast = 0x80000, kCritical = 0x100000;
using NativeLoad = jstring (*)(JNIEnv*, jclass, jstring, jobject, jclass);
NativeLoad original_load;
jclass runtime_class, callback_class, retained_helper_class;
jmethodID runtime_method, callback_method;
uintptr_t method_address;
unsigned char original_metadata[kArtSize];
bool installed, registration_started;
unsigned calls, successes, errors, notifications, exceptions, max_depth;
thread_local unsigned depth;
struct ErrorCheck { jstring path; unsigned calls = 0, notifications = 0; bool success = false; };
thread_local ErrorCheck* error_check;

void note(const char* value) { __android_log_print(ANDROID_LOG_INFO, "CageHostLoad", "%s", value); }

struct Region { uintptr_t first, last; uint64_t offset; char permissions[5]; };
bool region(uintptr_t address, size_t size, Region* result) {
    if (!address || !size || address > UINTPTR_MAX - size) return false;
    FILE* maps = fopen("/proc/self/maps", "re");
    if (!maps) return false;
    char line[2048]; bool found = false;
    while (fgets(line, sizeof(line), maps)) {
        unsigned long long first, last, offset; char permissions[5] = {};
        if (sscanf(line, "%llx-%llx %4s %llx", &first, &last, permissions, &offset) != 4)
            continue;
        if (address >= first && address + size <= last && permissions[0] == 'r') {
            if (result) {
                result->first = first; result->last = last; result->offset = offset;
                memcpy(result->permissions, permissions, sizeof(permissions));
            }
            found = true; break;
        }
    }
    fclose(maps); return found;
}

bool host_image(void* function) {
    Dl_info owner{}; Region text;
    if (!dladdr(function, &owner) || !owner.dli_fbase ||
        !region(reinterpret_cast<uintptr_t>(function), 1, &text) || text.permissions[2] != 'x')
        return false;
    uintptr_t base = reinterpret_cast<uintptr_t>(owner.dli_fbase);
    if (!region(base, sizeof(Elf64_Ehdr), nullptr)) return false;
    Elf64_Ehdr header; memcpy(&header, reinterpret_cast<void*>(base), sizeof(header));
    if (memcmp(header.e_ident, ELFMAG, SELFMAG) || header.e_ident[EI_CLASS] != ELFCLASS64 ||
        header.e_ident[EI_DATA] != ELFDATA2LSB || header.e_machine != EM_X86_64 ||
        header.e_phentsize != sizeof(Elf64_Phdr) || !header.e_phnum || header.e_phnum > 128 ||
        header.e_phoff > UINTPTR_MAX - base ||
        !region(base + header.e_phoff, header.e_phnum * sizeof(Elf64_Phdr), nullptr)) return false;
    for (unsigned index = 0; index < header.e_phnum; ++index) {
        Elf64_Phdr load;
        memcpy(&load, reinterpret_cast<void*>(base + header.e_phoff + index * sizeof(load)), sizeof(load));
        if (load.p_type != PT_LOAD || !(load.p_flags & PF_X) || load.p_vaddr > UINTPTR_MAX - base)
            continue;
        uintptr_t first = base + load.p_vaddr;
        uintptr_t pc = reinterpret_cast<uintptr_t>(function);
        if (load.p_memsz <= UINTPTR_MAX - first && pc >= first && pc < first + load.p_memsz)
            return true;
    }
    return false;
}

bool host_process() {
    unsigned char header[20] = {};
    int fd = open("/proc/self/exe", O_RDONLY | O_CLOEXEC);
    if (fd < 0) return false;
    ssize_t size = read(fd, header, sizeof(header)); close(fd);
    return size == sizeof(header) && !memcmp(header, ELFMAG, SELFMAG) &&
        header[EI_CLASS] == ELFCLASS64 && header[EI_DATA] == ELFDATA2LSB &&
        (static_cast<unsigned>(header[18]) | (static_cast<unsigned>(header[19]) << 8)) == EM_X86_64;
}

jstring text(JNIEnv* env, const char* value) { return env->NewStringUTF(value); }
jstring stop(JNIEnv* env, const char* stage) {
    // These are the installer's own preparation/check failures, never a wrapped
    // load's exception. The wrapper below preserves original pending errors.
    if (env->ExceptionCheck()) env->ExceptionClear();
    char value[160];
    snprintf(value, sizeof(value), "STOP host.%s registered=%d", stage, registration_started);
    note(value);
    return text(env, value);
}

static jstring wrapper(JNIEnv*, jclass, jstring, jobject, jclass);

bool metadata_intact() {
    unsigned char current[kArtSize];
    if (!method_address || !region(method_address, sizeof(current), nullptr)) return false;
    memcpy(current, reinterpret_cast<void*>(method_address), sizeof(current));
    uintptr_t entry; memcpy(&entry, current + kJniSlot, sizeof(entry));
    return !memcmp(current, original_metadata, kJniSlot) &&
        !memcmp(current + kQuickSlot, original_metadata + kQuickSlot, sizeof(uintptr_t)) &&
        entry == reinterpret_cast<uintptr_t>(wrapper);
}

static jstring wrapper(JNIEnv* env, jclass owner, jstring path, jobject loader, jclass caller) {
    __atomic_fetch_add(&calls, 1u, __ATOMIC_RELAXED);
    unsigned current_depth = ++depth;
    unsigned observed = __atomic_load_n(&max_depth, __ATOMIC_RELAXED);
    while (observed < current_depth && !__atomic_compare_exchange_n(&max_depth, &observed,
            current_depth, true, __ATOMIC_RELAXED, __ATOMIC_RELAXED)) {}
    ErrorCheck* check = error_check;
    bool checked = check && env->IsSameObject(check->path, path);
    if (checked) ++check->calls;

    // Both functions are host ISA, and the original Runtime.nativeLoad frame
    // remains the current ArtMethod during the entire original load/JNI_OnLoad.
    jstring result = original_load(env, owner, path, loader, caller);
    if (env->ExceptionCheck()) {
        __atomic_fetch_add(&exceptions, 1u, __ATOMIC_RELAXED);
    } else if (result) {
        __atomic_fetch_add(&errors, 1u, __ATOMIC_RELAXED);
    } else {
        __atomic_fetch_add(&successes, 1u, __ATOMIC_RELAXED);
        if (checked) check->success = true;
        // An explicit JNI call performs host-to-ARM reference/ABI conversion.
        // No ARM function pointer is directly invoked by this host library.
        note("host.callback.before");
        env->CallStaticVoidMethod(callback_class, callback_method, path);
        if (env->ExceptionCheck()) {
            __atomic_fetch_add(&exceptions, 1u, __ATOMIC_RELAXED);
            // Preserve this added callback failure as a visible exception;
            // successful completion is not reported when refresh dispatch fails.
            note("host.callback.after.pendingException");
        } else {
            __atomic_fetch_add(&notifications, 1u, __ATOMIC_RELAXED);
            if (checked) ++check->notifications;
            note("host.callback.after.returned");
        }
    }
    --depth;
    return result;
}
} // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_io_github_leexeo_cage_privacy_host_HostBridge_profile(JNIEnv* env, jclass owner) {
    if (sizeof(void*) != 8 || !host_process() || !host_image(reinterpret_cast<void*>(wrapper)))
        return stop(env, "profile.machine");
    jclass version = env->FindClass("android/os/Build$VERSION");
    jfieldID sdk_field = version ? env->GetStaticFieldID(version, "SDK_INT", "I") : nullptr;
    jint sdk = sdk_field ? env->GetStaticIntField(version, sdk_field) : 0;
    if (env->ExceptionCheck() || (sdk != 31 && sdk != 32)) return stop(env, "profile.sdk");
    jclass class_type = env->FindClass("java/lang/Class");
    jmethodID loader_method = class_type ? env->GetMethodID(class_type, "getClassLoader", "()Ljava/lang/ClassLoader;") : nullptr;
    jobject own_loader = loader_method ? env->CallObjectMethod(owner, loader_method) : nullptr;
    jclass dex_type = env->FindClass("dalvik/system/DexClassLoader");
    if (env->ExceptionCheck() || !own_loader || !dex_type || !env->IsInstanceOf(own_loader, dex_type))
        return stop(env, "profile.helperLoader");
    jclass loader_type = env->FindClass("java/lang/ClassLoader");
    jmethodID parent_method = loader_type ? env->GetMethodID(loader_type, "getParent", "()Ljava/lang/ClassLoader;") : nullptr;
    jobject parent = parent_method ? env->CallObjectMethod(own_loader, parent_method) : nullptr;
    jclass object_type = env->FindClass("java/lang/Object");
    jobject boot = object_type && loader_method ? env->CallObjectMethod(object_type, loader_method) : nullptr;
    if (env->ExceptionCheck() || !parent_method || !env->IsSameObject(parent, boot))
        return stop(env, "profile.bootParent");
    return text(env, "PASS host.profile actualImageMachine=62 processMachine=62 pointerBits=64 bootParent=true");
}

extern "C" JNIEXPORT jstring JNICALL
Java_io_github_leexeo_cage_privacy_host_HostBridge_install(JNIEnv* env, jclass owner, jclass callback, jstring missing) {
    if (installed || !callback || !missing || !host_process()) return stop(env, "install.precondition");
    const char* absent = env->GetStringUTFChars(missing, nullptr);
    if (!absent || env->ExceptionCheck()) return stop(env, "install.pathString");
    struct stat ignored{};
    bool nonexistent = absent[0] == '/' && lstat(absent, &ignored) == -1 && errno == ENOENT;
    env->ReleaseStringUTFChars(missing, absent);
    if (!nonexistent) return stop(env, "install.pathNotAbsent");

    jclass runtime = env->FindClass("java/lang/Runtime");
    runtime_method = runtime ? env->GetStaticMethodID(runtime, "nativeLoad",
        "(Ljava/lang/String;Ljava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/String;") : nullptr;
    if (!runtime_method || env->ExceptionCheck()) return stop(env, "install.method");
    runtime_class = static_cast<jclass>(env->NewGlobalRef(runtime));
    jclass executable = env->FindClass("java/lang/reflect/Executable");
    jfieldID art = executable ? env->GetFieldID(executable, "artMethod", "J") : nullptr;
    jobject reflected = env->ToReflectedMethod(runtime, runtime_method, JNI_TRUE);
    if (!art || !reflected || !runtime_class || env->ExceptionCheck()) return stop(env, "install.reflectionMetadata");
    method_address = static_cast<uintptr_t>(env->GetLongField(reflected, art));
    if (env->ExceptionCheck() || !region(method_address, sizeof(original_metadata), nullptr))
        return stop(env, "install.methodMemory");
    memcpy(original_metadata, reinterpret_cast<void*>(method_address), sizeof(original_metadata));
    uint32_t flags; memcpy(&flags, original_metadata + 4, sizeof(flags));
    uintptr_t entry; memcpy(&entry, original_metadata + kJniSlot, sizeof(entry));
    if ((flags & (kNative | kStatic | kFast | kCritical)) != (kNative | kStatic) ||
        !host_image(reinterpret_cast<void*>(entry))) return stop(env, "install.originalNativeHost");
    original_load = reinterpret_cast<NativeLoad>(entry);

    // Runtime retains a native pointer, not this helper's loader. Pin the
    // defining class/loader/library for the remainder of this process.
    retained_helper_class = static_cast<jclass>(env->NewGlobalRef(owner));
    if (!retained_helper_class || env->ExceptionCheck()) return stop(env, "install.helperLifetime");
    callback_class = static_cast<jclass>(env->NewGlobalRef(callback));
    if (!callback_class || env->ExceptionCheck()) return stop(env, "install.callbackLifetime");
    callback_method = env->GetStaticMethodID(callback, "afterNativeLoad", "(Ljava/lang/String;)V");
    jclass class_type = env->FindClass("java/lang/Class");
    jmethodID loader_method = class_type ? env->GetMethodID(class_type, "getClassLoader", "()Ljava/lang/ClassLoader;") : nullptr;
    jobject loader = loader_method ? env->CallObjectMethod(callback, loader_method) : nullptr;
    if (!retained_helper_class || !callback_class || !callback_method || !loader || env->ExceptionCheck())
        return stop(env, "install.callback");
    // Calling the real method before registration supplies its normal frame.
    jstring baseline = static_cast<jstring>(env->CallStaticObjectMethod(runtime_class, runtime_method,
        missing, loader, callback));
    if (!baseline || env->ExceptionCheck()) return stop(env, "install.originalError");

    JNINativeMethod registration = {const_cast<char*>("nativeLoad"),
        const_cast<char*>("(Ljava/lang/String;Ljava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/String;"),
        reinterpret_cast<void*>(wrapper)};
    registration_started = true;
    jint registered = env->RegisterNatives(runtime_class, &registration, 1);
    installed = registered == JNI_OK;
    if (!installed || env->ExceptionCheck() || !metadata_intact()) return stop(env, "install.registrationMetadata");
    jmethodID looked_up = env->GetStaticMethodID(runtime_class, "nativeLoad", registration.signature);
    if (looked_up != runtime_method || env->ExceptionCheck()) return stop(env, "install.methodIdentity");

    ErrorCheck check{missing};
    ErrorCheck* previous = error_check; error_check = &check;
    jstring wrapped = static_cast<jstring>(env->CallStaticObjectMethod(runtime_class, runtime_method,
        missing, loader, callback));
    error_check = previous;
    if (!wrapped || env->ExceptionCheck()) return stop(env, "install.wrappedError");
    const char* before = env->GetStringUTFChars(baseline, nullptr);
    if (!before || env->ExceptionCheck()) return stop(env, "install.originalErrorString");
    const char* after = env->GetStringUTFChars(wrapped, nullptr);
    if (!after || env->ExceptionCheck()) {
        env->ReleaseStringUTFChars(baseline, before); return stop(env, "install.wrappedErrorString");
    }
    bool equal = strcmp(before, after) == 0;
    env->ReleaseStringUTFChars(wrapped, after); env->ReleaseStringUTFChars(baseline, before);
    if (!equal || check.calls != 1 || check.notifications || check.success || !metadata_intact())
        return stop(env, "install.errorContract");
    note("host.install.pass originalMethodIdentity=true errorPreserved=true failedLoadNotified=false");
    return text(env, "PASS host.wrapper.installed originalHost=true originalMethodIdentity=true errorPreserved=true failedLoadNotified=false");
}

extern "C" JNIEXPORT jlongArray JNICALL
Java_io_github_leexeo_cage_privacy_host_HostBridge_diagnostics(JNIEnv* env, jclass) {
    // -1 records an attempted registration without a verified complete install;
    // the Java owner must treat that state as requiring a fresh process.
    jlong values[] = {installed ? 1 : registration_started ? -1 : 0, __atomic_load_n(&calls, __ATOMIC_RELAXED),
        __atomic_load_n(&successes, __ATOMIC_RELAXED), __atomic_load_n(&errors, __ATOMIC_RELAXED),
        __atomic_load_n(&notifications, __ATOMIC_RELAXED), __atomic_load_n(&exceptions, __ATOMIC_RELAXED),
        __atomic_load_n(&max_depth, __ATOMIC_RELAXED), metadata_intact()};
    jlongArray result = env->NewLongArray(8);
    if (result) env->SetLongArrayRegion(result, 0, 8, values);
    return result;
}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM*, void*) { return JNI_VERSION_1_6; }
