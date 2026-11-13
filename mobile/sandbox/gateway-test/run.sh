#!/usr/bin/env bash
set -euo pipefail
base=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d /tmp/cage-egress.XXXXXXXX)
umask 077
token=${work##*.}
gw=cg-g-$token
lan=cg-l-$token
wan=cg-w-$token
wp=$1
tools=${2:?Pass the temporary Linux tools directory}
export LD_LIBRARY_PATH="$tools/root/usr/lib/x86_64-linux-gnu"
nft="$tools/root/usr/sbin/nft"
backend=$(wslpath -w "$base/win_transport.py")
namespaces=()
resolver_dir_created=false
cleanup() {
    set +e
    if [[ -n "${slirp_pid:-}" ]]; then kill "$slirp_pid" >/dev/null 2>&1; fi
    for n in "${namespaces[@]}"; do
        for p in $(ip netns pids "$n"); do kill "$p" 2>/dev/null; done
    done
    for n in "${namespaces[@]}"; do ip netns del "$n"; done
    if "$resolver_dir_created"; then
        rm -f "/etc/netns/$lan/resolv.conf" "/etc/netns/$lan/nsswitch.conf"
        rmdir "/etc/netns/$lan" 2>/dev/null
    fi
    if [[ "$work" == /tmp/cage-egress.* ]]; then rm -rf -- "$work"; fi
}
trap cleanup EXIT
for n in "$gw" "$lan" "$wan"; do
    ip netns add "$n"; namespaces+=("$n")
    ip -n "$n" link set lo up
    ip netns exec "$n" sysctl -qw net.ipv6.conf.all.disable_ipv6=1 net.ipv6.conf.default.disable_ipv6=1
done
mkdir -p /etc/netns
mkdir "/etc/netns/$lan"
resolver_dir_created=true
printf 'nameserver 192.0.2.1\noptions timeout:3 attempts:2\n' > "/etc/netns/$lan/resolv.conf"
sed -E 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf > "/etc/netns/$lan/nsswitch.conf"
ip -n "$gw" link add g-lan type veth peer name client0 netns "$lan"
ip -n "$gw" link add g-wan type veth peer name upstream0 netns "$wan"
for item in "$gw g-lan 192.0.2.1" "$lan client0 192.0.2.2" "$gw g-wan 198.51.100.1" "$wan upstream0 198.51.100.2"; do
    read -r ns dev addr <<< "$item"
    ip -n "$ns" addr add "$addr/30" dev "$dev"
    ip -n "$ns" link set "$dev" up
done
ip -n "$lan" route add default via 192.0.2.1
ip netns exec "$gw" sysctl -qw net.ipv4.ip_forward=1 net.ipv4.conf.all.rp_filter=0 net.ipv4.conf.default.rp_filter=0 net.ipv4.conf.g-lan.rp_filter=0
ip -n "$wan" addr add 203.0.113.17/32 dev lo
ip -n "$wan" route add 192.0.2.0/30 via 198.51.100.1
ip -n "$gw" route add 203.0.113.17/32 via 198.51.100.2
# Reachability control for an underlay route that is independent of the proxy.
mkdir "$work/canary"; echo canary > "$work/canary/check"
ip netns exec "$wan" python3 -m http.server 6080 --bind 203.0.113.17 --directory "$work/canary" >"$work/canary.log" 2>&1 &
canary() { ip netns exec "$1" curl -q --noproxy '*' -fsS --max-time 2 http://203.0.113.17:6080/check 2>/dev/null; }
for i in {1..15}; do if [[ "$(canary "$lan" || true)" == canary ]]; then break; fi; sleep .2; done
[[ "$(canary "$lan")" == canary ]]
echo "positive control: client reached underlay before applying gateway policy"
"$tools/root/usr/bin/slirp4netns" --netns-type=path --configure --disable-host-loopback "/run/netns/$gw" directwan >"$work/slirp.log" 2>&1 &
slirp_pid=$!
for i in {1..40}; do if ip -n "$gw" route show default | grep -q directwan; then break; fi; sleep .1; done
ip -n "$gw" route show default | grep -q directwan || { cat "$work/slirp.log"; exit 1; }
ip netns exec "$gw" "$nft" -f - <<'NFT'
table ip test_wan {
    chain egress {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr 192.0.2.2 oifname "directwan" counter masquerade
    }
}
NFT
nat_count() {
    ip netns exec "$gw" "$nft" -j list chain ip test_wan egress | python3 -c 'import json,sys; print(next(e["counter"]["packets"] for r in json.load(sys.stdin)["nftables"] if "rule" in r for e in r["rule"]["expr"] if "counter" in e))'
}
real_ip=$("$wp" "$backend" resolve | tr -d '\r')
destination=ipv4.icanhazip.com
real_control() {
    ip netns exec "$1" setpriv --reuid 65534 --regid 65534 --clear-groups curl -qfsS -4 --noproxy '*' --resolve "$destination:443:$real_ip" --max-time 8 "https://$destination/"
}
real_exit=$(real_control "$lan")
before=$(nat_count)
[[ -n "$real_exit" && "$before" -gt 0 ]]
echo "positive control: client reached real public HTTPS over alternate WAN; NAT counter advanced"
ip netns exec "$gw" "$nft" -f - <<NFT
table inet cage_lab_guard {
    chain input {
        type filter hook input priority filter; policy accept;
        iifname "g-lan" ip daddr 192.0.2.1 udp dport 53 accept
        iifname "g-lan" ip daddr 192.0.2.1 tcp dport 53 accept
        iifname "g-lan" drop
    }
    chain forward {
        type filter hook forward priority filter; policy accept;
        iifname "g-lan" oifname != "cage-tun" counter drop
    }
    chain output {
        type filter hook output priority filter; policy accept;
        oifname "directwan" meta skuid 65534 ip daddr $real_ip tcp dport 443 accept
        oifname "directwan" counter drop
    }
}
NFT
ip -n "$gw" route add prohibit default metric 32000 table 216
ip -n "$gw" rule add pref 100 iif g-lan lookup 216
gzip -dc "${3:?Pass the verified Mihomo archive}" > "$work/mihomo"; chmod 700 "$work/mihomo"
cp "$base/gateway.yaml" "$work/config.yaml"
start_proxy() {
    ip netns exec "$wan" python3 "$base/uplink.py" "$wp" "$backend" >"$work/uplink.log" 2>&1 &
    proxy_pid=$!
    for i in {1..20}; do
        if ip netns exec "$wan" ss -lnt | grep -q ':1080 '; then return; fi
        sleep .2
    done
    echo "upstream listener failed"; return 1
}
start_core() {
    ip netns exec "$gw" "$work/mihomo" -d "$work" -f "$work/config.yaml" >"$work/core.log" 2>&1 &
    core_pid=$!
    for i in {1..50}; do
        if ip -n "$gw" link show cage-tun >/dev/null 2>&1; then break; fi
        if ! kill -0 "$core_pid" 2>/dev/null; then break; fi
        sleep .2
    done
    if ! ip -n "$gw" link show cage-tun >/dev/null 2>&1; then cat "$work/core.log"; return 1; fi
    ip netns exec "$gw" sysctl -qw net.ipv4.conf.cage-tun.rp_filter=0
    ip -n "$gw" route replace default dev cage-tun metric 10 table 216
}
probe() {
    local phase=$1 expected=$2
    ip netns exec "$lan" python3 "$base/client.py" "$phase" "$work/pin" > "$work/result.json" || { tail -12 "$work/core.log"; tail -12 "$work/uplink.log"; ip netns exec "$gw" ss -lnu; return 1; }
    python3 - "$phase" "$expected" "$work" <<'PY'
import ipaddress,json,sys
from pathlib import Path
phase,expected,work=sys.argv[1:]
d=Path(work)
res=json.loads((d/"result.json").read_text())
ref=(d/"reference").read_text().strip()
ok=True
for k,v in res.items():
    try: ipaddress.IPv4Address(v); state="same-exit" if v==ref else "OTHER-EXIT"
    except ValueError: state=v
    print(phase,k,state,flush=True)
    if expected=="online":ok &= state=="same-exit"
    else:ok &= state in ("TimeoutError","gaierror","PermissionError","ConnectionRefusedError","ConnectionResetError","OSError","RemoteDisconnected","SSLEOFError","SSLError","curl-6","curl-7","curl-28","curl-35","curl-52","curl-56")
if not ok:raise SystemExit("unexpected probe result")
PY
    [[ "$(canary "$gw")" == canary ]]
    if [[ "$(canary "$lan" || true)" == canary ]]; then echo "underlay leak"; return 1; fi
    [[ -n "$(real_control "$gw")" ]]
    [[ "$(nat_count)" == "$before" ]]
    echo "$phase: real alternate WAN still reachable by control; no new client NAT flows on that path"
}
start_proxy
start_core
"$wp" "$backend" reference | tr -d '\r' > "$work/reference"
check=$(ip netns exec "$gw" curl -qfsS -4 --noproxy no-bypass.invalid --proxy socks5h://198.51.100.2:1080 --max-time 12 https://ipv4.icanhazip.com/) || { tail -12 "$work/uplink.log"; exit 1; }
[[ "$check" == "$(cat "$work/reference")" ]]
echo "gateway upstream: verified against live Cage proxy"
probe online online
kill "$proxy_pid"; wait "$proxy_pid" || true
probe upstream-stopped offline
kill "$core_pid"; wait "$core_pid" || true
probe core-stopped offline
start_proxy; start_core
probe recovered online
echo 'gateway test passed'
