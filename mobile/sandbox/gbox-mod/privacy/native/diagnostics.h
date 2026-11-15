#pragma once
#include <stdarg.h>

// Diagnostic observations only: no refresh, task registration, GOT changes, or
// symbol calls occur here. Paths are returned only to the selected guest's Java
// writer; logcat contains counts and fixed stages, never these path strings.
constexpr size_t DIAGNOSTIC_PATHS = 96;
struct DiagnosticPath { char path[1024]; unsigned decisions; };
DiagnosticPath observed_filters[DIAGNOSTIC_PATHS]{};
DiagnosticPath observed_loads[DIAGNOSTIC_PATHS]{};
size_t observed_filter_count, observed_load_count;
pthread_mutex_t observations = PTHREAD_MUTEX_INITIALIZER;
unsigned filter_decisions[4]{}; // outside roots, excluded, non-ARM/unresolved, allowed
unsigned filter_absolute, filter_relative, filter_empty;
unsigned load_callbacks, load_success, load_relevant;
unsigned filter_path_drops, load_path_drops;
bool load_observer_requested;

const char* file_name(const char* path) {
    if (!path) return "";
    const char* slash = strrchr(path, '/');
    return slash ? slash + 1 : path;
}

bool diagnostic_relevant(const char* path) {
    if (!path || !*path) return false;
    if (*path != '/') return true; // bare loader names carry no unrelated app path
    pthread_mutex_lock(&configuration);
    bool result = root_matches_locked(path);
    if (!result && root_count > 1) {
        const char* package = file_name(roots[1]);
        result = *package && strstr(path, package);
    }
    pthread_mutex_unlock(&configuration);
    if (result) return true;
    const char* name = file_name(path);
    return strcmp(name, "libc.so") == 0 || strcmp(name, "libcage_privacy.so") == 0
        || strcmp(name, "libvlitecore64.so") == 0 || strcmp(name, "libnb.so") == 0
        || strcmp(name, "libtcb.so") == 0;
}

bool remember_path(DiagnosticPath* records, size_t* count, const char* path, unsigned decision) {
    if (!path || strlen(path) >= sizeof(records[0].path)) return false;
    pthread_mutex_lock(&observations);
    size_t index = 0;
    while (index < *count && strcmp(records[index].path, path) != 0) ++index;
    if (index < DIAGNOSTIC_PATHS) {
        if (index == *count) { strcpy(records[index].path, path); ++*count; }
        records[index].decisions |= 1u << decision;
    }
    pthread_mutex_unlock(&observations);
    return index < DIAGNOSTIC_PATHS;
}

void diagnostic_filter(const char* path, unsigned decision) {
    int saved = errno;
    __atomic_fetch_add(&filter_decisions[decision], 1u, __ATOMIC_RELAXED);
    unsigned* kind = !path || !*path ? &filter_empty : *path == '/' ? &filter_absolute : &filter_relative;
    __atomic_fetch_add(kind, 1u, __ATOMIC_RELAXED);
    if (diagnostic_relevant(path) && !remember_path(observed_filters, &observed_filter_count, path, decision))
        __atomic_fetch_add(&filter_path_drops, 1u, __ATOMIC_RELAXED);
    errno = saved;
}

void diagnostic_after_dlopen(const char* path, int result, void*) {
    // ByteHook holds its observer read lock here. Only bounded copying and our
    // own counters/locks are used; never enumerate or re-enter its hook manager.
    int saved = errno;
    if (__atomic_load_n(&enabled, __ATOMIC_ACQUIRE)) {
        __atomic_fetch_add(&load_callbacks, 1u, __ATOMIC_RELAXED);
        if (result == 0) __atomic_fetch_add(&load_success, 1u, __ATOMIC_RELAXED);
        if (diagnostic_relevant(path)) {
            __atomic_fetch_add(&load_relevant, 1u, __ATOMIC_RELAXED);
            if (!remember_path(observed_loads, &observed_load_count, path, result == 0 ? 0 : 1))
                __atomic_fetch_add(&load_path_drops, 1u, __ATOMIC_RELAXED);
        }
    }
    errno = saved;
}

struct ObservationText {
    char bytes[65536]{};
    size_t used = 0;
    bool truncated = false;
    void append(const char* format, ...) {
        constexpr size_t limit = sizeof(bytes) - 64; // reserve a mandatory truncation marker
        if (used + 1 >= limit) { truncated = true; return; }
        va_list args;
        va_start(args, format);
        int count = vsnprintf(bytes + used, limit - used, format, args);
        va_end(args);
        if (count > 0) {
            if (static_cast<size_t>(count) >= limit - used) { used = limit - 1; truncated = true; }
            else used += static_cast<size_t>(count);
        }
    }
    void finish() {
        snprintf(bytes + used, sizeof(bytes) - used, "\ntext.truncated=%d\n", truncated);
    }
};
ObservationText binding_observation;

unsigned mapped_machine(uintptr_t base) {
    if (!readable(base, sizeof(Elf64_Ehdr))) return 0;
    Elf64_Ehdr header;
    memcpy(&header, reinterpret_cast<void*>(base), sizeof(header));
    if (memcmp(header.e_ident, ELFMAG, SELFMAG) || header.e_ident[EI_CLASS] != ELFCLASS64) return 0;
    return header.e_machine;
}

struct ObservationCensus { ObservationText* text; unsigned total, relevant, selected, arm; };
int observe_image(dl_phdr_info* info, size_t, void* opaque) {
    auto* census = static_cast<ObservationCensus*>(opaque);
    ++census->total;
    if (!diagnostic_relevant(info->dlpi_name)) return 0;
    ++census->relevant;
    bool selected = path_matches(info->dlpi_name);
    unsigned machine = mapped_machine(info->dlpi_addr);
    if (selected) ++census->selected;
    if (machine == EM_AARCH64) ++census->arm;
    census->text->append("phdr root=%d machine=%u base=%llx path=%s\n", selected, machine,
        static_cast<unsigned long long>(info->dlpi_addr), info->dlpi_name);
    return 0;
}

void describe_symbol(ObservationText* text, const char* label, void* symbol) {
    Dl_info owner{};
    if (!symbol || !dladdr(symbol, &owner)) { text->append("symbol %s unavailable\n", label); return; }
    uintptr_t base = reinterpret_cast<uintptr_t>(owner.dli_fbase);
    uintptr_t address = reinterpret_cast<uintptr_t>(symbol);
    text->append("symbol %s machine=%u rva=%llx owner=%s name=%s bytes=", label, mapped_machine(base),
        static_cast<unsigned long long>(address - base), owner.dli_fname ? owner.dli_fname : "",
        owner.dli_sname ? owner.dli_sname : "");
    if (readable(address, 32)) {
        const auto* bytes = reinterpret_cast<const unsigned char*>(address);
        for (size_t i = 0; i < 32; ++i) text->append("%02x", bytes[i]);
    } else text->append("unreadable");
    text->append("\n");
}

void capture_observation(ObservationText* text, int sequence) {
    text->append("checkpoint=%d active=%u installed=%d ownership=%d\n", sequence,
        __atomic_load_n(&enabled, __ATOMIC_ACQUIRE), installed, release_verified);
    text->append("ownershipSamples armFirstDiff=%ld nbFirstDiff=%ld hostFirstDiff=%ld hostBase=%llx (-1=exact,-2=not-read)\n",
        ownership_arm_difference, ownership_nb_difference, ownership_host_difference,
        static_cast<unsigned long long>(ownership_host_base));
    pthread_mutex_lock(&configuration);
    for (size_t index = 0; index < root_count; ++index) text->append("root[%zu]=%s\n", index, roots[index]);
    pthread_mutex_unlock(&configuration);
    text->append("filter total=%u absolute=%u relative=%u empty=%u outside=%u excluded=%u unresolved=%u allowed=%u\n",
        __atomic_load_n(&filter_calls, __ATOMIC_RELAXED), __atomic_load_n(&filter_absolute, __ATOMIC_RELAXED),
        __atomic_load_n(&filter_relative, __ATOMIC_RELAXED), __atomic_load_n(&filter_empty, __ATOMIC_RELAXED),
        __atomic_load_n(&filter_decisions[0], __ATOMIC_RELAXED), __atomic_load_n(&filter_decisions[1], __ATOMIC_RELAXED),
        __atomic_load_n(&filter_decisions[2], __ATOMIC_RELAXED), __atomic_load_n(&filter_decisions[3], __ATOMIC_RELAXED));
    for (size_t index = 0; index < 4; ++index)
        text->append("hook[%zu] success=%u failure=%u selectedCalls=%u\n", index,
            __atomic_load_n(&hook_success[index], __ATOMIC_RELAXED), __atomic_load_n(&hook_failure[index], __ATOMIC_RELAXED),
            __atomic_load_n(&hook_calls[index], __ATOMIC_RELAXED));
    text->append("loadCallbacks=%u success=%u relevant=%u\n", __atomic_load_n(&load_callbacks, __ATOMIC_RELAXED),
        __atomic_load_n(&load_success, __ATOMIC_RELAXED), __atomic_load_n(&load_relevant, __ATOMIC_RELAXED));
    pthread_mutex_lock(&observations);
    text->append("pathRecords capacity=%zu filter=%zu load=%zu filterDrops=%u loadDrops=%u\n", DIAGNOSTIC_PATHS,
        observed_filter_count, observed_load_count, __atomic_load_n(&filter_path_drops, __ATOMIC_RELAXED),
        __atomic_load_n(&load_path_drops, __ATOMIC_RELAXED));
    for (size_t index = 0; index < observed_filter_count; ++index)
        text->append("filterPath decisions=%u path=%s\n", observed_filters[index].decisions, observed_filters[index].path);
    for (size_t index = 0; index < observed_load_count; ++index)
        text->append("loadPath results=%u path=%s\n", observed_loads[index].decisions, observed_loads[index].path);
    pthread_mutex_unlock(&observations);
    ObservationCensus census{text, 0, 0, 0, 0};
    dl_iterate_phdr(observe_image, &census);
    text->append("phdrTotals total=%u relevant=%u selected=%u relevantArm=%u\n", census.total,
        census.relevant, census.selected, census.arm);
    describe_symbol(text, "getifaddrs", reinterpret_cast<void*>(real_getifaddrs));
    describe_symbol(text, "freeifaddrs", reinterpret_cast<void*>(real_freeifaddrs));
    describe_symbol(text, "property_callback", reinterpret_cast<void*>(real_property_callback));
    FILE* maps = fopen("/proc/self/maps", "re");
    if (maps) {
        char line[2048], path[1024];
        while (fgets(line, sizeof(line), maps)) {
            path[0] = '\0';
            if (sscanf(line, "%*s %*s %*s %*s %*s %1023[^\n]", path) != 1) continue;
            if (!strstr(path, ".so") && !strstr(path, ".apk")) continue;
            if (diagnostic_relevant(path)) text->append("map %s", line);
        }
        fclose(maps);
    } else text->append("maps unavailable\n");
    char summary[192];
    snprintf(summary, sizeof(summary), "observation.%d phdr=%u rootMatches=%u relevantArm=%u filters=%u allowed=%u loads=%u",
        sequence, census.total, census.selected, census.arm, __atomic_load_n(&filter_calls, __ATOMIC_RELAXED),
        __atomic_load_n(&filter_decisions[3], __ATOMIC_RELAXED), __atomic_load_n(&load_callbacks, __ATOMIC_RELAXED));
    log(summary);
    text->finish();
}
