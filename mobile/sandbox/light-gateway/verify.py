"""Run narrow host-only configuration tests; never contacts a phone or an upstream."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jdk", required=True, type=Path)
    args = parser.parse_args()
    here = Path(os.path.realpath(__file__)).parent
    output = here / ".build"
    output.mkdir(exist_ok=True)
    suffix = ".exe" if os.name == "nt" else ""
    with tempfile.TemporaryDirectory(prefix="config-test-", dir=output) as work:
        command = [str(args.jdk / "bin" / ("javac" + suffix)), "--release", "8", "-encoding", "UTF-8", "-d", work]
        command += [str(here / file) for file in ("Upstream.java", "TunnelConfig.java", "VlessConfig.java", "tests/ConfigTest.java")]
        subprocess.run(command, check=True)
        subprocess.run([str(args.jdk / "bin" / ("java" + suffix)), "-cp", work,
                        "io.github.leexeo.cage.localcore.ConfigTest"], check=True)


if __name__ == "__main__":
    main()
