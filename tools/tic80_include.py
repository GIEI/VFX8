"""Expand --#include directives in a TIC-80 Lua source file.

Usage: python tools/tic80_include.py game/main.lua -o game/build/main.lua
Includes are resolved relative to the file containing each directive.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


INCLUDE = re.compile(r'^\s*--#include\s+"([^"\r\n]+)"\s*$')


class IncludeError(Exception):
    pass


def expand(path: Path, stack: tuple[Path, ...], sources: set[Path]) -> str:
    try:
        resolved = path.resolve(strict=True)
        source = resolved.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError) as exc:
        raise IncludeError(f"cannot read {path}: {exc}") from exc

    if resolved in stack:
        chain = " -> ".join(str(item) for item in (*stack, resolved))
        raise IncludeError(f"include cycle: {chain}")

    sources.add(resolved)
    normalized = source.replace("\r\n", "\n").replace("\r", "\n")
    output: list[str] = []
    for number, line in enumerate(normalized.splitlines(keepends=True), start=1):
        stripped = line.rstrip("\n")
        if stripped.lstrip().startswith("--#include"):
            match = INCLUDE.fullmatch(stripped)
            if not match:
                raise IncludeError(f"invalid include at {resolved}:{number}")
            child = resolved.parent / match.group(1)
            inserted = expand(child, (*stack, resolved), sources)
            output.append(inserted)
            if inserted and not inserted.endswith("\n"):
                output.append("\n")
        else:
            output.append(line)
    return "".join(output)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="existing game Lua source")
    parser.add_argument("-o", "--output", required=True, type=Path, help="combined Lua file")
    args = parser.parse_args(argv)

    try:
        sources: set[Path] = set()
        combined = expand(args.source, (), sources)
        target = args.output.resolve()
        if target in sources:
            raise IncludeError("output would overwrite an input or included file")
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("w", encoding="utf-8", newline="\n") as stream:
            stream.write(combined)
    except (IncludeError, OSError) as exc:
        parser.exit(1, f"tic80_include: {exc}\n")

    print(f"{args.output}: {len(combined.encode('utf-8'))} bytes of Lua")
    return 0


if __name__ == "__main__":
    sys.exit(main())
