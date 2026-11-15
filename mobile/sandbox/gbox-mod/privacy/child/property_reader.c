// This helper sends values only to its parent's private pipe. The Java probe
// compares them in memory and persists booleans, never raw SIM values.
#include <dlfcn.h>
#include <elf.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/system_properties.h>
#include <unistd.h>
#include "policy_keys.h"

static void emit(const char* api, const char* key, const char* value, int length) {
    printf("value|%s|%s|%d|", api, key, length);
    for (const unsigned char* p = (const unsigned char*)value; *p; ++p) printf("%02x", *p);
    printf("\n");
}

static void callback(void* cookie, const char* name, const char* value, uint32_t serial) {
    (void)serial;
    const char* expected = (const char*)cookie;
    if (strcmp(name, expected) != 0) { printf("callbackName=false\n"); return; }
    emit("callback", name, value, (int)strlen(value));
}

static void read_key(const char* key) {
    char value[PROP_VALUE_MAX] = {0};
    int length = __system_property_get(key, value);
    emit("get", key, value, length);
    const prop_info* info = __system_property_find(key);
    if (info == NULL) { printf("absent|%s\n", key); return; }
    length = __system_property_read(info, NULL, value);
    emit("read", key, value, length);
    __system_property_read_callback(info, callback, (void*)key);
}

int main(void) {
    Elf64_Ehdr header = {0};
    int fd = open("/proc/self/exe", O_RDONLY | O_CLOEXEC);
    ssize_t count = fd >= 0 ? read(fd, &header, sizeof(header)) : -1;
    if (fd >= 0) close(fd);
    printf("mainElf=%u\n", count == sizeof(header) ? header.e_machine : 0);
    unsigned (*state)(void) = (unsigned (*)(void))dlsym(RTLD_DEFAULT, "cage_child_policy_state");
    int (*existing)(void) = (int (*)(void))dlsym(RTLD_DEFAULT, "cage_existing_preload_marker");
    printf("policyState=%u\n", state != NULL ? state() : 0);
    printf("existingPreload=%s\n", existing != NULL && existing() == 701 ? "true" : "false");
    for (size_t i = 0; i < sizeof(kSimProperties) / sizeof(kSimProperties[0]); ++i) read_key(kSimProperties[i].name);
    read_key("persist.sys.timezone");
    read_key("persist.radio.multisim.config");
    read_key("telephony.active_modems.max_count");
    read_key("ro.build.version.sdk");
    return ferror(stdout) ? 1 : 0;
}

