/* Loopback transport for the two Cage test APKs' own system curl children.
 * The next hop is always the guest's private Unix socket. The test shell has
 * no INTERNET permission. TLS and the SOCKS conversation stay inside curl. */
#include <arpa/inet.h>
#include <android/log.h>
#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

static int (*system_socket)(int, int, int);
static int (*system_connect)(int, const struct sockaddr *, socklen_t);
static pthread_once_t initialized = PTHREAD_ONCE_INIT;
static struct sockaddr_un endpoint;

static void initialize(void) {
    system_socket = dlsym(RTLD_NEXT, "socket");
    system_connect = dlsym(RTLD_NEXT, "connect");

    char exe[128];
    ssize_t length = readlink("/proc/self/exe", exe, sizeof(exe));
    static const char curl[] = "/system/bin/curl";
    if (length != sizeof(curl) - 1 || memcmp(exe, curl, sizeof(curl) - 1) != 0)
        return;

    /* The package startup sets this only for the two pre-existing probes.
     * Do not accept an arbitrary path, address, or forwarding destination. */
    const char *path = getenv("CAGE_CURL4_LOCAL");
    static const char plain[] = "/data/user/0/top.niunaijun.cagetest/cache/plainnet-egress.sock";
    static const char stable[] = "/data/user/0/top.niunaijun.cagetest/cache/stablenet-egress.sock";
    if (path == NULL || (strcmp(path, plain) != 0 && strcmp(path, stable) != 0))
        return;
    endpoint.sun_family = AF_UNIX;
    memcpy(endpoint.sun_path, path, strlen(path) + 1);
}

int socket(int domain, int type, int protocol) {
    pthread_once(&initialized, initialize);
    if (!system_socket) { errno = ENOSYS; return -1; }
    if (endpoint.sun_family != AF_UNIX || domain != AF_INET)
        return system_socket(domain, type, protocol);
    if ((type & ~(SOCK_CLOEXEC | SOCK_NONBLOCK)) != SOCK_STREAM ||
            (protocol != 0 && protocol != IPPROTO_TCP)) {
        errno = EACCES;
        return -1;
    }
    return system_socket(AF_UNIX, type, 0);
}

int connect(int fd, const struct sockaddr *address, socklen_t length) {
    pthread_once(&initialized, initialize);
    if (!system_connect) { errno = ENOSYS; return -1; }
    if (endpoint.sun_family != AF_UNIX || address == NULL ||
            length < sizeof(sa_family_t) || address->sa_family != AF_INET)
        return system_connect(fd, address, length);
    if (length < sizeof(struct sockaddr_in)) { errno = EINVAL; return -1; }
    struct sockaddr_in ipv4;
    memcpy(&ipv4, address, sizeof(ipv4));
    if (ipv4.sin_addr.s_addr != htonl(INADDR_LOOPBACK) || ipv4.sin_port != htons(38491)) {
        errno = EACCES;
        return -1;
    }
    socklen_t size = (socklen_t)(offsetof(struct sockaddr_un, sun_path) + strlen(endpoint.sun_path) + 1);
    int result = system_connect(fd, (const struct sockaddr *)&endpoint, size);
    int saved_errno = errno;
    /* Android logging uses a Unix socket itself. Initialization has completed
     * here, and the log socket takes the unchanged AF_UNIX path above. */
    __android_log_print(ANDROID_LOG_INFO, "CageCurl4", "original executable=/system/bin/curl peerPid=%ld",
                        (long)getpid());
    errno = saved_errno;
    return result;
}
