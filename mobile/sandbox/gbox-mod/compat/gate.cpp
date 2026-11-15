#include "runtime_api.h"
#include "sample_guard.h"
#include <android/log.h>
#include <dlfcn.h>
#include <elf.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/system_properties.h>
#include <unistd.h>

#if !defined(__aarch64__)
#error "This compatibility candidate is restricted to an ARM64 guest library"
#endif

static JavaVM* vm;
static pthread_mutex_t install_lock = PTHREAD_MUTEX_INITIALIZER;
static bool installed;
static void* retained_core;

extern "C" bool cage_compat_diagnostic_ready() {
    return installed && retained_core;
}

static void stage(const char* label) {
    __android_log_write(ANDROID_LOG_INFO, "CageNativeCompat", label);
}

struct Region {
    uintptr_t first, last;
    unsigned long offset;
    char permissions[5];
    char path[512];
};

static bool parse_region(const char* line, Region* region) {
    unsigned long first, last, offset;
    char permissions[5] = {};
    int position = 0;
    if (sscanf(line, "%lx-%lx %4s %lx %*s %*s %n", &first, &last, permissions,
               &offset, &position) != 4 || first >= last) return false;
    region->first = first; region->last = last; region->offset = offset;
    memcpy(region->permissions, permissions, sizeof(permissions));
    const char* path = line + position;
    while (*path == ' ') ++path;
    snprintf(region->path, sizeof(region->path), "%s", path);
    region->path[strcspn(region->path, "\r\n")] = 0;
    return true;
}

static bool mapped_region(uintptr_t address, size_t length, Region* region) {
    if (!length || address > UINTPTR_MAX - length) return false;
    FILE* maps = fopen("/proc/self/maps", "r");
    if (!maps) return false;
    bool found = false;
    char line[1024];
    Region current;
    while (fgets(line, sizeof(line), maps)) {
        if (!parse_region(line, &current)) continue;
        if (current.first <= address && address + length <= current.last) {
            *region = current;
            found = true;
            break;
        }
    }
    fclose(maps);
    return found;
}

static bool bytes_equal(uintptr_t address, const unsigned char* expected, size_t length) {
    Region region;
    return mapped_region(address, length, &region) && region.permissions[0] == 'r'
            && !memcmp(reinterpret_cast<const void*>(address), expected, length);
}

static bool property_is(const char* name, const char* expected) {
    char value[PROP_VALUE_MAX] = {};
    return __system_property_get(name, value) > 0 && !strcmp(value, expected);
}

static bool property_nonempty(const char* name) {
    char value[PROP_VALUE_MAX] = {};
    return __system_property_get(name, value) > 0;
}

static bool property_ends_with(const char* name, const char* suffix) {
    char value[PROP_VALUE_MAX] = {};
    int length = __system_property_get(name, value);
    size_t suffix_len = strlen(suffix);
    return length > 0 && static_cast<size_t>(length) >= suffix_len
            && !strcmp(value + static_cast<size_t>(length) - suffix_len, suffix);
}

static bool runtime_matches(jint sdk) {
    if (sdk != 31 && sdk != 32) { stage("guard.api.mismatch"); return false; }
    char version[PROP_VALUE_MAX] = {};
    if (__system_property_get("ro.build.version.sdk", version) <= 0 || atoi(version) != sdk) {
        stage("guard.api.mismatch"); return false;
    }
    if (!property_ends_with("ro.build.fingerprint", ":12/V417IR/2721:user/release-keys")
            || !property_nonempty("ro.hardware")
            || !property_nonempty("ro.product.board")
            || !property_is("ro.dalvik.vm.native.bridge", "libnb.so")) {
        stage("guard.properties.mismatch"); return false;
    }
    FILE* maps = fopen("/proc/self/maps", "r");
    if (!maps) { stage("guard.mappings.unavailable"); return false; }
    bool bridge = false, host_art = false;
    char line[1024];
    Region region;
    while (fgets(line, sizeof(line), maps)) {
        if (!parse_region(line, &region)) continue;
        if (strstr(region.path, "/system/lib64/arm64/nb/libtcb.so")) bridge = true;
        if (!strstr(region.path, "/lib64/libart.so") || region.offset || region.permissions[0] != 'r'
                || region.last - region.first < sizeof(Elf64_Ehdr)) continue;
        Elf64_Ehdr header;
        memcpy(&header, reinterpret_cast<const void*>(region.first), sizeof(header));
        if (!memcmp(header.e_ident, ELFMAG, SELFMAG) && header.e_ident[EI_CLASS] == ELFCLASS64
                && header.e_ident[EI_DATA] == ELFDATA2LSB && header.e_machine == EM_X86_64) host_art = true;
    }
    fclose(maps);
    if (!bridge) stage("guard.bridge.missing");
    if (!host_art) stage("guard.hostArt.mismatch");
    return bridge && host_art;
}

static bool sample_matches(uintptr_t base, uintptr_t symbol) {
    if (symbol < base || symbol - base != kJniOnLoadOffset) {
        stage("guard.symbol.mismatch"); return false;
    }
    if (!bytes_equal(base, kElfHeader, sizeof(kElfHeader))
            || !bytes_equal(base + kBuildIdOffset, kBuildId, sizeof(kBuildId))) {
        stage("guard.elfIdentity.mismatch"); return false;
    }
    if (!bytes_equal(base + kHelperOffset, kHelperBody, sizeof(kHelperBody))) {
        stage("guard.helperBody.mismatch"); return false;
    }
    if (!bytes_equal(base + kGetterOffset, kGetterBody, sizeof(kGetterBody))) {
        stage("guard.getterBody.mismatch"); return false;
    }
    if (!bytes_equal(base + kBinderCallbackOffset, kBinderCallbackBody, sizeof(kBinderCallbackBody))) {
        stage("guard.binderCallbackBody.mismatch"); return false;
    }
    if (!bytes_equal(base + kBinderInstallerOffset, kBinderInstallerBody, sizeof(kBinderInstallerBody))) {
        stage("guard.binderInstallerBody.mismatch"); return false;
    }
    return true;
}

struct EntryPatch {
    uintptr_t address, page;
    int original_protection;
    unsigned char before[16], after[16];
};

static bool prepare_patch(uintptr_t address, uintptr_t destination, EntryPatch* patch) {
    Region region;
    if ((address & 3) || (destination & 3) || !mapped_region(address, 16, &region)
            || region.permissions[0] != 'r' || region.permissions[3] != 'p') return false;
    patch->address = address;
    patch->page = address & ~static_cast<uintptr_t>(4095);
    patch->original_protection = PROT_READ;
    if (region.permissions[1] == 'w') patch->original_protection |= PROT_WRITE;
    if (region.permissions[2] == 'x') patch->original_protection |= PROT_EXEC;
    memcpy(patch->before, reinterpret_cast<const void*>(address), 16);
    const uint32_t code[2] = {0x58000050, 0xd61f0200}; // ldr x16, literal(+8); br x16
    memcpy(patch->after, code, 8);
    memcpy(patch->after + 8, &destination, 8);
    return true;
}

static void write_patch(const EntryPatch& patch, bool replacement) {
    memcpy(reinterpret_cast<void*>(patch.address), replacement ? patch.after : patch.before, 16);
    __builtin___clear_cache(reinterpret_cast<char*>(patch.address), reinterpret_cast<char*>(patch.address + 16));
}

static bool redirect_entries(uintptr_t base) {
    if (sysconf(_SC_PAGESIZE) != 4096) return false;
    EntryPatch helper, getter;
    if (!prepare_patch(base + kHelperOffset, reinterpret_cast<uintptr_t>(&cage_compat_hook), &helper)
            || !prepare_patch(base + kGetterOffset, reinterpret_cast<uintptr_t>(&cage_compat_get_original), &getter)
            || helper.page == getter.page) return false;
    if (mprotect(reinterpret_cast<void*>(helper.page), 4096, helper.original_protection | PROT_WRITE)) return false;
    if (mprotect(reinterpret_cast<void*>(getter.page), 4096, getter.original_protection | PROT_WRITE)) {
        if (mprotect(reinterpret_cast<void*>(helper.page), 4096, helper.original_protection)) abort();
        return false;
    }
    stage("redirect.helper.before");
    write_patch(helper, true);
    stage("redirect.helper.after");
    stage("redirect.originalGetter.before");
    write_patch(getter, true);
    stage("redirect.originalGetter.after");
    bool restored_helper = !mprotect(reinterpret_cast<void*>(helper.page), 4096, helper.original_protection);
    bool restored_getter = !mprotect(reinterpret_cast<void*>(getter.page), 4096, getter.original_protection);
    bool confirmed = bytes_equal(helper.address, helper.after, 16) && bytes_equal(getter.address, getter.after, 16);
    if (!restored_helper || !restored_getter || !confirmed) {
        // Roll back both redirections before reporting failure; never continue with half an install.
        if (mprotect(reinterpret_cast<void*>(helper.page), 4096, helper.original_protection | PROT_WRITE)
                || mprotect(reinterpret_cast<void*>(getter.page), 4096, getter.original_protection | PROT_WRITE)) abort();
        write_patch(helper, false);
        write_patch(getter, false);
        if (mprotect(reinterpret_cast<void*>(helper.page), 4096, helper.original_protection)
                || mprotect(reinterpret_cast<void*>(getter.page), 4096, getter.original_protection)) abort();
        return false;
    }
    stage("redirect.verified");
    return true;
}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* machine, void*) {
    vm = machine;
    return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT jint JNICALL
Java_io_github_leexeo_cage_gbox_NativeCompat_nativeInstall(JNIEnv* env, jclass, jint sdk) {
    pthread_mutex_lock(&install_lock);
    if (installed) { pthread_mutex_unlock(&install_lock); return 1; }
    if (!runtime_matches(sdk)) {
        stage("guard.runtime.unsupported.originalPath");
        pthread_mutex_unlock(&install_lock); return 0;
    }
    void* core = dlopen("libvlitecore64.so", RTLD_NOW | RTLD_NOLOAD);
    void* symbol = core ? dlsym(core, "JNI_OnLoad") : nullptr;
    if (!core) stage("guard.core.notLoaded");
    if (core && !symbol) stage("guard.core.symbolMissing");
    Dl_info location = {};
    bool located = symbol && dladdr(symbol, &location) && location.dli_fbase && location.dli_fname;
    const char* filename = located ? strrchr(location.dli_fname, '/') : nullptr;
    filename = filename ? filename + 1 : (located ? location.dli_fname : "");
    uintptr_t base = reinterpret_cast<uintptr_t>(location.dli_fbase);
    if (!located || strcmp(filename, "libvlitecore64.so")
            || !sample_matches(base, reinterpret_cast<uintptr_t>(symbol))) {
        stage("guard.sample.mismatch.originalPath");
        if (core) dlclose(core);
        pthread_mutex_unlock(&install_lock); return 0;
    }
    stage("guard.ready");
    if (!vm || !cage_compat_prepare(env, vm, base) || env->ExceptionCheck()) {
        stage("prepare.failed");
        dlclose(core);
        pthread_mutex_unlock(&install_lock); return -1;
    }
    stage("prepare.ready");
    if (!sample_matches(base, reinterpret_cast<uintptr_t>(symbol)) || !redirect_entries(base)) {
        stage("redirect.failed");
        dlclose(core);
        pthread_mutex_unlock(&install_lock); return -1;
    }
    retained_core = core;
    installed = true;
    stage("install.done");
    pthread_mutex_unlock(&install_lock);
    return 1;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_io_github_leexeo_cage_gbox_NativeCompat_nativeVerify(JNIEnv* env, jclass) {
    if (!installed || !retained_core) return JNI_FALSE;
    bool ok = cage_compat_verify(env) && !env->ExceptionCheck();
    stage(ok ? "verify.pass" : "verify.failed");
    return ok ? JNI_TRUE : JNI_FALSE;
}
