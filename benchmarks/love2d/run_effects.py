"""Run repeatable native LÖVE benchmarks for every VFX8 effect module."""

from __future__ import annotations

import argparse
import csv
import os
import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LOVE_PATHS = (Path(r"I:\Program Files\LOVE\love.exe"), Path(r"C:\Program Files\LOVE\love.exe"))
MODULES = (
    "particles",
    "screen_fx",
    "pixel_deform",
    "palette_fx",
    "pseudo3d",
    "flames",
    "electricity",
)
DEFAULT_OUTPUT = ROOT / "benchmarks" / "results" / "love2d-effects-latest.csv"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--warmup-frames", type=int, default=30)
    parser.add_argument("--sample-frames", type=int, default=600)
    parser.add_argument("--repetitions", type=int, default=5)
    parser.add_argument("--timeout", type=int, default=3600)
    args = parser.parse_args()
    for name in ("warmup_frames", "sample_frames", "repetitions", "timeout"):
        if getattr(args, name) < 1:
            parser.error(f"--{name.replace('_', '-')} must be positive")

    executable = os.environ.get("LOVE_EXECUTABLE") or shutil.which("love")
    if not executable:
        executable = next((str(path) for path in LOVE_PATHS if path.is_file()), None)
    if not executable:
        parser.error("LÖVE was not found; set LOVE_EXECUTABLE or add love to PATH")

    runtime_version = os.environ.get("LOVE_VERSION", "unavailable")
    if runtime_version == "unavailable" and os.name == "nt":
        escaped = str(executable).replace("'", "''")
        version_result = subprocess.run(
            ["powershell", "-NoProfile", "-Command",
             f"(Get-Item -LiteralPath '{escaped}').VersionInfo.ProductVersion"],
            capture_output=True, text=True, check=False,
        )
        if version_result.returncode == 0 and version_result.stdout.strip():
            runtime_version = version_result.stdout.strip()

    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="vfx8-love-effects-") as temporary:
        game = Path(temporary)
        package = game / "vfx8"
        package.mkdir()
        shutil.copy2(ROOT / "benchmarks" / "love2d" / "conf.lua", game / "conf.lua")
        shutil.copy2(ROOT / "benchmarks" / "love2d" / "effects.lua", game / "main.lua")
        for module in MODULES:
            shutil.copy2(ROOT / "src" / "love2d" / f"{module}.lua", package / f"{module}.lua")
        env = {
            **os.environ,
            "VFX8_EFFECT_BENCH_OUTPUT": str(output),
            "VFX8_EFFECT_BENCH_WARMUP": str(args.warmup_frames),
            "VFX8_EFFECT_BENCH_SAMPLES": str(args.sample_frames),
            "VFX8_EFFECT_BENCH_REPETITIONS": str(args.repetitions),
        }
        try:
            result = subprocess.run(
                [executable, str(game)], cwd=ROOT, env=env, capture_output=True,
                text=True, timeout=args.timeout, check=False,
            )
        except subprocess.TimeoutExpired as error:
            print(f"LÖVE effects benchmark exceeded {args.timeout} seconds.", file=sys.stderr)
            if error.stdout:
                print(error.stdout, file=sys.stderr)
            if error.stderr:
                print(error.stderr, file=sys.stderr)
            return 1

    print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)
    if result.returncode:
        return result.returncode
    if not output.is_file():
        print("LÖVE exited without writing effects benchmark results.", file=sys.stderr)
        return 1
    lines = output.read_text(encoding="utf-8").splitlines()
    expected = 3 * args.repetitions * (len(MODULES) + 1) * 3
    if len(lines) != expected + 1:
        print(f"Expected {expected} benchmark records, found {max(0, len(lines) - 1)}.", file=sys.stderr)
        return 1
    with output.open(newline="", encoding="utf-8") as source:
        rows = list(csv.DictReader(source))
    required_fields = ("quality", "effect", "scenario", "run", "sample_frames")
    if any(any(not row[field] for field in required_fields) for row in rows):
        print("Benchmark CSV contains an empty required field.", file=sys.stderr)
        return 1
    expected_effects = {"baseline", *MODULES}
    if {row["effect"] for row in rows} != expected_effects:
        print("Benchmark CSV does not contain the expected effect set.", file=sys.stderr)
        return 1
    for row in rows:
        if row["scenario"] == "saturated" and row["effect"] != "baseline":
            if int(row["active_items"]) != int(row["capacity"]):
                print(f"Saturated pool was not filled: {row['quality']} {row['effect']} run {row['run']}.", file=sys.stderr)
                return 1
        expected_samples = args.sample_frames if row["scenario"] == "saturated" else min(args.sample_frames, 120)
        if int(row["sample_frames"]) != expected_samples:
            print(f"Unexpected sample window in {row['quality']} {row['effect']} {row['scenario']}.", file=sys.stderr)
            return 1
    runtime = runtime_version
    for line in result.stdout.splitlines():
        if line.startswith("VFX8_LOVE_RUNTIME,"):
            runtime = line.split(",", 2)[1]
            break
    summary = output.with_suffix(".md")
    cpu = os.environ.get("PROCESSOR_IDENTIFIER", "unavailable")
    summarized = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks" / "love2d" / "summarize_effects.py"),
         "--input", str(output), "--output", str(summary), "--runtime", runtime,
         "--host-os", platform.platform(), "--cpu", cpu],
        cwd=ROOT, text=True, check=False,
    )
    if summarized.returncode:
        return summarized.returncode
    print(f"Saved {expected} native LÖVE effect measurements to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
