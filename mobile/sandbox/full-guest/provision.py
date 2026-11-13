"""After installation, stage public boot inputs and the local core's temporary authentication."""
import argparse
import base64
import re
import subprocess
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("--adb", required=True)
p.add_argument("--workdir", type=Path, required=True)
args = p.parse_args()

def shell(command, data=None):
    return subprocess.run([args.adb,"-d","shell","-T",command],input=data,stdout=subprocess.PIPE,check=True).stdout

def private_file(name, data):
    app = "run-as io.github.leexeo.cage.fullguest"
    shell(app+" sh -c 'umask 077; mkdir -p files && base64 -d > files/"+name+".tmp && mv files/"+name+".tmp files/"+name+"'", base64.b64encode(data))
    if int(shell(app+" stat -c %s files/"+name)) != len(data):
        raise IOError("Incomplete private file transfer")

runtime = shell("run-as io.github.leexeo.cage.localcore cat files/runtime.yaml").decode().replace("\r","")
token = re.search(r"^authentication: \['cage:([0-9a-f-]{36})'\]$",runtime,re.M)
if not token: raise SystemExit("Start the phone-local test core first")
for name in ("kernel","test-initrd.gz"):
    private_file(name,(args.workdir/name).read_bytes())
settings=f"""tunnel:
  mtu: 1500
socks5:
  address: 127.0.0.1
  port: 29461
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
