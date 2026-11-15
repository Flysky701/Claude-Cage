#include <jni.h>
#include <stdint.h>
#include <android/log.h>

#if !defined(__aarch64__)
#error This library must exercise the ARM translation side.
#endif

namespace {
unsigned callbacks, classes, exceptions;
unsigned exits, filenames, found_classes, found_methods, invoked_masks, owners;
unsigned last_error_stage, last_error_kind;
int last_seen = -1;

// Called only for an exception introduced by this diagnostic callback.
// Fixed kind codes avoid logging arbitrary exception messages or paths.
unsigned consume_exception(JNIEnv* env) {
    jthrowable error = env->ExceptionOccurred();
    env->ExceptionClear();
    if (!error) return 0;
    const char* kinds[] = {"java/lang/NoClassDefFoundError", "java/lang/ClassNotFoundException",
        "java/lang/NoSuchMethodError"};
    unsigned kind = 4;
    for (unsigned index = 0; index < 3; ++index) {
        jclass type = env->FindClass(kinds[index]);
        if (!type || env->ExceptionCheck()) {
            env->ExceptionClear(); kind = 5; break;
        }
        bool matches = env->IsInstanceOf(error, type);
        env->DeleteLocalRef(type);
        if (matches) { kind = index + 1; break; }
    }
    env->DeleteLocalRef(error);
    return kind;
}
}

extern "C" JNIEXPORT jint JNICALL
Java_io_github_leexeo_cage_hostloadprobe_ArmBridge_health(JNIEnv* env, jclass) {
    return env->ExceptionCheck() ? 0 : 0x43414745;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_leexeo_cage_hostloadprobe_ArmBridge_afterNativeLoad(JNIEnv* env, jclass owner, jstring filename) {
    __atomic_fetch_add(&callbacks, 1u, __ATOMIC_RELAXED);
    __android_log_print(ANDROID_LOG_INFO, "CageHostLoadProbe", "arm.callback.enter");
    if (filename) __atomic_fetch_add(&filenames, 1u, __ATOMIC_RELAXED);
    if (owner) __atomic_fetch_add(&owners, 1u, __ATOMIC_RELAXED);
    unsigned error_stage = env->ExceptionCheck() ? 4 : 0;
    jclass sentinel = error_stage ? nullptr : env->FindClass("io/github/leexeo/cage/hostloadprobe/Sentinel");
    if (!error_stage && env->ExceptionCheck()) error_stage = 1;
    bool class_ok = sentinel && !error_stage;
    if (class_ok) __atomic_fetch_add(&found_classes, 1u, __ATOMIC_RELAXED);
    jmethodID mask = class_ok ? env->GetStaticMethodID(sentinel, "seenMask", "()I") : nullptr;
    if (!error_stage && env->ExceptionCheck()) error_stage = 2;
    bool method_ok = mask && !error_stage;
    if (method_ok) __atomic_fetch_add(&found_methods, 1u, __ATOMIC_RELAXED);
    jint seen = method_ok ? env->CallStaticIntMethod(sentinel, mask) : 0;
    if (!error_stage && env->ExceptionCheck()) error_stage = 3;
    bool call_ok = method_ok && !error_stage;
    if (call_ok) __atomic_fetch_add(&invoked_masks, 1u, __ATOMIC_RELAXED);
    if (call_ok && filename && (seen & 1))
        __atomic_fetch_add(&classes, 1u, __ATOMIC_RELAXED);
    unsigned error_kind = 0;
    if (env->ExceptionCheck()) {
        // Record an added observer failure; the original load had succeeded.
        error_kind = consume_exception(env);
        __atomic_fetch_add(&exceptions, 1u, __ATOMIC_RELAXED);
    }
    if (sentinel) env->DeleteLocalRef(sentinel);
    __atomic_store_n(&last_error_stage, error_stage, __ATOMIC_RELAXED);
    __atomic_store_n(&last_error_kind, error_kind, __ATOMIC_RELAXED);
    __atomic_store_n(&last_seen, call_ok ? seen : -1, __ATOMIC_RELAXED);
    __atomic_fetch_add(&exits, 1u, __ATOMIC_RELAXED);
    __android_log_print(ANDROID_LOG_INFO, "CageHostLoadProbe",
        "arm.callback.exit class=%d method=%d call=%d filename=%d seen=%d errorStage=%u errorKind=%u",
        class_ok, method_ok, call_ok, filename != nullptr, call_ok ? seen : -1, error_stage, error_kind);
}

extern "C" JNIEXPORT jlongArray JNICALL
Java_io_github_leexeo_cage_hostloadprobe_ArmBridge_state(JNIEnv* env, jclass) {
    jlong values[] = {__atomic_load_n(&callbacks, __ATOMIC_RELAXED),
        __atomic_load_n(&classes, __ATOMIC_RELAXED), __atomic_load_n(&exceptions, __ATOMIC_RELAXED)};
    jlongArray result = env->NewLongArray(3);
    if (result) env->SetLongArrayRegion(result, 0, 3, values);
    return result;
}

extern "C" JNIEXPORT jlongArray JNICALL
Java_io_github_leexeo_cage_hostloadprobe_ArmBridge_details(JNIEnv* env, jclass) {
#define READ(value) __atomic_load_n(&value, __ATOMIC_RELAXED)
    jlong values[] = {READ(callbacks), READ(exits), READ(filenames), READ(found_classes),
        READ(found_methods), READ(invoked_masks), READ(classes), READ(exceptions),
        READ(last_error_stage), READ(last_error_kind), READ(last_seen), READ(owners)};
#undef READ
    jlongArray result = env->NewLongArray(12);
    if (result) env->SetLongArrayRegion(result, 0, 12, values);
    return result;
}

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM*, void*) { return JNI_VERSION_1_6; }
