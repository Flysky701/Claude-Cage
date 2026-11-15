#pragma once

#include "libc_samples.h"
#include <stddef.h>

static_assert(sizeof(ifaddrs) == 56 && offsetof(ifaddrs, ifa_next) == 0
    && offsetof(ifaddrs, ifa_name) == 8 && offsetof(ifaddrs, ifa_flags) == 16
    && offsetof(ifaddrs, ifa_data) == 48, "Unexpected 64-bit ifaddrs ABI");

long ownership_arm_difference = -2, ownership_nb_difference = -2, ownership_host_difference = -2;
uintptr_t ownership_host_base;

static long first_sample_difference(uintptr_t base, uintptr_t offset, const unsigned char* bytes, size_t size) {
    if (offset > UINTPTR_MAX - base || !readable(base + offset, size)) return -2;
    const auto* actual = reinterpret_cast<const unsigned char*>(base + offset);
    for (size_t index = 0; index < size; ++index)
        if (actual[index] != bytes[index]) return static_cast<long>(index);
    return -1;
}

// This header is included after the checked mapped-memory helpers. The samples
// cover getifaddrs, its allocation callback and freeifaddrs in the actual image.
// No opaque ifa_data field is inspected, copied, reallocated or separately freed.
static bool sample_matches(uintptr_t base, uintptr_t offset, const unsigned char* bytes, size_t size) {
    if (offset > UINTPTR_MAX - base) return false;
    uintptr_t start = base + offset;
    return readable(start, size) && memcmp(reinterpret_cast<const void*>(start), bytes, size) == 0;
}

static bool mapped_host_release_verified() {
    FILE* maps = fopen("/proc/self/maps", "re");
    if (!maps) { log("ownership.reject.hostMapsUnavailable"); return false; }
    char line[2048], permissions[5], path[1024];
    unsigned long long begin, end, offset;
    bool verified = false, host_seen = false;
    while (fgets(line, sizeof(line), maps)) {
        path[0] = '\0';
        if (sscanf(line, "%llx-%llx %4s %llx %*s %*u %1023[^\n]", &begin, &end, permissions, &offset, path) != 5
            || offset != 0 || permissions[0] != 'r' || end - begin < sizeof(Elf64_Ehdr)) continue;
        const char* name = strrchr(path, '/');
        if (!name || strcmp(name, "/libc.so") != 0 || !readable(begin, sizeof(Elf64_Ehdr))) continue;
        Elf64_Ehdr header;
        memcpy(&header, reinterpret_cast<const void*>(static_cast<uintptr_t>(begin)), sizeof(header));
        if (memcmp(header.e_ident, ELFMAG, SELFMAG) != 0 || header.e_ident[EI_CLASS] != ELFCLASS64
            || header.e_ident[EI_DATA] != ELFDATA2LSB || header.e_machine != EM_X86_64) continue;
        host_seen = true;
        ownership_host_base = static_cast<uintptr_t>(begin);
        ownership_host_difference = first_sample_difference(begin, host_get_offset, host_ifaddrs_code, sizeof(host_ifaddrs_code));
        if (sample_matches(begin, host_get_offset, host_ifaddrs_code, sizeof(host_ifaddrs_code))) {
            verified = true;
            break;
        }
    }
    fclose(maps);
    log(verified ? "ownership.host.exactSample" : host_seen ? "ownership.reject.hostSampleMismatch" : "ownership.reject.hostImageMissing");
    return verified;
}

static bool cage_ifaddrs_release_verified(void* get, void* release) {
    Dl_info getter{}, freer{};
    if (!get || !release || !dladdr(get, &getter) || !dladdr(release, &freer)) {
        log("ownership.reject.symbolOwnerUnavailable"); return false;
    }
    if (getter.dli_fbase != freer.dli_fbase) { log("ownership.reject.differentOwners"); return false; }
    uintptr_t base = reinterpret_cast<uintptr_t>(getter.dli_fbase);
    if (!arm_header(base)) { log("ownership.reject.ownerNotArm"); return false; }
    if (reinterpret_cast<uintptr_t>(get) != base + arm_get_offset
        || reinterpret_cast<uintptr_t>(release) != base + arm_free_offset) {
        log("ownership.reject.symbolOffsets"); return false;
    }
    ownership_arm_difference = first_sample_difference(base, arm_get_offset, arm_ifaddrs_code, sizeof(arm_ifaddrs_code));
    ownership_nb_difference = first_sample_difference(base, arm_nb_get_offset, arm_nb_ifaddrs_code, sizeof(arm_nb_ifaddrs_code));
    if (sample_matches(base, arm_get_offset, arm_ifaddrs_code, sizeof(arm_ifaddrs_code))) {
        log("ownership.arm.exactSample"); return true;
    }
    // The nb ELF begins with SVC traps, so the unexecuted ARM remainder is not
    // accepted by itself. Check the actual mapped host implementation as well.
    if (!sample_matches(base, arm_nb_get_offset, arm_nb_ifaddrs_code, sizeof(arm_nb_ifaddrs_code))) {
        log("ownership.reject.armAndNbSamples"); return false;
    }
    log("ownership.nb.exactSample");
    return mapped_host_release_verified();
}
