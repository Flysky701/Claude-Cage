"""Narrow binary-XML overlay: add Cage's home activity, keep the old one registered.

No resource recompilation, package/version/permission/authority/data-dir changes.
The only removed nodes are the old SplashActivity's launcher intent filter.
"""
import struct

ANDROID = "http://schemas.android.com/apk/res/android"
OLD = "com.gbox.android.SplashActivity"
NEW = "io.github.leexeo.cage.shell.HomeActivity"


def u32(data, offset):
    return struct.unpack_from('<I', data, offset)[0]


def chunks(data):
    assert struct.unpack_from('<HH', data) == (3, 8) and u32(data, 4) == len(data)
    pos = 8
    result = []
    while pos < len(data):
        kind, header, size = struct.unpack_from('<HHI', data, pos)
        if size < header or pos + size > len(data):
            raise ValueError('Invalid XML chunk')
        result.append(bytearray(data[pos:pos + size]))
        pos += size
    return result


def strings(pool):
    count, styles, flags, start, style_start = struct.unpack_from('<IIIII', pool, 8)
    if styles or style_start:
        raise ValueError('Styled XML string pool is unsupported')
    utf8 = bool(flags & 256)
    def length(at, width):
        n = pool[at] if width == 1 else struct.unpack_from('<H', pool, at)[0]
        mask = 128 if width == 1 else 32768
        if n & mask:
            m = pool[at + width] if width == 1 else struct.unpack_from('<H', pool, at + width)[0]
            return ((n & (mask - 1)) << (8 if width == 1 else 16)) | m, at + 2 * width
        return n, at + width
    result = []
    for i in range(count):
        at = start + u32(pool, 28 + i * 4)
        n, at = length(at, 1 if utf8 else 2)
        if utf8:
            n, at = length(at, 1)
        result.append(bytes(pool[at:at + n * (1 if utf8 else 2)]).decode('utf-8' if utf8 else 'utf-16le'))
    return result, utf8


def make_pool(values, utf8):
    body, offsets = bytearray(), []
    def length(n, width):
        if width == 1:
            return bytes([n]) if n < 128 else bytes([128 | (n >> 8), n & 255])
        return struct.pack('<H', n) if n < 32768 else struct.pack('<HH', 32768 | (n >> 16), n & 65535)
    for value in values:
        offsets.append(len(body))
        encoded = value.encode('utf-8' if utf8 else 'utf-16le')
        units = len(value.encode('utf-16le')) // 2
        body += length(units, 1 if utf8 else 2)
        if utf8:
            body += length(len(encoded), 1)
        body += encoded + (b'\0' if utf8 else b'\0\0')
    body += b'\0' * (-len(body) % 4)
    start = 28 + 4 * len(values)
    return bytearray(struct.pack('<HHIIIIII', 1, 28, start + len(body), len(values), 0,
                                 256 if utf8 else 0, start, 0)
                     + struct.pack('<' + 'I' * len(offsets), *offsets) + body)


def attributes(chunk, values):
    start, size, count = struct.unpack_from('<HHH', chunk, 24)
    if size != 20:
        raise ValueError('Unknown XML attribute layout')
    result = []
    for i in range(count):
        at = 16 + start + i * size
        namespace, name, raw, _, _, kind, value = struct.unpack_from('<IIIHBBI', chunk, at)
        result.append((at, values[name], values[value] if kind == 3 else value,
                       values[namespace] if namespace != 0xffffffff else None))
    return result


def patch(data):
    parts = chunks(data)
    pools = [i for i, c in enumerate(parts) if struct.unpack_from('<H', c)[0] == 1]
    if len(pools) != 1:
        raise ValueError('One XML string pool required')
    values, utf8 = strings(parts[pools[0]])
    if NEW in values:
        raise ValueError('Home overlay already present')
    home_index = len(values)
    values.append(NEW)
    begin, end, depth, name_at = None, None, 0, None
    for i, c in enumerate(parts):
        kind = struct.unpack_from('<H', c)[0]
        if kind == 0x102:
            if begin is None and values[u32(c, 20)] == 'activity':
                matches = [a for a in attributes(c, values) if a[1:] == ('name', OLD, ANDROID)]
                if matches:
                    begin, name_at = i, matches[0][0]
            if begin is not None:
                depth += 1
        elif kind == 0x103 and begin is not None:
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    if begin is None or end is None:
        raise ValueError('Original launcher activity missing')
    original = parts[begin:end]
    # The new entry inherits the original launcher intent filter and attributes.
    new = [bytearray(c) for c in original]
    struct.pack_into('<I', new[0], name_at + 8, home_index)
    struct.pack_into('<I', new[0], name_at + 16, home_index)
    # New native UI manages its own lifecycle: do not inherit a splash noHistory.
    for at, name, value, namespace in attributes(new[0], values):
        if namespace == ANDROID and name in ('noHistory', 'excludeFromRecents'):
            struct.pack_into('<I', new[0], at + 8, 0xffffffff)
            new[0][at + 15] = 0x12
            struct.pack_into('<I', new[0], at + 16, 0)
    kept, removed_filters, i = [], 0, 0
    while i < len(original):
        c = original[i]
        if struct.unpack_from('<H', c)[0] == 0x102 and values[u32(c, 20)] == 'intent-filter':
            level, j = 1, i + 1
            while level:
                k = struct.unpack_from('<H', original[j])[0]
                level += (k == 0x102) - (k == 0x103)
                j += 1
            subtree = original[i:j]
            launcher = any(a[2] == 'android.intent.category.LAUNCHER' for node in subtree
                           if struct.unpack_from('<H', node)[0] == 0x102 for a in attributes(node, values))
            if launcher:
                removed_filters += 1
            else:
                kept.extend(subtree)
            i = j
        else:
            kept.append(c)
            i += 1
    if removed_filters != 1:
        raise ValueError('Expected exactly one original launcher filter')
    parts[begin:end] = kept + new
    parts[pools[0]] = make_pool(values, utf8)
    payload = b''.join(parts)
    result = struct.pack('<HHI', 3, 8, len(payload) + 8) + payload
    # Roundtrip string values/indices are stable; existing references never move.
    checked, _ = strings(chunks(result)[pools[0]])
    if checked != values:
        raise ValueError('String pool roundtrip mismatch')
    return result
