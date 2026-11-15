#pragma once
#include <jni.h>
#include <stdint.h>

extern "C" {
bool cage_compat_prepare(JNIEnv* env, JavaVM* vm, uintptr_t core_base);
bool cage_compat_hook(JNIEnv* env, jclass target, const char* name, const char* signature,
                      bool is_static, void** original_slot, void* replacement);
void* cage_compat_get_original(jmethodID method);
bool cage_compat_verify(JNIEnv* env);
bool cage_compat_diagnostic_ready();
}
