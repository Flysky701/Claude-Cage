"""Pinned upstream C libraries for the API36 path; fetch only with --fetch."""
import argparse
import hashlib
from pathlib import Path
import urllib.request
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[5]
CACHE = ROOT / "mobile/.build/gbox-mod/android16-native/deps"
PACKAGES = (
    ("bytehook", "com/bytedance", "1.1.2", "b3c85fec26e9f41fd3608851ac3fe412573ef4ce6ef83911b92d610d3bab7215", ("libbytehook.so",)),
    ("shadowhook", "com/bytedance/android", "2.0.1", "2cad01ff4d59542958775e19f281981a7e84b39670b5fae75905b8511e10c7cd",
     ("libshadowhook.so", "libshadowhook_nothing.so")),
)


def prepare(output: Path, fetch=False):
    output.mkdir(parents=True, exist_ok=True)
    result, records = {}, []
    for name, group, version, digest, libraries in PACKAGES:
        archive = CACHE / f"{name}-{version}.aar"
        url = f"https://repo.maven.apache.org/maven2/{group}/{name}/{version}/{archive.name}"
        if not archive.exists():
            if not fetch:
                raise FileNotFoundError("Run privacy/native/dependencies.py --fetch for pinned official AARs")
            data = urllib.request.urlopen(url, timeout=60).read()
            if hashlib.sha256(data).hexdigest() != digest:
                raise ValueError("Downloaded dependency hash mismatch: " + name)
            CACHE.mkdir(parents=True, exist_ok=True)
            archive.write_bytes(data)
        if hashlib.sha256(archive.read_bytes()).hexdigest() != digest:
            raise ValueError("Cached dependency hash mismatch: " + name)
        with ZipFile(archive) as source:
            for library in libraries:
                raw = source.read("jni/arm64-v8a/" + library)
                if raw[:6] != b"\x7fELF\x02\x01" or int.from_bytes(raw[18:20], "little") != 183:
                    raise ValueError("Dependency architecture mismatch")
                path = output / library
                path.write_bytes(raw)
                result["lib/arm64-v8a/" + library] = path
        records.append(dict(name=name, version=version, sha256=digest, source=url))
    notices = Path(__file__).resolve().parent / "third_party/NOTICE.txt"
    result["assets/cage-privacy/THIRD-PARTY-NOTICES.txt"] = notices
    return result, records


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fetch", action="store_true")
    args = parser.parse_args()
    files, _ = prepare(CACHE / "verified", args.fetch)
    print("Verified entries: " + ", ".join(sorted(files)))
