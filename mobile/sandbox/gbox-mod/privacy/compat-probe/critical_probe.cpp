#define CAGE_CRITICAL_PROBE 1
#include "native_bridge_probe.cpp"

typedef jint (*CriticalOriginal)();
static CriticalOriginal critical_original;
static unsigned critical_mode;
static unsigned critical_calls;
static const jint replacement_marker = -20261115;

// CriticalNative ABI: no JNIEnv, no jclass, no JNI calls or logging. The probe
// records stages around calls from its ordinary JNI control method instead.
static jint critical_replacement() {
    __atomic_add_fetch(&critical_calls, 1, __ATOMIC_RELAXED);
    if (__atomic_load_n(&critical_mode, __ATOMIC_RELAXED) == 1) return replacement_marker;
    return critical_original();
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_leexeo_cage_nativebridgeprobe_NativeBridgeProbeActivity_runProbe(JNIEnv* env, jclass clazz, jint sdk) {
    reporter = (jclass)env->NewGlobalRef(clazz);
    record_method = env->GetStaticMethodID(clazz, "record", "(Ljava/lang/String;)V");
    stage(env, "native.enter.arm64.critical.variant");
    if (sdk != 31 && sdk != 32) { stage(env, "STOP diagnostic.scoped.to.Android12"); return; }
    jclass binder = env->FindClass("android/os/Binder");
    if (exception(env, "critical.FindClass Binder") || !binder) return;
    jmethodID method = env->GetStaticMethodID(binder, "getCallingUid", "()I");
    if (exception(env, "critical.original.GetStaticMethodID") || !method) return;
    stage(env, "critical.baseline.before.call");
    jint baseline = env->CallStaticIntMethod(binder, method);
    if (exception(env, "critical.baseline.call")) return;
    if (baseline == replacement_marker) { stage(env, "STOP critical.marker.collides.with.baseline"); return; }
    stage(env, "PASS critical.baseline.call.value.not.logged");
    jobject reflected = env->ToReflectedMethod(binder, method, JNI_TRUE);
    jclass executable = env->FindClass("java/lang/reflect/Executable");
    jfieldID art_field = env->GetFieldID(executable, "artMethod", "J");
    if (exception(env, "critical.Executable.artMethod") || !art_field || !reflected) return;
    uintptr_t art = (uintptr_t)env->GetLongField(reflected, art_field);
    if (exception(env, "critical.read.artMethod") || !art) return;
    uint32_t header[4];
    if (!mapped_copy(art, header, sizeof(header))) { stage(env, "STOP critical.metadata.unreadable"); return; }
    // Android 12 libdexfile/dex/modifiers.h: kAccCriticalNative=0x00100000.
    const uint32_t required = 0x00100108; // critical + native + static
    if ((header[1] & required) != required || (header[1] & 0x00080000)) {
        stage(env, "STOP method.flags.not.CriticalNative"); return;
    }
    stage(env, "PASS critical.native.static.flags.confirmed");
    uintptr_t original = 0;
    if (!mapped_copy(art + 16, &original, sizeof(original)) || !original || !host_entry(env, original)) {
        stage(env, "STOP original.entry.x86.not.proven"); return;
    }
    stage(env, "PASS original.entry.is.x86");
    critical_original = (CriticalOriginal)original;
    __atomic_store_n(&critical_mode, 1, __ATOMIC_RELAXED);
    JNINativeMethod registration = {const_cast<char*>("getCallingUid"), const_cast<char*>("()I"), (void*)&critical_replacement};
    stage(env, "critical.register.before.guest.JNIEnv.RegisterNatives");
    int result = env->RegisterNatives(binder, &registration, 1);
    char text[220];
    snprintf(text, sizeof(text), "critical.register.after result=%d", result);
    stage(env, text);
    if (exception(env, "critical.RegisterNatives") || result != JNI_OK) return;
    stage(env, "critical.lookup.before.GetStaticMethodID");
    jmethodID after = env->GetStaticMethodID(binder, "getCallingUid", "()I");
    if (exception(env, "critical.after.GetStaticMethodID") || !after) return;
    stage(env, "PASS critical.lookup.after.registration");
    uint32_t current[4];
    if (!mapped_copy(art, current, sizeof(current)) || current[0] != header[0] || current[2] != header[2] ||
        (current[1] & required) != required) { stage(env, "STOP critical.method.metadata.changed"); return; }
    stage(env, "PASS critical.class.dex.and.flags.preserved");
    uintptr_t installed = 0;
    if (!mapped_copy(art + 16, &installed, sizeof(installed)) || installed == (uintptr_t)&critical_replacement) {
        stage(env, "STOP critical.bridge.did.not.wrap.callback"); return;
    }
    stage(env, "PASS critical.callback.wrapped");
    unsigned before_count = __atomic_load_n(&critical_calls, __ATOMIC_RELAXED);
    stage(env, "critical.replacement.only.before.call");
    jint replaced = env->CallStaticIntMethod(binder, after);
    if (exception(env, "critical.replacement.only.call") || replaced != replacement_marker ||
        __atomic_load_n(&critical_calls, __ATOMIC_RELAXED) == before_count) {
        stage(env, "FAIL critical.replacement.only.value"); return;
    }
    stage(env, "PASS critical.replacement.only.call");
    __atomic_store_n(&critical_mode, 2, __ATOMIC_RELAXED);
    before_count = __atomic_load_n(&critical_calls, __ATOMIC_RELAXED);
    stage(env, "critical.direct.original.before.call");
    jint delegated = env->CallStaticIntMethod(binder, after);
    if (exception(env, "critical.direct.original.call") || delegated != baseline ||
        __atomic_load_n(&critical_calls, __ATOMIC_RELAXED) == before_count) {
        stage(env, "FAIL critical.direct.original.value.differs"); return;
    }
    stage(env, "PASS critical.direct.original.matches.baseline.value.not.logged");
    stage(env, "PASS all.critical.bridge.stages");
}
