#include "runtime_api.h"
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#if !defined(__aarch64__)
#error "Asset-path diagnostic must exercise the ARM64 guest libc"
#endif

extern "C" JNIEXPORT jint JNICALL
Java_io_github_leexeo_cage_gbox_AssetPathTrace_readApkPrefix(JNIEnv* env, jclass, jstring value) {
    if (!cage_compat_diagnostic_ready() || !value) return -10001;
    const char* path = env->GetStringUTFChars(value, nullptr);
    if (!path) return -10002;
    int descriptor = open(path, O_RDONLY | O_CLOEXEC);
    int status = descriptor >= 0 ? 1 : -(errno ? errno : EIO);
    env->ReleaseStringUTFChars(value, path);
    if (descriptor < 0) return status;
    unsigned char header[4] = {};
    size_t count = 0;
    while (count < sizeof(header)) {
        ssize_t received = read(descriptor, header + count, sizeof(header) - count);
        if (received < 0 && errno == EINTR) continue;
        if (received <= 0) break;
        count += static_cast<size_t>(received);
    }
    close(descriptor);
    if (count == sizeof(header)) {
        status |= 2;
        if (header[0] == 0x50 && header[1] == 0x4b && header[2] == 3 && header[3] == 4) status |= 4;
    }
    return status;
}
