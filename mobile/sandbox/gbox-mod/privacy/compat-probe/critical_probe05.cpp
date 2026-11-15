#define CAGE_CRITICAL_PROBE 1
#include "native_bridge_probe.cpp"

typedef jint (*CriticalOriginal)();
static CriticalOriginal critical_original;
static unsigned critical_mode;
static unsigned critical_calls;
static const jint replacement_marker = -20261115;
static int native_report = -1;
static JNIEnv* saved_env;
static uintptr_t saved_env_table;

// The special ABI has no JNIEnv/jclass. Keep the callback free of JNI and logs.
static jint critical_replacement() {
    __atomic_add_fetch(&critical_calls, 1, __ATOMIC_RELAXED);
    if (__atomic_load_n(&critical_mode, __ATOMIC_RELAXED) == 1) return replacement_marker;
    return critical_original();
}

static void native_record(const char* text) {
    if (native_report < 0) return;
    write(native_report, text, strlen(text));
    write(native_report, "\n", 1);
    fsync(native_report);
}

extern "C" JNIEXPORT jboolean JNICALL
Java_io_github_leexeo_cage_nativebridgeprobe_NativeBridgeProbeActivity_prepareCritical(
        JNIEnv* env, jclass clazz, jint sdk, jint baseline, jstring report_path) {
    reporter = (jclass)env->NewGlobalRef(clazz);
    record_method = env->GetStaticMethodID(clazz, "record", "(Ljava/lang/String;)V");
    stage(env, "native.enter.arm64.critical.java.caller.variant");
    if (sdk != 31 && sdk != 32) { stage(env, "STOP diagnostic.scoped.to.Android12"); return JNI_FALSE; }
    if (baseline == replacement_marker) { stage(env, "STOP critical.marker.collides.with.baseline"); return JNI_FALSE; }
    const char* path = env->GetStringUTFChars(report_path, nullptr);
    if (!path) return JNI_FALSE;
    native_report = open(path, O_WRONLY | O_APPEND | O_CLOEXEC);
    env->ReleaseStringUTFChars(report_path, path);
    if (native_report < 0) { stage(env, "STOP native.report.open.failed"); return JNI_FALSE; }
    jclass binder = env->FindClass("android/os/Binder");
    if (exception(env, "critical.FindClass Binder") || !binder) return JNI_FALSE;
    jmethodID method = env->GetStaticMethodID(binder, "getCallingUid", "()I");
    if (exception(env, "critical.original.GetStaticMethodID") || !method) return JNI_FALSE;
    jobject reflected = env->ToReflectedMethod(binder, method, JNI_TRUE);
    jclass executable = env->FindClass("java/lang/reflect/Executable");
    jfieldID art_field = env->GetFieldID(executable, "artMethod", "J");
    if (exception(env, "critical.Executable.artMethod") || !art_field || !reflected) return JNI_FALSE;
    uintptr_t art = (uintptr_t)env->GetLongField(reflected, art_field);
    if (exception(env, "critical.read.artMethod") || !art) return JNI_FALSE;
    uint32_t header[4];
    if (!mapped_copy(art, header, sizeof(header))) { stage(env, "STOP critical.metadata.unreadable"); return JNI_FALSE; }
    const uint32_t required = 0x00100108; // critical + native + static
    if ((header[1] & required) != required || (header[1] & 0x00080000)) {
        stage(env, "STOP method.flags.not.CriticalNative"); return JNI_FALSE;
    }
    stage(env, "PASS critical.native.static.flags.confirmed");
    uintptr_t original = 0;
    if (!mapped_copy(art + 16, &original, sizeof(original)) || !original || !host_entry(env, original)) {
        stage(env, "STOP original.entry.x86.not.proven"); return JNI_FALSE;
    }
    stage(env, "PASS original.entry.is.x86");
    critical_original = (CriticalOriginal)original;
    saved_env = env;
    saved_env_table = (uintptr_t)env->functions;
    native_record("critical.raw.original.before.registration.before.call");
    jint raw_value = critical_original();
    // No JNI calls between the raw call and these durable diagnostic writes.
    uintptr_t after_table = 0;
    bool table_same = mapped_copy((uintptr_t)saved_env, &after_table, sizeof(after_table)) && after_table == saved_env_table;
    native_record(raw_value == baseline ? "PASS critical.raw.original.matches.baseline.value.not.logged" : "FAIL critical.raw.original.value.differs");
    native_record(table_same ? "PASS critical.raw.original.env.table.unchanged" : "FAIL critical.raw.original.env.table.changed");
    if (raw_value != baseline || !table_same) return JNI_FALSE;
    if (exception(env, "critical.raw.original.after.call.health")) return JNI_FALSE;
    stage(env, "PASS critical.raw.original.JNI.health");
    __atomic_store_n(&critical_mode, 1, __ATOMIC_RELAXED);
    JNINativeMethod registration = {const_cast<char*>("getCallingUid"), const_cast<char*>("()I"), (void*)&critical_replacement};
    stage(env, "critical.register.before.guest.JNIEnv.RegisterNatives");
    int result = env->RegisterNatives(binder, &registration, 1);
    char text[180];
    snprintf(text, sizeof(text), "critical.register.after result=%d", result);
    stage(env, text);
    if (exception(env, "critical.RegisterNatives") || result != JNI_OK) return JNI_FALSE;
    jmethodID after = env->GetStaticMethodID(binder, "getCallingUid", "()I");
    if (exception(env, "critical.after.GetStaticMethodID") || !after) return JNI_FALSE;
    uint32_t current[4];
    if (!mapped_copy(art, current, sizeof(current)) || current[0] != header[0] || current[2] != header[2] ||
        (current[1] & required) != required) { stage(env, "STOP critical.method.metadata.changed"); return JNI_FALSE; }
    uintptr_t installed = 0;
    if (!mapped_copy(art + 16, &installed, sizeof(installed)) || installed == (uintptr_t)&critical_replacement) {
        stage(env, "STOP critical.bridge.did.not.wrap.callback"); return JNI_FALSE;
    }
    stage(env, "PASS critical.registration.metadata.lookup.wrapped");
    stage(env, "critical.install.returning.to.Java.before.any.replacement.call");
    return JNI_TRUE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_io_github_leexeo_cage_nativebridgeprobe_NativeBridgeProbeActivity_criticalHealthAndMode(
        JNIEnv* env, jclass, jint mode) {
    native_record("critical.separate.ARM.JNI.health.enter");
    uintptr_t current_table = 0;
    bool table_same = mapped_copy((uintptr_t)env, &current_table, sizeof(current_table)) && current_table == saved_env_table;
    bool called = __atomic_load_n(&critical_calls, __ATOMIC_RELAXED) != 0;
    native_record(table_same ? "PASS critical.separate.ARM.JNI.env.table.matches" : "FAIL critical.separate.ARM.JNI.env.table.differs");
    native_record(called ? "PASS critical.callback.counter.nonzero" : "FAIL critical.callback.counter.zero");
    if (!table_same || !called) return JNI_FALSE;
    if (exception(env, "critical.separate.ARM.JNI.health")) return JNI_FALSE;
    stage(env, "PASS critical.separate.ARM.JNI.health");
    __atomic_store_n(&critical_mode, (unsigned)mode, __ATOMIC_RELAXED);
    return JNI_TRUE;
}
