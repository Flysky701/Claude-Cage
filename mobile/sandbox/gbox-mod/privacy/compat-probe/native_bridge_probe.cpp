#include <jni.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <dlfcn.h>
#include <stdlib.h>

static jclass reporter;
static jmethodID record_method;
static int callback_mode;
static const char* test_key = "cage.bridge_probe.nonexistent.20261115";
static jobject backup_method;
static jclass backup_declaring_class;
static jclass object_class;
static jmethodID method_invoke;
static void* backup_art;
static uint32_t backup_identity[4];
static unsigned callback_depth;

static void stage(JNIEnv* env, const char* text) {
    jstring message = env->NewStringUTF(text);
    env->CallStaticVoidMethod(reporter, record_method, message);
    env->DeleteLocalRef(message);
}

static bool exception(JNIEnv* env, const char* location) {
    if (!env->ExceptionCheck()) return false;
    env->ExceptionDescribe();
    env->ExceptionClear();
    char text[180];
    snprintf(text, sizeof(text), "FAIL java.exception at=%s", location);
    stage(env, text);
    return true;
}

static unsigned elf_machine(const char* path) {
    if (!path || !path[0]) return 0;
    unsigned char header[20];
    int file = open(path, O_RDONLY | O_CLOEXEC);
    if (file < 0) return 0;
    ssize_t length = read(file, header, sizeof(header));
    close(file);
    if (length != sizeof(header) || memcmp(header, "\x7f" "ELF", 4) || header[5] != 1) return 0;
    return header[18] | ((unsigned)header[19] << 8);
}

struct MappedRegion {
    uintptr_t start, end;
    uint64_t offset;
    char permissions[5];
    char path[512];
};

static bool mapping_for(uintptr_t address, size_t length, MappedRegion* result) {
    if (!length || address > UINTPTR_MAX - length) return false;
    FILE* maps = fopen("/proc/self/maps", "r");
    if (!maps) return false;
    char line[1024];
    bool found = false;
    while (fgets(line, sizeof(line), maps)) {
        unsigned long start = 0, end = 0, offset = 0;
        char permissions[5] = {};
        int position = 0;
        if (sscanf(line, "%lx-%lx %4s %lx %*s %*s %n", &start, &end, permissions, &offset, &position) < 4) continue;
        if (address < start || address + length > end) continue;
        char* path = line + position;
        while (*path == ' ') ++path;
        path[strcspn(path, "\r\n")] = 0;
        char* deleted = strstr(path, " (deleted)");
        if (deleted) *deleted = 0;
        result->start = start; result->end = end; result->offset = offset;
        memcpy(result->permissions, permissions, sizeof(permissions));
        snprintf(result->path, sizeof(result->path), "%s", path);
        found = true;
        break;
    }
    fclose(maps);
    return found;
}

static uint64_t little(const unsigned char* bytes, size_t length) {
    uint64_t value = 0;
    for (size_t i = 0; i < length; ++i) value |= (uint64_t)bytes[i] << (i * 8);
    return value;
}

// Only copy a bounded range after confirming it belongs to a readable map.
// The framework mappings under examination remain loaded for this process.
static bool mapped_copy(uintptr_t address, void* destination, size_t length) {
    MappedRegion region;
    if (!mapping_for(address, length, &region) || !strchr(region.permissions, 'r')) return false;
    memcpy(destination, (void*)address, length);
    return true;
}

static bool mapped_elf_proof(JNIEnv* env, uintptr_t header_address, uintptr_t entry, const MappedRegion& entry_map) {
    unsigned char header[64];
    if (!mapped_copy(header_address, header, sizeof(header))) return false;
    if (memcmp(header, "\x7f" "ELF", 4) || header[5] != 1 || (header[4] != 1 && header[4] != 2)) return false;
    unsigned machine = (unsigned)little(header + 18, 2);
    bool wide = header[4] == 2;
    char text[320];
    snprintf(text, sizeof(text), "original.mapped.ELF header=0x%llx class=%u machine=%u", (unsigned long long)header_address, header[4], machine);
    stage(env, text);
    if ((wide && machine != 62) || (!wide && machine != 3)) return false;
    uint64_t ph_offset = little(header + (wide ? 32 : 28), wide ? 8 : 4);
    unsigned ph_size = (unsigned)little(header + (wide ? 54 : 42), 2);
    unsigned ph_count = (unsigned)little(header + (wide ? 56 : 44), 2);
    if (ph_size != (wide ? 56 : 32) || !ph_count || ph_count > 128 || ph_offset > 1024 * 1024 ||
        ph_offset > UINTPTR_MAX - header_address) return false;
    unsigned char program_headers[128 * 56];
    if (!mapped_copy(header_address + ph_offset, program_headers, ph_size * ph_count)) return false;
    uintptr_t bias = 0;
    bool have_bias = false;
    for (unsigned i = 0; i < ph_count; ++i) {
        const unsigned char* ph = program_headers + i * ph_size;
        if (little(ph, 4) != 1) continue; // PT_LOAD
        uint64_t offset = little(ph + (wide ? 8 : 4), wide ? 8 : 4);
        uint64_t address = little(ph + (wide ? 16 : 8), wide ? 8 : 4);
        uint64_t size = little(ph + (wide ? 32 : 16), wide ? 8 : 4);
        if (!offset && size >= sizeof(header) && header_address >= address) {
            bias = header_address - address; have_bias = true; break;
        }
    }
    if (!have_bias) return false;
    for (unsigned i = 0; i < ph_count; ++i) {
        const unsigned char* ph = program_headers + i * ph_size;
        unsigned flags = (unsigned)little(ph + (wide ? 4 : 24), 4);
        if (little(ph, 4) != 1 || !(flags & 1)) continue; // executable PT_LOAD
        uint64_t offset = little(ph + (wide ? 8 : 4), wide ? 8 : 4);
        uint64_t address = little(ph + (wide ? 16 : 8), wide ? 8 : 4);
        uint64_t size = little(ph + (wide ? 32 : 16), wide ? 8 : 4);
        if (address > UINTPTR_MAX - bias) continue;
        uintptr_t start = bias + address;
        if (entry < start || entry - start >= size) continue;
        uint64_t actual_offset = entry_map.offset + (entry - entry_map.start);
        uint64_t expected_offset = offset + (entry - start);
        bool matches = actual_offset == expected_offset;
        snprintf(text, sizeof(text), "original.mapped.PT_LOAD executable=true mapOffsetMatches=%s bias=0x%llx", matches ? "true" : "false", (unsigned long long)bias);
        stage(env, text);
        return matches;
    }
    return false;
}

// NativeBridge can redirect open(path) to an ARM file even when this process's
// original JNI entry belongs to an x86 mapping. Prove ISA from mapped ELF bytes,
// checked against the executable mapping and its file offset, not disk paths.
static bool host_entry(JNIEnv* env, uintptr_t address) {
    MappedRegion entry_map;
    if (!mapping_for(address, 16, &entry_map) || !strchr(entry_map.permissions, 'r') ||
        !strchr(entry_map.permissions, 'x')) return false;
    char text[768];
    snprintf(text, sizeof(text), "original.mapping start=0x%llx offset=0x%llx permissions=%s file=%.500s", (unsigned long long)entry_map.start,
             (unsigned long long)entry_map.offset, entry_map.permissions, entry_map.path);
    stage(env, text);
    unsigned char bytes[16];
    if (!mapped_copy(address, bytes, sizeof(bytes))) return false;
    char encoded[33];
    for (unsigned i = 0; i < sizeof(bytes); ++i) snprintf(encoded + i * 2, 3, "%02x", bytes[i]);
    snprintf(text, sizeof(text), "original.entry.bytes=%s", encoded);
    stage(env, text);
    uintptr_t dl_base = 0;
    Dl_info info = {};
    if (dladdr((void*)address, &info) && info.dli_fbase) {
        dl_base = (uintptr_t)info.dli_fbase;
        snprintf(text, sizeof(text), "original.dladdr base=0x%llx file=%.500s", (unsigned long long)dl_base, info.dli_fname ? info.dli_fname : "");
        stage(env, text);
        if (mapped_elf_proof(env, dl_base, address, entry_map)) return true;
    }
    if (entry_map.start >= entry_map.offset) {
        uintptr_t map_base = entry_map.start - entry_map.offset;
        if (map_base != dl_base && mapped_elf_proof(env, map_base, address, entry_map)) return true;
    }
    return false;
}

static bool equals(JNIEnv* env, jstring value, const char* expected) {
    if (!value) return false;
    const char* chars = env->GetStringUTFChars(value, 0);
    if (!chars) return false;
    bool same = strcmp(chars, expected) == 0;
    env->ReleaseStringUTFChars(value, chars);
    return same;
}

static bool backup_integrity(JNIEnv* env, jfieldID art_field, uintptr_t original_art, uintptr_t original_native, uintptr_t original_quick) {
    if (!backup_art || !backup_method || !backup_declaring_class || backup_art == (void*)original_art) return false;
    uintptr_t value = (uintptr_t)env->GetLongField(backup_method, art_field);
    const uint32_t* header = (const uint32_t*)backup_art;
    bool independent = value == (uintptr_t)backup_art && value != original_art;
    bool identity = header[0] == backup_identity[0] && header[2] == backup_identity[2] && (header[1] & 0x108) == 0x108;
    bool entries = *(uintptr_t*)((char*)backup_art + 16) == original_native &&
                   *(uintptr_t*)((char*)backup_art + 24) == original_quick;
    bool rooted = env->GetObjectRefType(backup_method) == JNIGlobalRefType &&
                  env->GetObjectRefType(backup_declaring_class) == JNIGlobalRefType;
    char text[256];
    snprintf(text, sizeof(text), "backup.integrity independent=%s classAndDex=%s nativeAndQuickPreserved=%s strongRoots=%s",
             independent ? "true" : "false", identity ? "true" : "false", entries ? "true" : "false", rooted ? "true" : "false");
    stage(env, text);
    return independent && identity && entries && rooted;
}

static bool prepare_backup(JNIEnv* env, jclass properties, jmethodID original_method, jobject ordinary_reflected,
                           jfieldID art_field, uintptr_t original_art, uintptr_t original_native, uintptr_t* original_quick) {
    // This experiment is deliberately restricted to the already observed API
    // 31/32, 64-bit ArtMethod layout and an immovable boot-image declaring class.
    // It is not a general ART cloning implementation or a GBox patch.
    if (sizeof(void*) != 8) { stage(env, "STOP backup.requires.64bit.layout"); return false; }
    unsigned char snapshot[32];
    if (!mapped_copy(original_art, snapshot, sizeof(snapshot))) { stage(env, "STOP backup.original.metadata.unreadable"); return false; }
    memcpy(backup_identity, snapshot, sizeof(backup_identity));
    MappedRegion declaring_map;
    if (!mapping_for((uintptr_t)backup_identity[0], 8, &declaring_map) ||
        !strchr(declaring_map.permissions, 'r') || !strstr(declaring_map.path, "boot") || !strstr(declaring_map.path, ".art")) {
        stage(env, "STOP backup.declaring.class.not.verified.boot.image"); return false;
    }
    jclass class_class = env->FindClass("java/lang/Class");
    jmethodID get_loader = env->GetMethodID(class_class, "getClassLoader", "()Ljava/lang/ClassLoader;");
    if (exception(env, "backup.getClassLoader.method") || !get_loader) return false;
    jobject loader = env->CallObjectMethod(properties, get_loader);
    if (exception(env, "backup.getClassLoader.call")) return false;
    // Android 12 returns BootClassLoader for bootstrap classes, unlike the RI's
    // null. Compare to Object's actual loader rather than assuming either form.
    jclass bootstrap_object = env->FindClass("java/lang/Object");
    if (exception(env, "backup.Object.class") || !bootstrap_object) return false;
    jobject bootstrap_loader = env->CallObjectMethod(bootstrap_object, get_loader);
    if (exception(env, "backup.Object.getClassLoader")) return false;
    if (!env->IsSameObject(loader, bootstrap_loader)) {
        stage(env, "STOP backup.declaring.class.has.nonboot.loader"); return false;
    }
    memcpy(original_quick, snapshot + 24, sizeof(*original_quick));
    MappedRegion quick_map;
    if (!mapping_for(*original_quick, 1, &quick_map) || !strchr(quick_map.permissions, 'x')) {
        stage(env, "STOP backup.original.quick.entry.not.executable"); return false;
    }
    jobject fresh = env->ToReflectedMethod(properties, original_method, JNI_TRUE);
    if (exception(env, "backup.ToReflectedMethod") || !fresh || env->IsSameObject(fresh, ordinary_reflected)) {
        stage(env, "STOP backup.reflection.object.not.independent"); return false;
    }
    jclass method_class = env->FindClass("java/lang/reflect/Method");
    method_invoke = env->GetMethodID(method_class, "invoke", "(Ljava/lang/Object;[Ljava/lang/Object;)Ljava/lang/Object;");
    jmethodID set_accessible = env->GetMethodID(method_class, "setAccessible", "(Z)V");
    if (exception(env, "backup.reflection.methods") || !method_invoke || !set_accessible) return false;
    env->CallVoidMethod(fresh, set_accessible, JNI_TRUE);
    if (exception(env, "backup.setAccessible")) return false;
    void* allocated = 0;
    if (posix_memalign(&allocated, 8, sizeof(snapshot)) || !allocated) { stage(env, "FAIL backup.allocate"); return false; }
    memcpy(allocated, snapshot, sizeof(snapshot));
    backup_art = allocated; // Kept until this disposable process terminates.
    backup_method = env->NewGlobalRef(fresh);
    backup_declaring_class = (jclass)env->NewGlobalRef(properties);
    object_class = (jclass)env->NewGlobalRef(bootstrap_object);
    if (exception(env, "backup.global.references") || !backup_method || !backup_declaring_class || !object_class) return false;
    // Only the fresh diagnostic reflection object's pointer is changed. The
    // original method and the runtime's method array are not overwritten.
    env->SetLongField(backup_method, art_field, (jlong)(uintptr_t)backup_art);
    if (exception(env, "backup.set.independent.artMethod")) return false;
    if ((uintptr_t)env->GetLongField(ordinary_reflected, art_field) != original_art) {
        stage(env, "STOP backup.ordinary.method.aliased"); return false;
    }
    stage(env, "PASS backup.boot.class.and.distinct.reflection.object");
    return backup_integrity(env, art_field, original_art, original_native, *original_quick);
}

static jstring invoke_backup(JNIEnv* env, jstring key, jstring fallback) {
    jobjectArray arguments = env->NewObjectArray(2, object_class, 0);
    if (!arguments) return 0;
    env->SetObjectArrayElement(arguments, 0, key);
    env->SetObjectArrayElement(arguments, 1, fallback);
    jstring result = (jstring)env->CallObjectMethod(backup_method, method_invoke, (jobject)0, arguments);
    env->DeleteLocalRef(arguments);
    return result;
}

static jstring replacement(JNIEnv* env, jclass clazz, jstring key, jstring fallback) {
    if (!equals(env, key, test_key)) return fallback ? (jstring)env->NewLocalRef(fallback) : env->NewStringUTF("");
    if (callback_mode == 1) {
        stage(env, "callback.enter.replacement.only");
        return env->NewStringUTF("arm-replacement");
    }
    if (++callback_depth != 1) {
        stage(env, "FAIL backup.recursion.guard");
        --callback_depth;
        return env->NewStringUTF("recursion-blocked");
    }
    stage(env, "callback.before.JNI.backup.Method.invoke");
    jstring value = invoke_backup(env, key, fallback);
    --callback_depth;
    if (env->ExceptionCheck() || !value) return value;
    stage(env, "callback.after.JNI.backup.Method.invoke");
    if (!equals(env, value, "original-default")) {
        stage(env, "FAIL original.callback.value");
        return value;
    }
    return env->NewStringUTF("delegated:original-default");
}

#ifndef CAGE_CRITICAL_PROBE
extern "C" JNIEXPORT void JNICALL
Java_io_github_leexeo_cage_nativebridgeprobe_NativeBridgeProbeActivity_runProbe(JNIEnv* env, jclass clazz, jint sdk) {
    reporter = (jclass)env->NewGlobalRef(clazz);
    record_method = env->GetStaticMethodID(clazz, "record", "(Ljava/lang/String;)V");
    stage(env, "native.enter.arm64");
    if (sdk != 31 && sdk != 32) { stage(env, "STOP diagnostic.scoped.to.Android12"); return; }
    jclass properties = env->FindClass("android/os/SystemProperties");
    if (exception(env, "FindClass SystemProperties") || !properties) return;
    const char* signature = "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;";
    jmethodID method = env->GetStaticMethodID(properties, "native_get", signature);
    if (exception(env, "original.GetStaticMethodID") || !method) return;
    jstring key = env->NewStringUTF(test_key);
    jstring fallback = env->NewStringUTF("original-default");
    stage(env, "baseline.before.call");
    jstring baseline = (jstring)env->CallStaticObjectMethod(properties, method, key, fallback);
    if (exception(env, "baseline.call") || !equals(env, baseline, "original-default")) { stage(env, "FAIL baseline.value"); return; }
    stage(env, "PASS baseline.original.value");
    jobject reflected = env->ToReflectedMethod(properties, method, JNI_TRUE);
    jclass executable = env->FindClass("java/lang/reflect/Executable");
    jfieldID art_field = env->GetFieldID(executable, "artMethod", "J");
    if (exception(env, "Executable.artMethod") || !art_field || !reflected) return;
    uintptr_t art = (uintptr_t)env->GetLongField(reflected, art_field);
    if (exception(env, "read.artMethod") || !art) return;
    uint32_t header[4];
    memcpy(header, (void*)art, sizeof(header));
    if ((header[1] & 0x108) != 0x108) { stage(env, "STOP unexpected.method.flags"); return; }
    // Android12 layout is independently observed in both full GBox tombstones.
    // Read the slot only; this diagnostic never writes raw ArtMethod memory.
    uintptr_t original = *(uintptr_t*)(art + 16);
    char text[300];
    snprintf(text, sizeof(text), "method.metadata flags=0x%x index=0x%x original=0x%llx callback=0x%llx hostExeMachine=%u",
             header[1], header[2], (unsigned long long)original,
             (unsigned long long)(uintptr_t)&replacement, elf_machine("/proc/self/exe"));
    stage(env, text);
    if (!original || !host_entry(env, original)) { stage(env, "STOP original.entry.x86.not.proven"); return; }
    stage(env, "PASS original.entry.is.x86");
    uintptr_t original_quick = 0;
    if (!prepare_backup(env, properties, method, reflected, art_field, art, original, &original_quick)) return;
    stage(env, "backup.before.registration.before.call");
    jstring backup_before = invoke_backup(env, key, fallback);
    if (exception(env, "backup.before.registration.call") || !equals(env, backup_before, "original-default")) {
        stage(env, "FAIL backup.before.registration.value"); return;
    }
    stage(env, "PASS backup.before.registration.call");
    callback_mode = 1;
    JNINativeMethod registration = {const_cast<char*>("native_get"), const_cast<char*>(signature), (void*)&replacement};
    stage(env, "register.before.guest.JNIEnv.RegisterNatives");
    int result = env->RegisterNatives(properties, &registration, 1);
    snprintf(text, sizeof(text), "register.after result=%d", result);
    stage(env, text);
    if (exception(env, "RegisterNatives") || result != JNI_OK) return;
    stage(env, "lookup.before.GetStaticMethodID.after.registration");
    jmethodID after = env->GetStaticMethodID(properties, "native_get", signature);
    if (exception(env, "after.GetStaticMethodID") || !after) return;
    stage(env, "PASS lookup.after.registration");
    uint32_t current_header[4];
    memcpy(current_header, (void*)art, sizeof(current_header));
    // Registration may legitimately update runtime flags or hotness. Check the
    // class, dex identity, and required native/static bits rather than all bytes.
    if (current_header[0] != header[0] || current_header[2] != header[2] ||
        (current_header[1] & 0x108) != 0x108) {
        stage(env, "STOP method.class.or.identity.corrupted"); return;
    }
    snprintf(text, sizeof(text), "method.flags.before=0x%x after=0x%x classAndDexUnchanged=true", header[1], current_header[1]);
    stage(env, text);
    uintptr_t installed = *(uintptr_t*)(art + 16);
    snprintf(text, sizeof(text), "replacement.entry=0x%llx rawArmCallback=%s", (unsigned long long)installed,
             installed == (uintptr_t)&replacement ? "true" : "false");
    stage(env, text);
    if (installed == (uintptr_t)&replacement) { stage(env, "STOP bridge.did.not.wrap.ARM.callback"); return; }
    stage(env, "replacement.only.before.call");
    jstring replaced = (jstring)env->CallStaticObjectMethod(properties, after, key, fallback);
    if (exception(env, "replacement.only.call") || !equals(env, replaced, "arm-replacement")) { stage(env, "FAIL replacement.only.value"); return; }
    stage(env, "PASS replacement.only.call");
    if (!backup_integrity(env, art_field, art, original, original_quick)) { stage(env, "STOP backup.metadata.after.registration"); return; }
    stage(env, "backup.after.registration.before.call");
    jstring backup_after = invoke_backup(env, key, fallback);
    if (exception(env, "backup.after.registration.call") || !equals(env, backup_after, "original-default")) {
        stage(env, "FAIL backup.after.registration.value"); return;
    }
    stage(env, "PASS backup.after.registration.call");
    callback_mode = 2;
    stage(env, "backup.delegate.before.call");
    jstring delegated = (jstring)env->CallStaticObjectMethod(properties, after, key, fallback);
    if (exception(env, "backup.delegate.call") || !equals(env, delegated, "delegated:original-default")) { stage(env, "FAIL backup.delegate.value"); return; }
    stage(env, "PASS backup.delegate.call");
    jclass system = env->FindClass("java/lang/System");
    jmethodID gc = env->GetStaticMethodID(system, "gc", "()V");
    if (exception(env, "System.gc.method") || !gc) return;
    stage(env, "lifetime.before.normal.System.gc");
    env->CallStaticVoidMethod(system, gc);
    if (exception(env, "System.gc.call")) return;
    stage(env, "lifetime.after.normal.System.gc");
    if (!backup_integrity(env, art_field, art, original, original_quick)) { stage(env, "STOP backup.metadata.after.gc"); return; }
    jstring after_gc = (jstring)env->CallStaticObjectMethod(properties, after, key, fallback);
    if (exception(env, "backup.delegate.after.gc") || !equals(env, after_gc, "delegated:original-default")) {
        stage(env, "FAIL backup.delegate.after.gc.value"); return;
    }
    stage(env, "PASS backup.delegate.after.normal.gc");
    stage(env, "PASS all.backup.bridge.stages");
}
#endif
