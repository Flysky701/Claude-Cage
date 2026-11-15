"""Fetch only the missing x86_64 link inputs from the official r27d ZIP.

Headers and compiler are shared with the existing r27d ARM toolchain. HTTP
ranges are required: a server returning the whole archive is rejected.
"""
from pathlib import Path
import binascii
import io
import json
import struct
import urllib.request
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[5]
NDK = ROOT / "mobile/.build/client-integration/ndk"
LLVM = NDK / "toolchains/llvm/prebuilt/windows-x86_64"
URL = "https://dl.google.com/android/repository/android-ndk-r27d-windows.zip"
SIZE = 781506724
PREFIX = "android-ndk-r27d/"
FILES = [
    "toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/x86_64-linux-android/28/" + name
    for name in ("libc.so", "libdl.so", "crtbegin_dynamic.o", "crtend_android.o")
] + ["toolchains/llvm/prebuilt/windows-x86_64/lib/clang/18/lib/linux/libclang_rt.builtins-x86_64-android.a"]


def get_range(start, end):
    request = urllib.request.Request(URL, headers={"Range": f"bytes={start}-{end}", "Accept-Encoding": "identity"})
    with urllib.request.urlopen(request, timeout=45) as response:
        if response.status != 206 or response.headers.get("Content-Range") != f"bytes {start}-{end}/{SIZE}":
            raise RuntimeError("Official ZIP server did not honor the bounded range")
        data = response.read(end - start + 2)
    if len(data) != end - start + 1:
        raise RuntimeError("Truncated ZIP range")
    return data


def main():
    pending = [path for path in FILES if not (NDK / path).is_file()]
    if not pending:
        print("x86_64 NDK link inputs already present")
        return
    tail = get_range(SIZE - 65557, SIZE - 1)
    eocd = tail.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise RuntimeError("ZIP end record missing")
    fields = struct.unpack_from("<4s4H2LH", tail, eocd)
    cd_size, cd_offset = fields[5:7]
    central = get_range(cd_offset, cd_offset + cd_size - 1)
    # ZipFile adjusts the offsets for a central-directory-only image. The
    # original local offsets are restored by adding cd_offset below.
    with zipfile.ZipFile(io.BytesIO(central + tail[eocd:])) as archive:
        infos = {info.filename: info for info in archive.infolist()}
    extracted = []
    for relative in pending:
        info = infos[PREFIX + relative]
        local_offset = info.header_offset + cd_offset
        header = get_range(local_offset, local_offset + 29)
        fields = struct.unpack("<4s5H3L2H", header)
        if fields[0] != b"PK\x03\x04" or fields[3] != zipfile.ZIP_DEFLATED:
            raise RuntimeError("Unexpected ZIP entry encoding")
        data_start = local_offset + 30 + fields[-2] + fields[-1]
        compressed = get_range(data_start, data_start + info.compress_size - 1)
        data = zlib.decompress(compressed, -15)
        if len(data) != info.file_size or binascii.crc32(data) & 0xffffffff != info.CRC:
            raise RuntimeError("ZIP member integrity mismatch")
        target = (NDK / relative).resolve()
        if not target.is_relative_to(NDK.resolve()):
            raise RuntimeError("Target leaves NDK cache")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        extracted.append({"file": relative, "compressedBytes": info.compress_size, "bytes": len(data), "crc32": f"{info.CRC:08x}"})
    report = ROOT / "mobile/.build/gbox-mod/child-probe/ndk-x86-inputs.json"
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps({"source": URL, "release": "27.3.13750724", "files": extracted}, indent=2), encoding="utf-8")
    print(json.dumps({"fetchedFiles": len(extracted), "compressedBytes": sum(item["compressedBytes"] for item in extracted)}))


if __name__ == "__main__":
    main()
