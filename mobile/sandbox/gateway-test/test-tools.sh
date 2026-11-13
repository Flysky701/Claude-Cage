#!/bin/bash
set -euo pipefail
out=$1
cd "$out"
if ! apt-get -qq download slirp4netns libslirp0 nftables libnftables1 libnftnl11 libmnl0 libxtables12; then
    exit 1
fi
mkdir root
for p in ./*.deb; do dpkg-deb -x "$p" root; done
export LD_LIBRARY_PATH="$out/root/usr/lib/x86_64-linux-gnu"
ldd root/usr/bin/slirp4netns root/usr/sbin/nft | grep 'not found' || true
root/usr/bin/slirp4netns --version | head -1
root/usr/sbin/nft --version
printf '%s\n' "$out"
