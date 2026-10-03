"""Create a clean, versioned VFX8 source archive without local build data."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import zipfile


ROOT_FILES = ("README.md", "LICENSE", "CHANGELOG.md", "RELEASE_NOTES.md")
SOURCE_DIRS = ("src", "docs", "examples", "tests", "tools", "benchmarks")
EXCLUDED_DIRS = {"build", "__pycache__", ".userdata", "runtime-data", "love_mcp"}


def collect_files(root: Path) -> list[Path]:
    files = [root / name for name in ROOT_FILES if (root / name).is_file()]
    for dirname in SOURCE_DIRS:
        base = root / dirname
        if not base.is_dir():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            relative = path.relative_to(root)
            if any(part in EXCLUDED_DIRS for part in relative.parts):
                continue
            if path.suffix in {".pyc", ".pyo"}:
                continue
            files.append(path)
    return sorted(files, key=lambda item: item.relative_to(root).as_posix().lower())


def write_archive(root: Path, output: Path, version: str) -> int:
    files = collect_files(root)
    prefix = f"vfx8-{version}"
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            relative = path.relative_to(root).as_posix()
            info = zipfile.ZipInfo(f"{prefix}/{relative}", date_time=(2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    return len(files)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", default="0.1.0", help="Archive version (default: 0.1.0).")
    parser.add_argument("--output", type=Path, help="Output ZIP path (default: .tmp/vfx8-VERSION-source.zip).")
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?", args.version):
        parser.error("version must follow the numeric semantic version format, optionally with a prerelease suffix")

    root = Path(__file__).resolve().parents[1]
    output = args.output or root / ".tmp" / f"vfx8-{args.version}-source.zip"
    output = output.resolve()
    if output == root or root in output.parents:
        relative = output.relative_to(root)
        if not relative.parts or relative.parts[0] not in {".tmp", "dist"}:
            parser.error("an output inside the repository must be placed under .tmp/ or dist/")
    count = write_archive(root, output, args.version)
    print(f"Created {output} with {count} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
