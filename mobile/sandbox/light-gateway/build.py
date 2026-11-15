"""Build the recovered VPN gateway; see README.md for provenance."""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "recovery"))
from rebuild import main

if __name__ == "__main__":
    main("gateway", HERE)
