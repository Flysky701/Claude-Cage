#include <jni.h>

#if !defined(__aarch64__)
#error The sentinel must load through the ARM application's original loader.
#endif
#ifndef CAGE_SENTINEL_ID
#error Set a unique ID from 1 through 4 for each fresh library.
#endif

extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
    JNIEnv* env = nullptr;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK || !env)
        return JNI_ERR;
    jclass sentinel = env->FindClass("io/github/leexeo/cage/hostloadprobe/Sentinel");
    if (!sentinel || env->ExceptionCheck()) return JNI_ERR;
    jmethodID mark = env->GetStaticMethodID(sentinel, "mark", "(I)Z");
    if (!mark || env->ExceptionCheck()) return JNI_ERR;
    if (!env->CallStaticBooleanMethod(sentinel, mark, CAGE_SENTINEL_ID) || env->ExceptionCheck())
        return JNI_ERR;
#if defined(CAGE_SENTINEL_NESTED)
    jmethodID nested = env->GetStaticMethodID(sentinel, "loadNested", "()V");
    if (!nested || env->ExceptionCheck()) return JNI_ERR;
    env->CallStaticVoidMethod(sentinel, nested);
    if (env->ExceptionCheck()) return JNI_ERR;
#endif
    env->DeleteLocalRef(sentinel);
    return JNI_VERSION_1_6;
}
