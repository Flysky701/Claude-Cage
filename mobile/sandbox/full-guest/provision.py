"""After installation, stage public boot inputs and the local core's temporary authentication."""
import argparse
import base64
import hashlib
import re
import secrets
import shlex
import struct
import subprocess
import tarfile
import tempfile
import stat
from pathlib import Path
from prepare_engine import pc_firmware

p = argparse.ArgumentParser()
p.add_argument("--adb", required=True)
p.add_argument("--workdir", type=Path, required=True)
p.add_argument("--android-iso", type=Path, help="Bliss 16.9.7 FOSS 20241011 live image for the graphical guest")
p.add_argument("--userdata", type=Path, help="formatted ext4 image for the first boot only")
p.add_argument("--microg-relay", action="store_true", help="use the separate microG space's phone-local relay")
args = p.parse_args()

def shell(command, data=None):
    return subprocess.run([args.adb,"-d","shell","-T",command],input=data,stdout=subprocess.PIPE,check=True).stdout

def private_file(name, data):
    app = "run-as io.github.leexeo.cage.fullguest"
    shell(app+" sh -c 'umask 077; mkdir -p files && base64 -d > files/"+name+".tmp && mv files/"+name+".tmp files/"+name+"'", base64.b64encode(data))
    if int(shell(app+" stat -c %s files/"+name)) != len(data):
        raise IOError("Incomplete private file transfer")

app = "run-as io.github.leexeo.cage.fullguest"

def private_image(name, path):
    # Stream large images once over USB. Leave an existing Android data disk in place.
    remote = "files/" + name
    if name == "userdata.img" and subprocess.run([args.adb,"-d","shell",app+" test -f "+remote]).returncode == 0:
        return
    temp = "/data/local/tmp/cage-guest-" + secrets.token_hex(8)
    try:
        subprocess.run([args.adb,"-d","push","-z","any",str(path),temp],check=True)
        shell(app+" sh -c 'umask 077; mkdir -p files && cp "+temp+" "+remote+".part && mv "+remote+".part "+remote+"'")
        if int(shell(app+" stat -c %s "+remote))!=path.stat().st_size:
            raise IOError("Incomplete guest image transfer")
    finally:
        shell("rm -f "+shlex.quote(temp))

def engine_files():
    engine=args.workdir/"engine"
    if not (engine/"qemu").is_file():raise ValueError("Run prepare_engine.py before provisioning a graphical guest")
    with tempfile.TemporaryDirectory(dir=args.workdir) as temporary:
        archive=Path(temporary)/"engine.tar"
        with tarfile.open(archive,"w") as out:
            out.add(engine/"lib",arcname="engine-lib")
            firmware=engine/"roms"
            for path in firmware.rglob("*"):
                rel=path.relative_to(firmware)
                if path.is_file() and pc_firmware(rel):
                    out.add(path,arcname="android-roms/"+rel.as_posix())
        private_image("engine.tar",archive)
        shell(app+" sh -c 'cd files && tar -xf engine.tar && rm engine.tar'")

def extract_boot(iso):
    # These two primary ISO9660 records are part of the pinned, verified release.
    with iso.open("rb") as src:
        if hashlib.file_digest(src,"sha256").hexdigest()!="735cb962ec6bd92b62eb82a812831a38d79a0dfdf12b7973d2d0f7ab001ba68e":
            raise ValueError("Expected the official Bliss 16.9.7 FOSS 20241011 image")
        src.seek(16*2048)
        pvd=src.read(2048)
        if pvd[1:6]!=b"CD001": raise ValueError("ISO9660 volume missing")
        src.seek(struct.unpack_from("<I",pvd,158)[0]*2048)
        directory=src.read(struct.unpack_from("<I",pvd,166)[0])
        pos=0
        records={}
        while pos<len(directory):
            length=directory[pos]
            if not length:
                pos=(pos//2048+1)*2048
                continue
            record=directory[pos:pos+length]
            name=record[33:33+record[32]].decode("ascii").split(";")[0].lower().rstrip(".")
            records[name]=(struct.unpack_from("<I",record,2)[0],struct.unpack_from("<I",record,10)[0])
            pos+=length
        for filename,remote in (("kernel","android-kernel"),("initrd.img","android-initrd.img")):
            sector,size=records[filename]
            if size<=0 or size>64*1024*1024:raise ValueError("Invalid ISO boot file")
            src.seek(sector*2048)
            private_file(remote,src.read(size))


if args.android_iso:
    if not args.userdata and subprocess.run([args.adb,"-d","shell",app+" test -f files/userdata.img"]).returncode:
        p.error("A blank ext4 --userdata image is required for the first graphical boot")
    if args.userdata:
        if not stat.S_ISREG(args.userdata.stat().st_mode):
            p.error("--userdata must be a regular ext4 image file")
        with args.userdata.open("rb") as data:
            data.seek(1080)
            if data.read(2)!=b"\x53\xef":p.error("--userdata is missing an ext filesystem superblock")
    extract_boot(args.android_iso)
    engine_files()
    if args.userdata: private_image("userdata.img",args.userdata)
    private_image("system.iso",args.android_iso)
    print("Graphical guest staged. Open the space to start its on-device gateway.")
    raise SystemExit(0)
relay = "io.github.leexeo.cage.microcore" if args.microg_relay else "io.github.leexeo.cage.localcore"
port = 29462 if args.microg_relay else 29461
runtime = shell("run-as "+relay+" cat files/runtime.yaml").decode().replace("\r","")
token = re.search(r"^authentication: \['cage:([0-9a-f-]{36})'\]$",runtime,re.M)
if not token: raise SystemExit("Start the phone-local test core first")
for name in ("kernel","test-initrd.gz"):
    private_file(name,(args.workdir/name).read_bytes())
settings=f"""tunnel:
  mtu: 1500
socks5:
  address: 127.0.0.1
  port: {port}
  udp: 'udp'
  username: cage
  password: '{token[1]}'
mapdns:
  address: 10.73.0.53
  port: 53
  network: 198.18.0.0
  netmask: 255.254.0.0
  cache-size: 1024
misc:
  log-level: error
  connect-timeout: 4000
"""
private_file("backend.yaml",settings.encode())
print("Boot files and private on-device upstream staged")
