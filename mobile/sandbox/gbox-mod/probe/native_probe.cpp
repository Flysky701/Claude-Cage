#include <jni.h>
#include <errno.h>
#include <fcntl.h>
#include <ifaddrs.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/system_properties.h>
#include <time.h>
#include <unistd.h>

// Fixed, bounded JSON output; no C++ runtime dependency or native logging.
struct Json {
    char bytes[8192] = {};
    size_t size = 0;
    bool overflow = false;

    void add(const char* format, ...) {
        if (overflow) return;
        va_list arguments;
        va_start(arguments, format);
        int count = vsnprintf(bytes + size, sizeof(bytes) - size, format, arguments);
        va_end(arguments);
        if (count < 0 || static_cast<size_t>(count) >= sizeof(bytes) - size) overflow = true;
        else size += static_cast<size_t>(count);
    }

    void quote(const char* text) {
        add("\"");
        for (const unsigned char* p = reinterpret_cast<const unsigned char*>(text); *p; ++p) {
            if (*p == '"' || *p == '\\') add("\\%c", *p);
            else if (*p < 32) add("\\u%04x", *p);
            else add("%c", *p);
        }
        add("\"");
    }

    void error(const char* type, int code = 0) {
        add("{\"status\":\"ERROR\",\"type\":");
        quote(type);
        add(",\"errno\":%d}", code);
    }

    jbyteArray result(JNIEnv* env) {
        const char* output = overflow ? "{\"status\":\"ERROR\",\"type\":\"OutputLimit\"}" : bytes;
        jsize length = static_cast<jsize>(strlen(output));
        jbyteArray array = env->NewByteArray(length);
        if (array != nullptr) env->SetByteArrayRegion(array, 0, length, reinterpret_cast<const jbyte*>(output));
        return array;
    }
};

static void properties(Json& json) {
    const char* keys[] = {
        "persist.sys.timezone", "gsm.sim.operator.iso-country", "gsm.sim.operator.alpha",
        "gsm.sim.operator.numeric", "gsm.operator.iso-country", "gsm.operator.alpha", "gsm.operator.numeric"
    };
    json.add("{");
    for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); ++i) {
        if (i) json.add(",");
        json.quote(keys[i]);
        json.add(":");
        char value[PROP_VALUE_MAX] = {};
        int length = __system_property_get(keys[i], value);
        if (length < 0 || length >= PROP_VALUE_MAX || strnlen(value, sizeof(value)) != static_cast<size_t>(length)) {
            json.error("PropertyRead");
            continue;
        }
        json.add("{\"status\":\"%s\",\"value\":", length == 0 ? "EMPTY" : "OK");
        json.quote(value);
        json.add("}");
    }
    json.add("}");
}

struct PropertyValue {
    char text[PROP_VALUE_MAX] = {};
    bool called = false;
    bool valid = false;
};

static void property_callback(void* opaque, const char*, const char* value, uint32_t serial) {
    (void)serial; // Opaque change token; no dependence on Bionic's internal bit layout.
    auto* output = static_cast<PropertyValue*>(opaque);
    output->called = true;
    size_t length = strnlen(value, PROP_VALUE_MAX);
    output->valid = length < PROP_VALUE_MAX;
    if (output->valid) memcpy(output->text, value, length + 1);
}

static PropertyValue read_property(const char* key, unsigned api) {
    PropertyValue result;
    if (api == 0) {
        int length = __system_property_get(key, result.text);
        result.called = true;
        result.valid = length >= 0 && length < PROP_VALUE_MAX
            && strnlen(result.text, sizeof(result.text)) == static_cast<size_t>(length);
        return result;
    }
    const prop_info* info = __system_property_find(key);
    if (info == nullptr) return result;
    if (api == 1) {
        char name[PROP_NAME_MAX] = {};
        int length = __system_property_read(info, name, result.text);
        result.called = true;
        result.valid = length >= 0 && length < PROP_VALUE_MAX
            && strnlen(result.text, sizeof(result.text)) == static_cast<size_t>(length)
            && strcmp(name, key) == 0;
    } else __system_property_read_callback(info, property_callback, &result);
    return result;
}

static void compact_property(Json& json, const PropertyValue& reading) {
    if (!reading.called) json.add("{\"error\":\"MissingProperty\"}");
    else if (!reading.valid) json.add("{\"error\":\"InvalidPropertyReading\"}");
    else json.quote(reading.text);
}

static void property_apis(Json& json) {
    const char* keys[] = {
        "persist.sys.timezone", "gsm.sim.operator.iso-country", "gsm.sim.operator.alpha",
        "gsm.sim.operator.numeric", "gsm.operator.iso-country", "gsm.operator.alpha", "gsm.operator.numeric"
    };
    const char* labels[] = {"legacyRead", "callback"};
    bool callbacks_valid = true;
    json.add("{");
    for (unsigned api = 1; api <= 2; ++api) {
        if (api > 1) json.add(",");
        json.quote(labels[api - 1]);
        json.add(":{");
        for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); ++i) {
            if (i) json.add(",");
            json.quote(keys[i]);
            json.add(":");
            PropertyValue reading = read_property(keys[i], api);
            compact_property(json, reading);
            if (api == 2) callbacks_valid &= reading.called && reading.valid;
        }
        json.add("}");
    }
    json.add(",\"callbacksValid\":%s,\"controls\":{", callbacks_valid ? "true" : "false");
    // Device capacity and unrelated version properties are observations, never SIM evidence.
    const char* controls[] = {"persist.radio.multisim.config", "telephony.active_modems.max_count", "ro.build.version.sdk"};
    for (size_t i = 0; i < sizeof(controls) / sizeof(controls[0]); ++i) {
        if (i) json.add(",");
        json.quote(controls[i]);
        json.add(":[");
        for (unsigned api = 0; api <= 2; ++api) {
            if (api) json.add(",");
            compact_property(json, read_property(controls[i], api));
        }
        json.add("]");
    }
    json.add("}}");
}

static void interfaces(Json& json) {
    ifaddrs* list = nullptr;
    errno = 0;
    if (getifaddrs(&list) != 0) {
        int code = errno;
        if (list != nullptr) freeifaddrs(list);
        json.error("Getifaddrs", code);
        return;
    }
    if (list == nullptr) {
        json.add("{\"status\":\"NULL\",\"value\":null}");
        return;
    }
    const char* names[128] = {};
    size_t count = 0;
    bool invalid = false;
    for (ifaddrs* item = list; item != nullptr; item = item->ifa_next) {
        // Deliberately never read ifa_addr, ifa_netmask, MAC data, or interface addresses.
        if (item->ifa_name == nullptr) { invalid = true; break; }
        if (strnlen(item->ifa_name, 65) > 64) { invalid = true; break; }
        bool duplicate = false;
        for (size_t i = 0; i < count; ++i) if (strcmp(names[i], item->ifa_name) == 0) duplicate = true;
        if (duplicate) continue;
        if (count == sizeof(names) / sizeof(names[0])) { invalid = true; break; }
        names[count++] = item->ifa_name;
    }
    if (invalid) json.error("InvalidInterfaceList");
    else {
        json.add("{\"status\":\"OK\",\"value\":[");
        for (size_t i = 0; i < count; ++i) {
            if (i) json.add(",");
            json.quote(names[i]);
        }
        json.add("]}");
    }
    freeifaddrs(list);
}

static void process_elf(Json& json) {
    int file = open("/proc/self/exe", O_RDONLY | O_CLOEXEC);
    if (file < 0) { json.error("OpenProcessElf", errno); return; }
    unsigned char header[20] = {};
    size_t length = 0;
    int failure = 0;
    while (length < sizeof(header)) {
        ssize_t count = read(file, header + length, sizeof(header) - length);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) { failure = count < 0 ? errno : 0; break; }
        length += static_cast<size_t>(count);
    }
    close(file);
    if (length != sizeof(header)) { json.error("ReadProcessElf", failure); return; }
    if (memcmp(header, "\x7f" "ELF", 4) != 0 || (header[4] != 1 && header[4] != 2)
            || (header[5] != 1 && header[5] != 2)) {
        json.error("InvalidProcessElf");
        return;
    }
    unsigned machine = header[5] == 1 ? header[18] | (header[19] << 8) : (header[18] << 8) | header[19];
    json.add("{\"status\":\"OK\",\"value\":{\"magicOk\":true,\"elfClass\":%u,\"byteOrder\":%u,\"eMachine\":%u}}",
             header[4], header[5], machine);
}

extern "C" JNIEXPORT jbyteArray JNICALL
Java_io_github_leexeo_cage_gboxprobe_ProbeActivity_nativeState(JNIEnv* env, jclass) {
    Json json;
    json.add("{\"status\":\"OK\",\"compiledAbi\":");
#if defined(__aarch64__)
    json.quote("arm64-v8a");
#else
    json.quote("UNEXPECTED_BUILD_ABI");
#endif
    json.add(",\"properties\":");
    properties(json);
    json.add(",\"propertyApis\":");
    property_apis(json);
    json.add(",\"interfaces\":");
    interfaces(json);
    json.add(",\"processMainElf\":");
    process_elf(json);
    json.add("}");
    return json.result(env);
}

extern "C" JNIEXPORT jbyteArray JNICALL
Java_io_github_leexeo_cage_gboxprobe_ProbeActivity_nativeClock(JNIEnv* env, jclass, jboolean refresh) {
    Json json;
    if (refresh) tzset();
    errno = 0;
    time_t epoch = time(nullptr);
    if (epoch == static_cast<time_t>(-1)) { json.error("Time", errno); return json.result(env); }
    tm local = {};
    if (localtime_r(&epoch, &local) == nullptr) { json.error("Localtime", errno); return json.result(env); }
    json.add("{\"status\":\"OK\",\"value\":{\"epochSeconds\":%lld,\"offsetSeconds\":%ld,\"explicitTzset\":%s}}",
             static_cast<long long>(epoch), local.tm_gmtoff, refresh ? "true" : "false");
    return json.result(env);
}
