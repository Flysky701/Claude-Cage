"""Send the current single-node Cage route directly to the test app's private directory."""
import argparse
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--adb", required=True)
parser.add_argument("--config", type=Path, default=Path.home()/".claude-cage/proxy/config.yaml")
args = parser.parse_args()
sections = {}
current = None
for line in args.config.read_text(encoding="utf-8-sig").splitlines():
    key = re.match(r"^([a-zA-Z][\w-]*):", line)
    if key:
        current = key.group(1)
    if current in ("proxies", "proxy-groups", "rules"):
        sections.setdefault(current, []).append(line)
if set(sections) != {"proxies", "proxy-groups", "rules"}:
    raise SystemExit("Expected proxy, group and rule sections")
if sum(line.startswith("    - ") for line in sections["proxies"]) != 1:
    raise SystemExit("This experiment expects the active single-node Cage configuration")
rules = [line.strip() for line in sections["rules"][1:] if line.strip()]
if len(rules) != 1 or not re.fullmatch(r"- [\"']?MATCH,[^,]+[\"']?", rules[0], re.I):
    raise SystemExit("Expected a single explicit MATCH rule")
if any(re.search(r"\b(DIRECT|PASS)\b", line, re.I) for line in sections["proxy-groups"]+rules):
    raise SystemExit("Direct fallback not supported by this test")
payload = ("\n".join(line for k in ("proxies","proxy-groups","rules") for line in sections[k])+"\n").encode()
target = ("run-as io.github.leexeo.cage.localcore sh -c "
          "'umask 077; mkdir -p files && cat > files/upstream.tmp && mv files/upstream.tmp files/upstream.yaml'")
subprocess.run([args.adb, "-d", "shell", "-T", target], input=payload, check=True)
print("Private configuration provisioned")
