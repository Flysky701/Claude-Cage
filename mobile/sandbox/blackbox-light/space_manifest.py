"""Add the space entry point to the binary manifest of the pinned BlackBox APK."""
import struct


def add_space_activity(xml, microg=False):
    # Retain the original resource IDs, namespace map and every existing string index.
    pool = 8
    kind, header, size, count, styles, flags, start, _ = struct.unpack_from("<HH6I", xml, pool)
    if (kind, header, styles, flags, start) != (1, 28, 0, 0, 28 + 4 * count):
        raise ValueError("unexpected BlackBox manifest string pool")
    offsets = list(struct.unpack_from(f"<{count}I", xml, pool + header))
    data = bytearray(xml[pool + start:pool + size])
    strings = []
    for offset in offsets:
        length, = struct.unpack_from("<H", data, offset)
        strings.append(data[offset + 2:offset + 2 + length * 2].decode("utf-16-le"))

    def index(value):
        if value not in strings:
            offsets.append(len(data))
            encoded = value.encode("utf-16-le")
            data.extend(struct.pack("<H", len(encoded) // 2) + encoded + b"\0\0")
            strings.append(value)
        return strings.index(value)

    none = 0xffffffff
    android = index("http://schemas.android.com/apk/res/android")
    if microg:
        # All package-specific strings in this pinned manifest have the same length
        # after renaming. Fully qualified Java component names use another prefix.
        old_pkg, new_pkg = "top.niunaijun.cagetest", "top.niunaijun.microbox"
        if old_pkg not in strings:
            raise ValueError("unexpected base package for the microG space")
        for offset, value in zip(offsets, strings):
            if value == old_pkg or value.startswith(old_pkg + "."):
                pos = offset + 2
                data[pos:pos + 2 * len(old_pkg)] = new_pkg.encode("utf-16-le")
        # Move the original BlackBox launcher behind the space settings button.
        # Existing nodes retain their category index; the new launcher gets a new one.
        launcher_index = strings.index("android.intent.category.LAUNCHER")
        strings[launcher_index] = "io.github.leexeo.cage.space.INTERNAL_LAUNCHER"
        encoded = strings[launcher_index].encode("utf-16-le")
        offsets[launcher_index] = len(data)
        data.extend(struct.pack("<H", len(encoded) // 2) + encoded + b"\0\0")

    def element(name, attrs=(), children=b""):
        tag = index(name)
        fields = bytearray()
        for key, value in attrs:
            if value is True:
                raw, typ, typed = none, 0x12, 0xffffffff
            else:
                raw = typed = index(value)
                typ = 3
            fields.extend(struct.pack("<IIIHBBI", android, index(key), raw, 8, 0, typ, typed))
        opening = struct.pack("<HHIIIII6H", 0x102, 16, 36 + len(fields), 1, none,
                              none, tag, 20, 20, len(attrs), 0, 0, 0)
        closing = struct.pack("<HHIIIII", 0x103, 16, 24, 1, none, none, tag)
        return opening + fields + children + closing

    actions = b"".join(element("action", [("name", "io.github.leexeo.cage.space." + action)])
                        for action in ("OPEN_CLAUDE", "GOOGLE_SETTINGS", "INSTALL_CLAUDE", "OPEN_STORE"))
    category = element("category", [("name", "android.intent.category.DEFAULT")])
    attrs = [("name", "io.github.leexeo.cage.space.SpaceActivity"), ("exported", True)]
    filters = element("intent-filter", children=actions + category)
    if microg:
        attrs.append(("label", "Cage microG 空间"))
        launcher = element("action", [("name", "android.intent.action.MAIN")])
        launcher += element("category", [("name", "android.intent.category.LAUNCHER")])
        filters += element("intent-filter", children=launcher)
    activity = element("activity", attrs, filters)
    # The application end tag follows all of its existing children.
    position = pool + size
    while position < len(xml):
        token, _, length = struct.unpack_from("<HHI", xml, position)
        if token == 0x103 and struct.unpack_from("<I", xml, position + 20)[0] == index("application"):
            break
        if length < 8:
            raise ValueError("invalid manifest chunk")
        position += length
    else:
        raise ValueError("missing application tag")
    while len(data) % 4:
        data.append(0)
    new_start = header + 4 * len(offsets)
    string_pool = (struct.pack("<HH6I", 1, header, new_start + len(data), len(offsets), 0, 0, new_start, 0)
                   + struct.pack(f"<{len(offsets)}I", *offsets) + data)
    result = bytearray(xml[:pool] + string_pool + xml[pool + size:position] + activity + xml[position:])
    struct.pack_into("<I", result, 4, len(result))
    return result
