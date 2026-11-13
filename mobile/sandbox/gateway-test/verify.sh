#!/usr/bin/env bash
set -euo pipefail
base=$(cd "$(dirname "$0")" && pwd)
wp=${1:?Pass the WSL path of a Windows python.exe}
tools=$(mktemp -d /tmp/cage-gw-tools.XXXXXXXX)
trap 'rm -rf -- "$tools"' EXIT
# Accept a downloaded archive, or fetch the same version pinned by Cage for Linux.
manifest="$base/../../../packaging/linux/dependencies.json"
core=$(python3 - "$manifest" "$tools" "${2:-}" <<'PY'
import hashlib
import json
from pathlib import Path
import sys
from urllib.request import urlretrieve

spec = json.loads(Path(sys.argv[1]).read_text())["mihomo"]
if sys.argv[3]:
    archive = Path(sys.argv[3]).resolve()
else:
    archive = Path(sys.argv[2]) / spec["file"]
    urlretrieve(spec["url"], archive)
if hashlib.sha256(archive.read_bytes()).hexdigest() != spec["sha256"]:
    raise SystemExit("Mihomo archive does not match the Cage Linux dependency manifest")
print(archive)
PY
)
bash "$base/test-tools.sh" "$tools"
bash "$base/run.sh" "$wp" "$tools" "$core"
