#pragma once
#include "refresh_samples.h"

using RefreshLoaded = void (*)(void*);
uintptr_t refresh_core;
void* refresh_manager;
jclass refresh_scope_class;
jmethodID refresh_scope_method;
pthread_key_t refresh_thread;
bool refresh_thread_ready, refresh_prepared;
pthread_mutex_t refresh_serial = PTHREAD_MUTEX_INITIALIZER;
unsigned java_load_events, java_load_completed, java_load_deferred, java_load_refused;

bool refresh_pointer(uintptr_t rva, uintptr_t* value) {
    if (!readable(refresh_core + rva, sizeof(*value))) return false;
    memcpy(value, reinterpret_cast<void*>(refresh_core + rva), sizeof(*value));
    return true;
}

bool refresh_guard() {
    struct Window { uintptr_t rva; const unsigned char* bytes; size_t size; };
#define REFRESH_WINDOW(name) {kRefresh##name##Rva, kRefresh##name##Code, sizeof(kRefresh##name##Code)}
    const Window windows[] = {REFRESH_WINDOW(CoreGlobal), REFRESH_WINDOW(PostDlopen), REFRESH_WINDOW(PostNewElf),
        REFRESH_WINDOW(ElfManagerRefresh), REFRESH_WINDOW(TaskHookElf), REFRESH_WINDOW(LinkerInLock),
        REFRESH_WINDOW(DlcloseReadLock), REFRESH_WINDOW(DlcloseUnlock), REFRESH_WINDOW(SetPostDlopen)};
#undef REFRESH_WINDOW
    for (size_t index = 0; index < sizeof(windows) / sizeof(windows[0]); ++index) {
        const Window& window = windows[index];
        if (!sample_matches(refresh_core, window.rva, window.bytes, window.size)) {
            stage("load.guard.reject.sample", index); return false;
        }
    }
    for (size_t index = 0; index < sizeof(kRefreshGotTargets) / sizeof(kRefreshGotTargets[0]); ++index) {
        uintptr_t value;
        if (!refresh_pointer(kRefreshGotTargets[index].slot_rva, &value)
            || value != refresh_core + kRefreshGotTargets[index].target_rva) {
            stage("load.guard.reject.got", index); return false;
        }
    }
    uint32_t state[2];
    if (!readable(refresh_core + kRefreshCoreStateRva, sizeof(state))) return false;
    memcpy(state, reinterpret_cast<void*>(refresh_core + kRefreshCoreStateRva), sizeof(state));
    uintptr_t manager, elfs, post, argument;
    if (state[0] != 0 || state[1] != 0
        || !refresh_pointer(kRefreshCoreStateRva + 8, &manager)
        || !refresh_pointer(kRefreshCoreStateRva + 24, &elfs)
        || !refresh_pointer(kRefreshMonitorPostArgumentRva, &argument)
        || !refresh_pointer(kRefreshMonitorPostFunctionRva, &post)
        || !manager || !elfs || !readable(manager, sizeof(void*)) || !readable(elfs, sizeof(void*))
        || argument != manager || post != refresh_core + kRefreshPostDlopenRva
        || (refresh_manager && reinterpret_cast<uintptr_t>(refresh_manager) != manager)) {
        log("load.guard.reject.managerState"); return false;
    }
    refresh_manager = reinterpret_cast<void*>(manager);
    return true;
}

void monitor_status() {
    const uintptr_t slots[] = {0xe2988, 0xe2990, 0xe29a0};
    int statuses[3] = {-1000, -1000, -1000};
    for (size_t index = 0; index < 3; ++index) {
        uintptr_t task;
        if (refresh_pointer(slots[index], &task) && readable(task + 0x58, sizeof(int)))
            memcpy(&statuses[index], reinterpret_cast<void*>(task + 0x58), sizeof(int));
    }
    char message[128];
    snprintf(message, sizeof(message), "load.monitor.status dlopen=%d ext=%d close=%d", statuses[0], statuses[1], statuses[2]);
    log(message);
}

bool refresh_scope(JNIEnv* env) {
    if (!__atomic_load_n(&enabled, __ATOMIC_ACQUIRE)) return false;
    jboolean current = env->CallStaticBooleanMethod(refresh_scope_class, refresh_scope_method);
    if (env->ExceptionCheck()) {
        env->ExceptionClear(); // only our added scope query; original nativeLoad had no exception
        log("load.notify.reject.scopeQuery"); return false;
    }
    return current == JNI_TRUE;
}

void after_java_load(JNIEnv* env, jstring) {
    if (!__atomic_load_n(&enabled, __ATOMIC_ACQUIRE)) return;
    __atomic_fetch_add(&java_load_events, 1u, __ATOMIC_RELAXED);
    if (pthread_getspecific(refresh_thread)) {
        pthread_setspecific(refresh_thread, reinterpret_cast<void*>(2));
        __atomic_fetch_add(&java_load_deferred, 1u, __ATOMIC_RELAXED);
        log("load.notify.deferred.sameThread innerReturnNotCovered=true");
        return;
    }
    // Every other thread waits for its own successful-load event to be handled.
    pthread_mutex_lock(&refresh_serial);
    bool completed = false;
    if (pthread_setspecific(refresh_thread, reinterpret_cast<void*>(1)) == 0) {
        do {
            completed = false;
            if (pthread_setspecific(refresh_thread, reinterpret_cast<void*>(1))) break;
            if (!refresh_scope(env) || !refresh_guard()) break;
            using InLinkerLock = bool (*)();
            if (reinterpret_cast<InLinkerLock>(refresh_core + kRefreshLinkerInLockRva)()) {
                log("load.notify.reject.linkerLocked"); break;
            }
            log("load.notify.before.originalRefresh");
            reinterpret_cast<RefreshLoaded>(refresh_core + kRefreshPostDlopenRva)(refresh_manager);
            log("load.notify.after.originalRefresh");
            completed = true;
            // Drain real same-thread events; this is not a timer or polling refresh.
        } while (pthread_getspecific(refresh_thread) == reinterpret_cast<void*>(2));
    }
    pthread_setspecific(refresh_thread, nullptr);
    pthread_mutex_unlock(&refresh_serial);
    if (completed) __atomic_fetch_add(&java_load_completed, 1u, __ATOMIC_RELAXED);
    else __atomic_fetch_add(&java_load_refused, 1u, __ATOMIC_RELAXED);
    char message[192];
    snprintf(message, sizeof(message), "load.notify.result completed=%d events=%u completedEvents=%u deferred=%u refused=%u allowed=%u",
        completed, __atomic_load_n(&java_load_events, __ATOMIC_RELAXED), __atomic_load_n(&java_load_completed, __ATOMIC_RELAXED),
        __atomic_load_n(&java_load_deferred, __ATOMIC_RELAXED), __atomic_load_n(&java_load_refused, __ATOMIC_RELAXED),
        __atomic_load_n(&filter_decisions[3], __ATOMIC_RELAXED));
    log(message);
}

bool prepare_load_refresh(JNIEnv* env, uintptr_t core) {
    if (refresh_prepared) return refresh_core == core && refresh_guard();
    refresh_core = core;
    if (!refresh_guard()) return 0;
    monitor_status();
    jclass local = env->FindClass("io/github/leexeo/cage/privacy/GuestPrivacy");
    if (!local || env->ExceptionCheck()) return 0;
    refresh_scope_class = static_cast<jclass>(env->NewGlobalRef(local));
    env->DeleteLocalRef(local);
    if (!refresh_scope_class || env->ExceptionCheck()) return 0;
    refresh_scope_method = env->GetStaticMethodID(refresh_scope_class, "isNativeScopeCurrent", "()Z");
    if (!refresh_scope_method || env->ExceptionCheck()) return 0;
    if (!refresh_thread_ready) {
        if (pthread_key_create(&refresh_thread, nullptr)) return 0;
        refresh_thread_ready = true;
    }
    refresh_prepared = true;
    log("load.refresh.prepared.hostInstallerPending=true");
    log("load.boundary constructors=false jniOnLoad=false pureNative=false concurrentBeforeReturn=false");
    return true;
}
