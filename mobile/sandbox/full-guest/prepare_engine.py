"""Stage an arm64 Android build of QEMU for the graphical, socket-only guest."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import struct
import tarfile
from urllib.parse import quote
import urllib.request

REPO = "https://packages.termux.dev/apt/termux-main/"
SYSTEM = {"libc.so", "libdl.so", "libm.so", "liblog.so", "libandroid.so", "libz.so",
          "libOpenSLES.so", "libaaudio.so", "libnativewindow.so", "libEGL.so", "libGLESv2.so",
          "libvulkan.so", "libmediandk.so", "libjnigraphics.so", "libatomic.so"}
PC_ROM = {"bios.bin","bios-256k.bin","kvmvapic.bin","vgabios-stdvga.bin","vgabios-virtio.bin","vgabios.bin","efi-e1000.rom",
          "pxe-e1000.rom","linuxboot.bin","linuxboot_dma.bin","pvh.bin","multiboot.bin","multiboot_dma.bin"}

def pc_firmware(path):
    return path.parts[0]=="keymaps" or (len(path.parts)==1 and path.name in PC_ROM)

def needed(elf):
    """DT_NEEDED names from a 64-bit little-endian ELF; no code is executed."""
    if elf[:6] != b"\x7fELF\x02\x01": raise ValueError("Invalid engine library")
    phoff, = struct.unpack_from("<Q", elf, 32)
    stride, count = struct.unpack_from("<HH", elf, 54)
    regions = []
    dynamic = None
    for i in range(count):
        kind, _, offset, va, _, size, _, _ = struct.unpack_from("<IIQQQQQQ", elf, phoff+i*stride)
        if kind == 1: regions.append((va, offset, size))
        if kind == 2: dynamic = (offset, size)
    names, table = [], 0
    if dynamic:
        for pos in range(dynamic[0], sum(dynamic), 16):
            tag, value = struct.unpack_from("<QQ",elf,pos)
            if tag == 0: break
            if tag == 1: names.append(value)
            if tag == 5: table=value
    if not names: return []
    strings = next(off+table-va for va,off,size in regions if va<=table<va+size)
    return [elf[strings+i:elf.index(0,strings+i)].decode("ascii") for i in names]

def payload(deb):
    pos=8
    if not deb.startswith(b"!<arch>\n"): raise ValueError("Invalid deb archive")
    while pos+60<=len(deb):
        name=deb[pos:pos+16].decode("ascii").strip().rstrip("/")
        size=int(deb[pos+48:pos+58])
        if name.startswith("data.tar."):
            return tarfile.open(fileobj=io.BytesIO(deb[pos+60:pos+60+size]), mode="r:*")
        pos+=60+size+size%2
    raise ValueError("Missing deb payload")

def build(base):
    cache=base/"termux-engine-cache"
    cache.mkdir(parents=True,exist_ok=True)
    packages=json.loads(Path(__file__).with_name("engine-packages.json").read_text(encoding="utf-8"))
    prefix="data/data/com.termux/files/usr/"
    output=base/"engine"
    libs=output/"lib"
    libs.mkdir(parents=True,exist_ok=True)
    def fetch(name):
        meta=packages[name]
        path=cache/(name+".deb")
        if not path.exists():
            url=REPO+quote(meta["file"],safe="/:")
            with urllib.request.urlopen(url,timeout=60) as response: data=response.read()
        else: data=path.read_bytes()
        if hashlib.sha256(data).hexdigest()!=meta["sha256"]: raise ValueError("Package checksum failed: "+name)
        if not path.exists():path.write_bytes(data)
        return name,path
    providers={}
    with ThreadPoolExecutor(max_workers=7) as pool:
        for pkg,deb in pool.map(fetch,sorted(packages)):
            with payload(deb.read_bytes()) as tar:
                for item in tar:
                    name=item.name.lstrip("./")
                    if not name.startswith(prefix): continue
                    rel=PurePosixPath(name[len(prefix):])
                    if rel.as_posix()=="bin/qemu-system-x86_64":
                        (output/"qemu").write_bytes(tar.extractfile(item).read())
                    if rel.parent.as_posix()=="lib" and ".so" in rel.name:
                        providers[rel.name]=(deb,item.name)
                    if pkg=="qemu-common" and len(rel.parts)>=3 and rel.parts[:2]==("share","qemu") and item.isfile():
                        firmware=Path(*rel.parts[2:])
                        if not pc_firmware(firmware): continue
                        dest=output/"roms"/firmware
                        if not dest.resolve().is_relative_to((output/"roms").resolve()): raise ValueError("Invalid firmware path")
                        dest.parent.mkdir(parents=True,exist_ok=True)
                        dest.write_bytes(tar.extractfile(item).read())
    # Android packages many of its libraries without versioned SONAMEs. Keep the ELF
    # names intact in private storage; the APK contains the executable in nativeLibraryDir.
    queue=needed((output/"qemu").read_bytes())
    done=set()
    while queue:
        name=queue.pop()
        if name in SYSTEM or name in done:continue
        if not re.fullmatch(r"lib[\w+.-]+\.so(?:\.[\w.-]+)?",name):raise ValueError("Invalid dependency "+name)
        deb,entry=providers[name]
        with payload(deb.read_bytes()) as tar: data=tar.extractfile(entry).read()
        (libs/name).write_bytes(data)
        done.add(name)
        queue.extend(needed(data))
    print("Prepared QEMU 11.1.3 and",len(done),"runtime libraries")

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workdir",type=Path)
    build(parser.parse_args().workdir)
