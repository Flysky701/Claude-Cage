from pathlib import Path
import argparse, gzip, re
p=argparse.ArgumentParser(description="Prepare the boot-only guest network fixture from local inputs.")
p.add_argument("workdir",type=Path)
base=p.parse_args().workdir.resolve()
raw=gzip.decompress((base/"initrd.img").read_bytes()); pos=0
while True:
    if raw[pos:pos+6]!=b"070701":raise ValueError("not newc")
    f=[int(raw[pos+6+i*8:pos+14+i*8],16) for i in range(13)]
    if raw[pos+110:pos+110+f[11]-1]==b"TRAILER!!!":break
    pos=(((pos+110+f[11]+3)&~3)+f[6]+3)&~3
out=bytearray(raw[:pos]); ino=0xe000
def add(name,data,mode):
    global ino
    ino+=1; n=name.encode()+b"\0"
    h=[ino,mode,0,0,1,0,len(data),0,0,0,0,len(n),0]
    out.extend(b"070701"+b"".join(f"{x:08x}".encode() for x in h)+n)
    out.extend(bytes(-len(out)%4));out.extend(data);out.extend(bytes(-len(out)%4))
for n in ("cage","cage/lib"):add(n,b"",0o40755)
for p in sorted((base/"curl-kit").rglob("*")):
    if p.is_file():add("cage/"+p.relative_to(base/"curl-kit").as_posix(),p.read_bytes(),0o100755)
add("cage/e1000.ko",(base/"e1000.ko").read_bytes(),0o100644)
pin=(base/"site-address").read_text().strip()
assert re.fullmatch(r"(?:[0-9]+\.){3}[0-9]+",pin)
init="""#!/bin/busybox sh
/bin/busybox --install -s /bin
export PATH=/bin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mkdir -p /etc /tmp
echo CAGE-VM-KERNEL; uname -r
insmod /cage/e1000.ko
ls /sys/class/net
if ! ip link set eth0 up; then echo CAGE-NIC-FAIL; while :; do sleep 60; done; fi
ip addr add 10.73.0.2/24 dev eth0
ip route add default via 10.73.0.1
echo 'nameserver 10.73.0.53' >/etc/resolv.conf
echo 'hosts: files dns' >/etc/nsswitch.conf
ip route; cat /sys/class/net/eth0/address
/cage/ld --library-path /cage/lib /cage/curl --version | head -1
i=0
while [ "$i" -lt 15 ]; do
  for mode in name address; do
    set --
    if [ "$mode" = address ]; then set -- --connect-to ipv4.icanhazip.com:443:PINIP:443; fi
    /cage/ld --library-path /cage/lib /cage/curl -q -4fsS --max-time 7 --connect-timeout 5 --cacert /cage/ca.crt -o /tmp/check "$@" "https://ipv4.icanhazip.com/?cage=$i-$mode"
    rc=$?
    addr=none
    if [ "$rc" = 0 ]; then addr=$(head -c 64 /tmp/check); fi
    echo "CAGE-RESULT $i $mode rc=$rc ip=$addr"
  done
  i=$((i+1)); sleep 3
done
while :; do sleep 60; done
""".replace("PINIP",pin)
add("cage-check",init.encode(),0o100755);add("TRAILER!!!",b"",0)
(base/"test-initrd.gz").write_bytes(gzip.compress(out,compresslevel=4,mtime=0))
