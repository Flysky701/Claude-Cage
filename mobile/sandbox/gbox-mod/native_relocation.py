"""Relocate one encoded host-package constant in an exactly identified ELF.

The executable segment, conditions, syscalls, permissions and failure branches are
unchanged. This is intentionally sample-specific; an unknown input fails closed.
"""
import hashlib
import struct

OLD = b"com.gbox.android"
NEW = b"com.cage.android"
LAYOUTS = {
    "64": {
        "size": 915888, "elf_class": 2, "machine": 183,
        "seed_offset": 0xda008, "seed_address": 0xdb008,
    },
    "32": {
        "size": 743904, "elf_class": 1, "machine": 40,
        "seed_offset": 0xb1008, "seed_address": 0xb2008,
    },
}
SAMPLES = {
    "lib/arm64-v8a/libvlitecore64.so": ("64",
        "7b8bd3b2061fc9d6ed86df4f330e5e203fa7003bb2ca18d69861fdcc3cff2b14",
        "f926801ae36312dd50fc7beb7c3f929525991f30fd05057cab2b62fbe216ca30"),
    "lib/arm64-v8a/libvlitecore32.so": ("32",
        "85238d29df6f0c42f42a9bf8bb8c0453935f92137713a2552f0f09c814d937cd",
        "9c5fb68d5e8f520f93a31f67033bdbae56947e2e4d49927019afc14e52178972"),
    "lib/armeabi-v7a/libvlitecore64.so": ("64",
        "d6f120b4b54d5e1bc776f2e2fea25fa4e021324fae92493aab064c0c6a8f1f37",
        "dd89f528ff69732ff25c01f38a9f9a50ca3bcc565f2f9244d44bd84a6b70bb3e"),
    "lib/armeabi-v7a/libvlitecore32.so": ("32",
        "cef8f6c08d8e6612ce7b3dcb972e3f07b98c7adc531140849eeb1a729105486e",
        "356de061e60526f9e29df16a293ca602ec5cbfb08457a84fed1da23bfbf4dcba"),
}
TARGETS = {name: dict(LAYOUTS[bits], sha256=whole, seed_sha256=seed)
           for name, (bits, whole, seed) in SAMPLES.items()}


def decode_seed(seed):
    if len(seed) != 256:
        raise ValueError("Unexpected encoded host constant size")
    stream = bytes(a ^ b for a, b in zip(seed, seed[1:]))
    positions = [i for i, value in enumerate(stream)
                 if 65 <= value <= 90 or 97 <= value <= 122 or 48 <= value <= 57 or value in (46, 95)]
    count = len(positions)
    split = (count + 1) // 2
    decoded = bytearray(count)
    for index, position in enumerate(positions):
        decoded[index // 2 + (index % 2) * split] = stream[position]
    return bytes(decoded), stream, positions


def relocate(name, original):
    sample = TARGETS.get(name)
    if sample is None:
        return original, None
    if len(original) != sample["size"] or hashlib.sha256(original).hexdigest() != sample["sha256"]:
        raise ValueError("Unknown native relocation sample: " + name)
    if original[:6] != b"\x7fELF" + bytes((sample["elf_class"], 1)):
        raise ValueError("Unexpected native ELF class or byte order: " + name)
    if struct.unpack_from("<H", original, 18)[0] != sample["machine"]:
        raise ValueError("Unexpected native ELF architecture: " + name)
    offset = sample["seed_offset"]
    seed = original[offset:offset + 256]
    if hashlib.sha256(seed).hexdigest() != sample["seed_sha256"]:
        raise ValueError("Native encoded host constant has changed")
    decoded, stream, positions = decode_seed(seed)
    if decoded != OLD or len(OLD) != len(NEW):
        raise ValueError("Native old package name did not decode exactly")
    replacement_stream = bytearray(stream)
    split = (len(positions) + 1) // 2
    for index, position in enumerate(positions):
        replacement_stream[position] = NEW[index // 2 + (index % 2) * split]
    replacement = bytearray((seed[0],))
    for value in replacement_stream:
        replacement.append(replacement[-1] ^ value)
    new_name, new_stream, new_positions = decode_seed(replacement)
    if new_name != NEW or new_positions != positions:
        raise ValueError("Native new package name did not decode exactly")
    if any(a != b for i, (a, b) in enumerate(zip(stream, new_stream)) if i not in positions):
        raise ValueError("Unrelated native decoded bytes changed")
    result = original[:offset] + replacement + original[offset + 256:]
    if len(result) != len(original):
        raise ValueError("Native replacement changed ELF size")
    # The known sample's entire executable load segment precedes this data blob.
    if sample["elf_class"] == 2:
        table = struct.unpack_from("<Q", original, 32)[0]
        entry_size, count = struct.unpack_from("<HH", original, 54)
        headers = [struct.unpack_from("<IIQQQQQQ", original, table + i * entry_size)
                   for i in range(count)]
        segments = [(h[0], h[1], h[2], h[3], h[5]) for h in headers]
    else:
        table = struct.unpack_from("<I", original, 28)[0]
        entry_size, count = struct.unpack_from("<HH", original, 42)
        headers = [struct.unpack_from("<IIIIIIII", original, table + i * entry_size)
                   for i in range(count)]
        segments = [(h[0], h[6], h[1], h[2], h[4]) for h in headers]
    seed_segment = [s for s in segments if s[0] == 1 and s[2] <= offset and offset + 256 <= s[2] + s[4]]
    if len(seed_segment) != 1 or seed_segment[0][1] & 1:
        raise ValueError("Native host constant is not confined to a non-executable segment")
    segment = seed_segment[0]
    if segment[3] + offset - segment[2] != sample["seed_address"]:
        raise ValueError("Native host constant address changed")
    for kind, flags, start, _, size in segments:
        if kind == 1 and flags & 1 and original[start:start + size] != result[start:start + size]:
            raise ValueError("Native executable instructions changed")
    return bytes(result), {
        "kind": "encoded host-package relocation", "originalSha256": sample["sha256"],
        "patchedSha256": hashlib.sha256(result).hexdigest(),
        "fileOffset": hex(offset), "virtualAddress": hex(sample["seed_address"]),
        "regionBytes": 256, "changedBytes": sum(a != b for a, b in zip(seed, replacement)),
        "decodedBefore": OLD.decode(), "decodedAfter": NEW.decode(),
        "executableSegmentsUnchanged": True, "conditionsAndFailurePathsUnchanged": True,
    }
