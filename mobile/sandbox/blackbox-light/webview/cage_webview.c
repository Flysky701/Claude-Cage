/* Confined to known Chromium modules' imported socket functions. No libc/global hooks. */
#define _GNU_SOURCE
#include <android/log.h>
#include <arpa/inet.h>
#include <elf.h>
#include <errno.h>
#include <jni.h>
#include <limits.h>
#include <link.h>
#include <netinet/tcp.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

#if !defined(__aarch64__)
#error This module currently supports Android arm64 only.
#endif
#ifndef DT_ANDROID_RELA
#define DT_ANDROID_RELA 0x60000011
#define DT_ANDROID_RELASZ 0x60000012
#endif
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "CageWebViewNative", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "CageWebViewNative", __VA_ARGS__)
#define TRACKED 256
#define MAX_PATCHES 256
#define MAX_MODULES 8

struct flow { int fd; dev_t dev; ino_t ino; int nodelay; };
static struct flow flows[TRACKED];
static pthread_mutex_t flow_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t install_lock = PTHREAD_MUTEX_INITIALIZER;
static bool flow_table_initialized;
static bool installed;
static int ready;
static char endpoint[sizeof(((struct sockaddr_un *)0)->sun_path)];
static unsigned long created, connected, denied, closed, option_adapted;
static unsigned int module_count, patch_count;

static void count(unsigned long *value) { __atomic_add_fetch(value, 1, __ATOMIC_RELAXED); }
static unsigned long read_count(unsigned long *value) { return __atomic_load_n(value, __ATOMIC_RELAXED); }

/* The hooks call this DSO's untouched libc imports, never a function pointer read from a target. */
static int flow_index_locked(int fd) {
    for (int i = 0; i < TRACKED; i++) {
        if (flows[i].fd != fd) continue;
        struct stat info;
        if (fstat(fd, &info) == 0 && info.st_dev == flows[i].dev && info.st_ino == flows[i].ino) return i;
        flows[i].fd = -1;  /* Another component may have closed/reused this descriptor. */
        return -1;
    }
    return -1;
}

static bool is_flow(int fd) {
    pthread_mutex_lock(&flow_lock);
    bool result = flow_index_locked(fd) >= 0;
    pthread_mutex_unlock(&flow_lock);
    return result;
}

static int route_socket(int domain, int type, int protocol) {
    if (domain != AF_INET && domain != AF_INET6) return socket(domain, type, protocol);
    if (!__atomic_load_n(&ready, __ATOMIC_ACQUIRE) || domain != AF_INET ||
            (type & ~(SOCK_NONBLOCK | SOCK_CLOEXEC)) != SOCK_STREAM ||
            (protocol != 0 && protocol != IPPROTO_TCP)) {
        count(&denied); errno = EACCES; return -1;
    }
    int fd = socket(AF_UNIX, type, 0);
    if (fd < 0) return fd;
    struct stat info;
    if (fstat(fd, &info) != 0) { int saved = errno; close(fd); errno = saved; return -1; }
    pthread_mutex_lock(&flow_lock);
    int slot = -1;
    for (int i = 0; i < TRACKED; i++) if (flows[i].fd == -1) { slot = i; break; }
    if (slot >= 0) flows[slot] = (struct flow){fd, info.st_dev, info.st_ino, 0};
    pthread_mutex_unlock(&flow_lock);
    if (slot < 0) { close(fd); errno = EMFILE; return -1; }
    count(&created);
    return fd;
}

static int route_connect(int fd, const struct sockaddr *address, socklen_t length) {
    if (!is_flow(fd)) {
        if (address != NULL && length >= sizeof(sa_family_t) &&
                (address->sa_family == AF_INET || address->sa_family == AF_INET6)) {
            count(&denied); errno = EACCES; return -1;
        }
        return connect(fd, address, length);
    }
    if (!__atomic_load_n(&ready, __ATOMIC_ACQUIRE) || address == NULL ||
            length < sizeof(struct sockaddr_in) || length > sizeof(struct sockaddr_storage)) {
        count(&denied); errno = EACCES; return -1;
    }
    struct sockaddr_in ip;
    memcpy(&ip, address, sizeof(ip));
    if (ip.sin_family != AF_INET || ip.sin_addr.s_addr != htonl(INADDR_LOOPBACK) || ip.sin_port != htons(38491)) {
        count(&denied); errno = EACCES; return -1;
    }
    struct sockaddr_un local = {.sun_family = AF_UNIX};
    size_t size = strlen(endpoint);
    memcpy(local.sun_path, endpoint, size + 1);
    int result = connect(fd, (const struct sockaddr *)&local,
                         (socklen_t)(__builtin_offsetof(struct sockaddr_un, sun_path) + size + 1));
    int saved = errno;
    if (result == 0 || (result < 0 && saved == EINPROGRESS)) count(&connected);
    unsigned long total = read_count(&connected);
    if (total < 8 || result < 0) LOGI("proxy connect fd=%d result=%d errno=%d", fd, result, result < 0 ? saved : 0);
    errno = saved;
    return result;
}

static int integer_option(const void *value, socklen_t size, int *out) {
    if (value == NULL || size != sizeof(int)) { errno = EINVAL; return -1; }
    memcpy(out, value, sizeof(int));
    return 0;
}

static int route_setsockopt(int fd, int level, int option, const void *value, socklen_t size) {
    if (!is_flow(fd)) return setsockopt(fd, level, option, value, size);
    if (level == IPPROTO_TCP) {
        int setting;
        if (integer_option(value, size, &setting) != 0) return -1;
        if (option == TCP_NODELAY && (setting == 0 || setting == 1)) {
            pthread_mutex_lock(&flow_lock);
            int index = flow_index_locked(fd);
            if (index >= 0) flows[index].nodelay = setting;
            pthread_mutex_unlock(&flow_lock);
            count(&option_adapted);
            return 0;
        }
        if ((option == TCP_KEEPIDLE || option == TCP_KEEPINTVL || option == TCP_KEEPCNT) && setting > 0) {
            count(&option_adapted); return 0;
        }
        errno = ENOPROTOOPT; return -1;
    }
    if (level == IPPROTO_IP && option == IP_TOS) {
        int setting;
        if (integer_option(value, size, &setting) != 0 || setting < 0 || setting > 255) {
            errno = EINVAL; return -1;
        }
        count(&option_adapted); return 0;
    }
    return setsockopt(fd, level, option, value, size);
}

static int return_integer(void *value, socklen_t *size, int result) {
    if (value == NULL || size == NULL) { errno = EFAULT; return -1; }
    size_t copy = *size < sizeof(result) ? *size : sizeof(result);
    memcpy(value, &result, copy);
    *size = sizeof(result);
    return 0;
}

static int route_getsockopt(int fd, int level, int option, void *value, socklen_t *size) {
    if (!is_flow(fd)) return getsockopt(fd, level, option, value, size);
    if (level == IPPROTO_TCP && option == TCP_NODELAY) {
        pthread_mutex_lock(&flow_lock);
        int index = flow_index_locked(fd);
        int setting = index >= 0 ? flows[index].nodelay : 0;
        pthread_mutex_unlock(&flow_lock);
        return return_integer(value, size, setting);
    }
#ifdef SO_DOMAIN
    if (level == SOL_SOCKET && option == SO_DOMAIN) return return_integer(value, size, AF_INET);
#endif
#ifdef SO_PROTOCOL
    if (level == SOL_SOCKET && option == SO_PROTOCOL) return return_integer(value, size, IPPROTO_TCP);
#endif
    return getsockopt(fd, level, option, value, size);  /* Includes real SO_ERROR for asynchronous connect. */
}

static int ip_name(int fd, struct sockaddr *address, socklen_t *size, bool peer) {
    if (!is_flow(fd)) return peer ? getpeername(fd, address, size) : getsockname(fd, address, size);
    if (address == NULL || size == NULL) { errno = EFAULT; return -1; }
    struct sockaddr_un check;
    socklen_t check_size = sizeof(check);
    int result = peer ? getpeername(fd, (struct sockaddr *)&check, &check_size)
                      : getsockname(fd, (struct sockaddr *)&check, &check_size);
    if (result != 0) return result;
    struct sockaddr_in ip = {.sin_family = AF_INET, .sin_port = peer ? htons(38491) : 0,
                             .sin_addr = {.s_addr = htonl(INADDR_LOOPBACK)}};
    size_t copy = *size < sizeof(ip) ? *size : sizeof(ip);
    memcpy(address, &ip, copy);
    *size = sizeof(ip);
    return 0;
}

static int route_getsockname(int fd, struct sockaddr *address, socklen_t *size) { return ip_name(fd, address, size, false); }
static int route_getpeername(int fd, struct sockaddr *address, socklen_t *size) { return ip_name(fd, address, size, true); }

static int route_close(int fd) {
    pthread_mutex_lock(&flow_lock);
    int index = flow_index_locked(fd);
    if (index >= 0) flows[index].fd = -1;
    pthread_mutex_unlock(&flow_lock);
    if (index >= 0) count(&closed);
    return close(fd);
}

struct import { const char *name; void *hook; };
static const struct import imports[] = {
    {"socket", (void *)route_socket}, {"connect", (void *)route_connect},
    {"setsockopt", (void *)route_setsockopt}, {"getsockopt", (void *)route_getsockopt},
    {"getsockname", (void *)route_getsockname}, {"getpeername", (void *)route_getpeername},
    {"close", (void *)route_close}
};
#define IMPORTS (sizeof(imports) / sizeof(imports[0]))
struct patch { void **slot; void *hook; void *previous; int protection; };
struct plan { struct patch items[MAX_PATCHES]; size_t count; unsigned int found[IMPORTS]; int error; unsigned int modules; };
struct image { const struct dl_phdr_info *info; const ElfW(Sym) *symbols; const char *strings; size_t string_size; };

static bool range(const struct image *image, uintptr_t address, size_t size, unsigned flags) {
    if (size > UINTPTR_MAX - address) return false;
    for (size_t i = 0; i < image->info->dlpi_phnum; i++) {
        const ElfW(Phdr) *header = &image->info->dlpi_phdr[i];
        if (header->p_type != PT_LOAD || (header->p_flags & flags) != flags) continue;
        if (header->p_vaddr > UINTPTR_MAX - image->info->dlpi_addr) continue;
        uintptr_t start = image->info->dlpi_addr + header->p_vaddr;
        if (header->p_memsz > UINTPTR_MAX - start) continue;
        if (address >= start && address + size <= start + header->p_memsz) return true;
    }
    return false;
}

static uintptr_t pointer(const struct image *image, ElfW(Addr) value, size_t size) {
    if (range(image, (uintptr_t)value, size, PF_R)) return (uintptr_t)value;
    if (value > UINTPTR_MAX - image->info->dlpi_addr) return 0;
    uintptr_t adjusted = image->info->dlpi_addr + value;
    return range(image, adjusted, size, PF_R) ? adjusted : 0;
}

static int slot_protection(const struct image *image, uintptr_t address, uintptr_t page_size) {
    int protection = -1;
    for (size_t i = 0; i < image->info->dlpi_phnum; i++) {
        const ElfW(Phdr) *header = &image->info->dlpi_phdr[i];
        if (header->p_vaddr > UINTPTR_MAX - image->info->dlpi_addr) return -1;
        uintptr_t start = image->info->dlpi_addr + header->p_vaddr;
        if (header->p_memsz > UINTPTR_MAX - start) return -1;
        uintptr_t end = start + header->p_memsz;
        if (header->p_type == PT_LOAD && address >= start && address < end) {
            if (header->p_flags & PF_X) return -1;  /* Never make code writable. */
            protection = PROT_READ | ((header->p_flags & PF_W) ? PROT_WRITE : 0);
        }
    }
    for (size_t i = 0; i < image->info->dlpi_phnum; i++) {
        const ElfW(Phdr) *header = &image->info->dlpi_phdr[i];
        if (header->p_type != PT_GNU_RELRO) continue;
        uintptr_t start = image->info->dlpi_addr + header->p_vaddr;
        uintptr_t end = start + header->p_memsz;
        if ((address & ~(page_size - 1)) >= (start & ~(page_size - 1)) && address < end)
            protection &= ~PROT_WRITE;
    }
    return protection;
}

static bool relocation(struct plan *plan, const struct image *image, ElfW(Addr) offset, ElfW(Xword) info) {
    size_t index = ELF64_R_SYM(info);
    if (index == 0) return true;
    if (index > (UINTPTR_MAX - (uintptr_t)image->symbols) / sizeof(ElfW(Sym))) return false;
    uintptr_t address = (uintptr_t)image->symbols + index * sizeof(ElfW(Sym));
    if (!range(image, address, sizeof(ElfW(Sym)), PF_R)) return false;
    const ElfW(Sym) *symbol = (const ElfW(Sym) *)address;
    if (symbol->st_name >= image->string_size) return false;
    const char *name = image->strings + symbol->st_name;
    if (memchr(name, '\0', image->string_size - symbol->st_name) == NULL) return false;
    for (size_t i = 0; i < IMPORTS; i++) {
        if (strcmp(name, imports[i].name) != 0) continue;
        unsigned type = ELF64_R_TYPE(info);
        if (type != R_AARCH64_JUMP_SLOT && type != R_AARCH64_GLOB_DAT) return false;
        uintptr_t slot = pointer(image, offset, sizeof(void *));
        if (slot == 0 || slot % sizeof(void *) != 0) return false;
        plan->found[i]++;
        for (size_t j = 0; j < plan->count; j++) if ((uintptr_t)plan->items[j].slot == slot) return true;
        if (plan->count == MAX_PATCHES) return false;
        long size = sysconf(_SC_PAGESIZE);
        if (size <= 0 || ((uintptr_t)size & ((uintptr_t)size - 1)) != 0) return false;
        int protection = slot_protection(image, slot, (uintptr_t)size);
        if (protection < 0) return false;
        plan->items[plan->count++] = (struct patch){(void **)slot, imports[i].hook, *(void **)slot, protection};
    }
    return true;
}

/* Bounded signed-LEB decoding for Android APS2 relocation tables. */
struct packed { const unsigned char *at, *end; bool ok; };
static int64_t signed_leb(struct packed *data) {
    uint64_t result = 0;
    unsigned shift = 0;
    for (unsigned i = 0; i < 10; i++) {
        if (data->at == data->end) break;
        unsigned char byte = *data->at++;
        if (i == 9 && byte != 0 && byte != 0x7f) break;
        result |= ((uint64_t)(byte & 0x7f)) << shift;
        shift += 7;
        if (!(byte & 0x80)) {
            if (shift < 64 && (byte & 0x40)) result |= UINT64_MAX << shift;
            return (int64_t)result;
        }
    }
    data->ok = false;
    return 0;
}

static bool android_relocations(struct plan *plan, const struct image *image, uintptr_t address, size_t size) {
    if (size < 4 || !range(image, address, size, PF_R) || memcmp((const void *)address, "APS2", 4) != 0) return false;
    struct packed data = {(const unsigned char *)address + 4, (const unsigned char *)address + size, true};
    int64_t count_left = signed_leb(&data), initial = signed_leb(&data);
    if (!data.ok || count_left < 0 || count_left > 4000000 || initial < 0) return false;
    uint64_t offset = (uint64_t)initial;
    while (count_left > 0 && data.ok) {
        int64_t count_group = signed_leb(&data), flags = signed_leb(&data);
        if (count_group <= 0 || count_group > count_left || flags < 0 || (flags & ~15) != 0) return false;
        int64_t delta = (flags & 2) ? signed_leb(&data) : 0;
        uint64_t info = (flags & 1) ? (uint64_t)signed_leb(&data) : 0;
        if ((flags & 12) == 12) (void)signed_leb(&data);  /* Addends do not affect import identification. */
        for (int64_t i = 0; i < count_group && data.ok; i++) {
            int64_t step = (flags & 2) ? delta : signed_leb(&data);
            if (step >= 0) {
                if ((uint64_t)step > UINT64_MAX - offset) return false;
                offset += (uint64_t)step;
            } else {
                uint64_t subtract = (uint64_t)(-(step + 1)) + 1;
                if (subtract > offset) return false;
                offset -= subtract;
            }
            if (!(flags & 1)) info = (uint64_t)signed_leb(&data);
            if ((flags & 12) == 8) (void)signed_leb(&data);
            if (!data.ok || !relocation(plan, image, offset, info)) return false;
        }
        count_left -= count_group;
    }
    return data.ok && count_left == 0 && data.at == data.end;
}

static bool ordinary_relocations(struct plan *plan, const struct image *image, uintptr_t address, size_t size) {
    if (size % sizeof(ElfW(Rela)) != 0 || !range(image, address, size, PF_R)) return false;
    const ElfW(Rela) *entries = (const ElfW(Rela) *)address;
    for (size_t i = 0; i < size / sizeof(*entries); i++)
        if (!relocation(plan, image, entries[i].r_offset, entries[i].r_info)) return false;
    return true;
}

static bool known_name(const char *path) {
    if (path == NULL) return false;
    const char *name = strrchr(path, '/');
    name = name == NULL ? path : name + 1;
    return strcmp(name, "libmonochrome_64.so") == 0 || strcmp(name, "libmonochrome.so") == 0 ||
           strcmp(name, "libwebviewchromium.so") == 0 || strcmp(name, "libwebviewchromium_64.so") == 0;
}

static int collect(struct dl_phdr_info *info, size_t size, void *opaque) {
    (void)size;
    struct plan *plan = opaque;
    if (!known_name(info->dlpi_name)) return 0;
    if (++plan->modules > MAX_MODULES || info->dlpi_phnum == 0 || info->dlpi_phnum > 256) { plan->error = 1; return 1; }
    struct image image = {.info = info};
    const ElfW(Dyn) *dynamic = NULL;
    size_t dynamic_size = 0;
    for (size_t i = 0; i < info->dlpi_phnum; i++) {
        if (info->dlpi_phdr[i].p_type != PT_DYNAMIC) continue;
        dynamic_size = info->dlpi_phdr[i].p_memsz;
        uintptr_t address = pointer(&image, info->dlpi_phdr[i].p_vaddr, dynamic_size);
        if (address == 0 || dynamic_size > 1048576) { plan->error = 2; return 1; }
        dynamic = (const ElfW(Dyn) *)address;
    }
    if (dynamic == NULL) { plan->error = 3; return 1; }
    ElfW(Addr) symbols = 0, strings = 0, plt = 0, rela = 0, android_rela = 0;
    size_t string_size = 0, plt_size = 0, rela_size = 0, android_size = 0, symbol_size = 0, rela_entry = 0;
    long plt_type = 0;
    bool ended = false;
    for (size_t i = 0; i < dynamic_size / sizeof(*dynamic); i++) {
        const ElfW(Dyn) *item = &dynamic[i];
        if (item->d_tag == DT_NULL) { ended = true; break; }
        switch (item->d_tag) {
            case DT_SYMTAB: symbols = item->d_un.d_ptr; break;
            case DT_STRTAB: strings = item->d_un.d_ptr; break;
            case DT_STRSZ: string_size = item->d_un.d_val; break;
            case DT_SYMENT: symbol_size = item->d_un.d_val; break;
            case DT_JMPREL: plt = item->d_un.d_ptr; break;
            case DT_PLTRELSZ: plt_size = item->d_un.d_val; break;
            case DT_PLTREL: plt_type = item->d_un.d_val; break;
            case DT_RELA: rela = item->d_un.d_ptr; break;
            case DT_RELASZ: rela_size = item->d_un.d_val; break;
            case DT_RELAENT: rela_entry = item->d_un.d_val; break;
            case DT_ANDROID_RELA: android_rela = item->d_un.d_ptr; break;
            case DT_ANDROID_RELASZ: android_size = item->d_un.d_val; break;
            default: break;
        }
    }
    if (!ended || symbol_size != sizeof(ElfW(Sym)) || string_size == 0 || string_size > 67108864 ||
            (plt_size && plt_type != DT_RELA) || (rela_size && rela_entry != sizeof(ElfW(Rela)))) {
        plan->error = 4; return 1;
    }
    image.symbols = (const ElfW(Sym) *)pointer(&image, symbols, sizeof(ElfW(Sym)));
    image.strings = (const char *)pointer(&image, strings, string_size);
    image.string_size = string_size;
    if (image.symbols == NULL || image.strings == NULL ||
            (plt_size && !ordinary_relocations(plan, &image, pointer(&image, plt, plt_size), plt_size)) ||
            (rela_size && !ordinary_relocations(plan, &image, pointer(&image, rela, rela_size), rela_size)) ||
            (android_size && !android_relocations(plan, &image, pointer(&image, android_rela, android_size), android_size))) {
        plan->error = 5; return 1;
    }
    return 0;
}

static bool kernel_denied(void) {
    const int families[] = {AF_INET, AF_INET6}, types[] = {SOCK_STREAM, SOCK_DGRAM};
    for (size_t i = 0; i < 2; i++) for (size_t j = 0; j < 2; j++) {
        int fd = socket(families[i], types[j] | SOCK_CLOEXEC, 0);
        if (fd >= 0) { close(fd); return false; }
        if (errno != EACCES && errno != EPERM) return false;
    }
    return true;
}

static bool write_slot(const struct patch *patch, void *value, uintptr_t page_size) {
    uintptr_t page = (uintptr_t)patch->slot & ~(page_size - 1);
    if (mprotect((void *)page, page_size, PROT_READ | PROT_WRITE) != 0) return false;
    __atomic_store_n(patch->slot, value, __ATOMIC_RELEASE);
    bool restored = mprotect((void *)page, page_size, patch->protection) == 0;
    return restored && __atomic_load_n(patch->slot, __ATOMIC_ACQUIRE) == value;
}

JNIEXPORT jint JNICALL Java_io_github_leexeo_cage_webviewroute_RouteWebView_nativeInstall(JNIEnv *env, jclass type) {
    (void)env; (void)type;
    pthread_mutex_lock(&install_lock);
    if (!kernel_denied()) { LOGE("raw kernel INET boundary missing"); pthread_mutex_unlock(&install_lock); return -1; }
    int length = snprintf(endpoint, sizeof(endpoint), "/data/user/0/top.niunaijun.microdem/cache/space-%ld-egress.sock", (long)getpid());
    struct stat node;
    if (length <= 0 || (size_t)length >= sizeof(endpoint) || lstat(endpoint, &node) != 0 ||
            !S_ISSOCK(node.st_mode) || node.st_uid != getuid() || (node.st_mode & 0077) != 0) {
        LOGE("private Unix endpoint absent or wrong owner/mode"); pthread_mutex_unlock(&install_lock); return -2;
    }
    struct plan plan = {0};
    dl_iterate_phdr(collect, &plan);
    if (plan.error || plan.modules == 0 || plan.found[0] == 0 || plan.found[1] == 0 || plan.count == 0) {
        LOGE("import scan failed code=%d modules=%u socket=%u connect=%u", plan.error, plan.modules, plan.found[0], plan.found[1]);
        pthread_mutex_unlock(&install_lock); return -3;
    }
    if (installed) {
        for (size_t i = 0; i < plan.count; i++) {
            if (__atomic_load_n(plan.items[i].slot, __ATOMIC_ACQUIRE) != plan.items[i].hook) {
                __atomic_store_n(&ready, 0, __ATOMIC_RELEASE);
                LOGE("previous hook coverage changed"); pthread_mutex_unlock(&install_lock); return -4;
            }
        }
        int result = (int)plan.count;
        pthread_mutex_unlock(&install_lock); return result;
    }
    if (!flow_table_initialized) {
        for (size_t i = 0; i < TRACKED; i++) flows[i].fd = -1;
        flow_table_initialized = true;
    }
    uintptr_t page_size = (uintptr_t)sysconf(_SC_PAGESIZE);
    if (page_size == 0 || (page_size & (page_size - 1)) != 0) { pthread_mutex_unlock(&install_lock); return -5; }
    __atomic_store_n(&ready, 0, __ATOMIC_RELEASE);
    size_t applied = 0;
    bool ok = true;
    for (; applied < plan.count; applied++) {
        if (!write_slot(&plan.items[applied], plan.items[applied].hook, page_size)) { applied++; ok = false; break; }
    }
    if (!ok || !kernel_denied()) {
        bool rollback = true;
        for (size_t i = 0; i < applied; i++) if (!write_slot(&plan.items[i], plan.items[i].previous, page_size)) rollback = false;
        LOGE("hook installation failed; rollback=%d; routed sockets stay disabled", rollback);
        pthread_mutex_unlock(&install_lock); return -6;
    }
    installed = true;
    module_count = plan.modules;
    patch_count = (unsigned int)plan.count;
    __atomic_store_n(&ready, 1, __ATOMIC_RELEASE);
    LOGI("installed modules=%u slots=%u socket=%u connect=%u; raw INET still denied", module_count, patch_count, plan.found[0], plan.found[1]);
    pthread_mutex_unlock(&install_lock);
    return (jint)plan.count;
}

JNIEXPORT jstring JNICALL Java_io_github_leexeo_cage_webviewroute_RouteWebView_nativeStatus(JNIEnv *env, jclass type) {
    (void)type;
    char message[256];
    snprintf(message, sizeof(message), "ready=%d modules=%u slots=%u created=%lu connect=%lu denied=%lu closed=%lu options=%lu",
             __atomic_load_n(&ready, __ATOMIC_ACQUIRE), module_count, patch_count,
             read_count(&created), read_count(&connected), read_count(&denied), read_count(&closed), read_count(&option_adapted));
    return (*env)->NewStringUTF(env, message);
}
