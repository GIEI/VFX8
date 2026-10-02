"""Run repeatable native LÖVE particle benchmarks and save raw measurements."""

from __future__ import annotations

import argparse
import os
import shutil
import sys
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LOVE_PATHS = (
    Path(r"I:\Program Files\LOVE\love.exe"),
    Path(r"C:\Program Files\LOVE\love.exe"),
)
OUTPUT = ROOT / "benchmarks" / "results" / "love2d-particles-latest.csv"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    executable = os.environ.get("LOVE_EXECUTABLE") or shutil.which("love")
    if not executable:
        executable = next((str(path) for path in LOVE_PATHS if path.is_file()), None)
    if not executable:
        parser.error("LÖVE was not found; set LOVE_EXECUTABLE or add love to PATH")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="vfx8-love-benchmark-") as temporary:
        game = Path(temporary)
        package = game / "vfx8"
        package.mkdir()
        shutil.copy2(ROOT / "benchmarks" / "love2d" / "conf.lua", game / "conf.lua")
        shutil.copy2(ROOT / "benchmarks" / "love2d" / "main.lua", game / "main.lua")
        shutil.copy2(ROOT / "src" / "love2d" / "particles.lua", package / "particles.lua")
        result = subprocess.run(
            [executable, str(game)],
            cwd=ROOT,
            env={**os.environ, "VFX8_BENCH_OUTPUT": str(args.output.resolve())},
            capture_output=True,
            text=True,
            timeout=180,
            check=False,
        )

    print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)
    if result.returncode:
        return result.returncode
    if not args.output.is_file():
        print("LÖVE exited without writing benchmark results.")
        return 1
    lines = args.output.read_text(encoding="utf-8").splitlines()
    if len(lines) != 16:
        print(f"Expected 15 benchmark records, found {max(0, len(lines) - 1)}.")
        return 1
    print(f"Saved 15 native LÖVE measurements to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
