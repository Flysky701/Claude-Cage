#!/bin/sh
set -eu
d="${1:?Pass the local boot fixture working directory}/curl-kit"
mkdir -p "$d/lib"
cp -L /usr/bin/curl "$d/curl"
cp -L /lib64/ld-linux-x86-64.so.2 "$d/ld"
cp /etc/ssl/certs/ca-certificates.crt "$d/ca.crt"
ldd /usr/bin/curl | awk '$2=="=>" && $3 ~ /^\// {print $3}' | while read -r file; do cp -L "$file" "$d/lib/"; done
du -sh "$d"
