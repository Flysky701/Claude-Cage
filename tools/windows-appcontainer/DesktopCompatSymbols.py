"""Read matching public PDB symbols through bounded HTTP ranges, not a full PDB.

MSF, DBI and Publics layouts follow the LLVM PDB Native RawTypes definitions.
Only official Electron symbols are requested. The cache contains public symbols.
"""
import argparse
import ctypes
import json
import pathlib
import struct
import urllib.request
import uuid


class Pdb:
    chunk = 256 * 1024

    def __init__(self, guid_age, cache, filename="electron.exe.pdb", server="https://symbols.electronjs.org"):
        self.url = f"{server}/{filename}/{guid_age}/{filename}"
        self.cache = cache / guid_age
        self.cache.mkdir(parents=True, exist_ok=True)
        self.total = 0
        self.memory = {}
        header = self.read(0, 56)
        if not header.startswith(b"Microsoft C/C++ MSF 7.00"):
            raise ValueError("unsupported PDB")
        self.block, _, _, directory_size, _, block_map = struct.unpack_from("<6I", header, 32)
        count = (directory_size + self.block - 1) // self.block
        pages = struct.unpack(f"<{count}I", self.read(block_map * self.block, count * 4))
        directory = b"".join(self.read(p * self.block, self.block) for p in pages)[:directory_size]
        streams = struct.unpack_from("<I", directory)[0]
        self.sizes = struct.unpack_from(f"<{streams}I", directory, 4)
        offset = 4 + streams * 4
        self.pages = []
        for size in self.sizes:
            n = (size + self.block - 1) // self.block if size != 0xFFFFFFFF else 0
            self.pages.append(struct.unpack_from(f"<{n}I", directory, offset))
            offset += n * 4
        info = self.stream(1, 0, 28)
        actual = uuid.UUID(bytes_le=info[12:28]).hex.upper() + str(struct.unpack_from("<I", info, 8)[0])
        if actual != guid_age:
            raise ValueError("PDB GUID/age mismatch")
        dbi = self.stream(3, 0, 64)
        self.public, self.records = struct.unpack_from("<H", dbi, 16)[0], struct.unpack_from("<H", dbi, 20)[0]
        public_header = self.stream(self.public, 0, 28)
        hash_size, map_size = struct.unpack_from("<II", public_header)
        self.map_offset, self.map_count = 28 + hash_size, map_size // 4
        print(json.dumps({"pdbIdentityVerified": True, "publicCount": self.map_count, "directoryBytes": directory_size}), flush=True)

    def read(self, offset, size):
        result = bytearray()
        while size:
            chunk_id, within = divmod(offset, self.chunk)
            if chunk_id not in self.memory:
                path = self.cache / f"{chunk_id:06x}.bin"
                if path.exists():
                    data = path.read_bytes()
                else:
                    start = chunk_id * self.chunk
                    if self.total + self.chunk > 64 * 1024 * 1024:
                        raise ValueError("64 MiB symbol range budget exceeded")
                    request = urllib.request.Request(self.url, headers={"Range": f"bytes={start}-{start+self.chunk-1}"})
                    with urllib.request.urlopen(request, timeout=20) as response:
                        if response.status != 206 or not response.headers.get("Content-Range", "").startswith(f"bytes {start}-"):
                            raise ValueError("server did not honor bounded range")
                        data = response.read(self.chunk + 1)
                    if len(data) > self.chunk:
                        raise ValueError("oversized range")
                    path.write_bytes(data)
                    self.total += len(data)
                self.memory[chunk_id] = data
            data = self.memory[chunk_id]
            take = min(size, len(data) - within)
            if take <= 0:
                raise ValueError("range outside PDB")
            result += data[within:within+take]
            offset += take
            size -= take
        return bytes(result)

    def stream(self, index, offset, size):
        if offset + size > self.sizes[index]:
            raise ValueError("stream outside PDB")
        output = bytearray()
        while size:
            page, within = divmod(offset, self.block)
            take = min(size, self.block - within)
            output += self.read(self.pages[index][page] * self.block + within, take)
            offset += take
            size -= take
        return bytes(output)

    def symbol(self, index):
        offset = struct.unpack("<I", self.stream(self.public, self.map_offset + index * 4, 4))[0]
        header = self.stream(self.records, offset, 14)
        length, kind, flags, address, section = struct.unpack("<HHIIH", header)
        if kind != 0x110E:
            raise ValueError(f"unexpected public record {kind:x}")
        name = self.stream(self.records, offset + 14, length + 2 - 14).split(b"\0", 1)[0].decode("utf-8", "replace")
        return section, address, name

    def find(self, section, address):
        low, high = 0, self.map_count
        while low < high:
            mid = (low + high) // 2
            candidate = self.symbol(mid)
            if candidate[:2] <= (section, address):
                low = mid + 1
            else:
                high = mid
        return self.symbol(max(0, low - 1))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("exe", type=pathlib.Path)
    parser.add_argument("cache", type=pathlib.Path)
    parser.add_argument("rva", nargs="+")
    parser.add_argument("--server", choices=["https://symbols.electronjs.org", "https://msdl.microsoft.com/download/symbols"], default="https://symbols.electronjs.org")
    args = parser.parse_args()
    with args.exe.open("rb") as f:
        f.seek(0x3C)
        pe = struct.unpack("<I", f.read(4))[0]
        f.seek(pe + 6)
        section_count = struct.unpack("<H", f.read(2))[0]
        f.seek(pe + 20)
        optional_size = struct.unpack("<H", f.read(2))[0]
        optional = pe + 24
        f.seek(optional + 112 + 6 * 8)
        debug_rva, debug_size = struct.unpack("<II", f.read(8))
        sections = []
        for i in range(section_count):
            f.seek(optional + optional_size + i * 40)
            name, virtual_size, rva, raw_size, raw = struct.unpack("<8sIIII", f.read(24))
            sections.append((rva, max(virtual_size, raw_size), raw))
        def raw(rva):
            for start, size, file_offset in sections:
                if start <= rva < start + size:
                    return file_offset + rva - start
            raise ValueError("RVA outside image")
        identity = None
        pdb_filename = None
        for i in range(debug_size // 28):
            f.seek(raw(debug_rva) + i * 28 + 12)
            kind, size, _, pointer = struct.unpack("<IIII", f.read(16))
            if kind == 2:
                f.seek(pointer)
                data = f.read(size)
                if data[:4] == b"RSDS":
                    identity = uuid.UUID(bytes_le=data[4:20]).hex.upper() + str(struct.unpack_from("<I", data, 20)[0])
                    pdb_filename = pathlib.Path(data[24:].split(b"\0", 1)[0].decode("utf-8")).name
        if not identity:
            raise ValueError("missing PE CodeView identity")
    pdb = Pdb(identity, args.cache, pdb_filename, args.server)
    undecorate = ctypes.WinDLL("dbghelp").UnDecorateSymbolName
    rows = []
    for value in args.rva:
        rva = int(value, 16)
        section = next((i + 1 for i, (start, size, _) in enumerate(sections) if start <= rva < start + size), None)
        if section is None:
            continue
        target = rva - sections[section - 1][0]
        matched_section, offset, name = pdb.find(section, target)
        buffer = ctypes.create_string_buffer(8192)
        decoded = buffer.value.decode("utf-8", "replace") if undecorate(name.encode(), buffer, len(buffer), 0) else name
        row = {"rva": hex(rva), "symbol": decoded, "symbolSection": matched_section, "offset": hex(target - offset)}
        rows.append(row)
        print(json.dumps(row), flush=True)
    report = {"identity": identity, "downloadBytes": pdb.total, "symbols": rows}
    (args.cache / "symbols.json").write_text(json.dumps(report, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
