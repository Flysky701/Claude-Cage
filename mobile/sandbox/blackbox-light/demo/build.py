"""Build the recovered lightweight DEMO; see README.md for provenance."""
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "recovery"))
from rebuild import main

if __name__ == "__main__":
    main("space", HERE)
