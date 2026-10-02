"""Stage the LÖVE demo with the current source module and launch it."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EXAMPLE = Path(__file__).resolve().parent
BUILD = EXAMPLE / "build"
LOVE_PATHS = (
    Path(r"I:\Program Files\LOVE\love.exe"),
    Path(r"C:\Program Files\LOVE\love.exe"),
)
MCP_LUA = Path.home() / ".codex" / "mcp-servers" / "love2d-mcp" / "lua"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mcp", action="store_true", help="enable the optional local love2d-mcp bridge")
    parser.add_argument("--stage-only", action="store_true", help="prepare the runnable game folder without launching LÖVE")
    args = parser.parse_args()

    module = ROOT / "src" / "love2d" / "particles.lua"
    screen_module = ROOT / "src" / "love2d" / "screen_fx.lua"
    deform_module = ROOT / "src" / "love2d" / "pixel_deform.lua"
    palette_module = ROOT / "src" / "love2d" / "palette_fx.lua"
    pseudo3d_module = ROOT / "src" / "love2d" / "pseudo3d.lua"
    flames_module = ROOT / "src" / "love2d" / "flames.lua"
    electricity_module = ROOT / "src" / "love2d" / "electricity.lua"
    for required in (module, screen_module, deform_module, palette_module, pseudo3d_module, flames_module, electricity_module):
        if not required.is_file():
            print(f"Missing effect module: {required}", file=sys.stderr)
            return 1

    BUILD.mkdir(parents=True, exist_ok=True)
    shutil.copy2(EXAMPLE / "main.lua", BUILD / "main.lua")
    shutil.copy2(EXAMPLE / "demo_extension.lua", BUILD / "demo_extension.lua")
    marker = BUILD / "vfx8_mcp_enabled"
    if args.mcp:
        if not (MCP_LUA / "love_mcp.lua").is_file():
            print(f"love2d-mcp Lua bridge not found: {MCP_LUA}", file=sys.stderr)
            return 1
        shutil.copy2(MCP_LUA / "love_mcp.lua", BUILD / "love_mcp.lua")
        shutil.copytree(MCP_LUA / "love_mcp", BUILD / "love_mcp", dirs_exist_ok=True)
        marker.write_text("enabled\n", encoding="utf-8")
    elif marker.exists():
        marker.unlink()
    package = BUILD / "vfx8"
    package.mkdir(parents=True, exist_ok=True)
    shutil.copy2(module, package / "particles.lua")
    shutil.copy2(screen_module, package / "screen_fx.lua")
    shutil.copy2(deform_module, package / "pixel_deform.lua")
    shutil.copy2(palette_module, package / "palette_fx.lua")
    shutil.copy2(pseudo3d_module, package / "pseudo3d.lua")
    shutil.copy2(flames_module, package / "flames.lua")
    shutil.copy2(electricity_module, package / "electricity.lua")

    required_staged = (BUILD / "main.lua", BUILD / "demo_extension.lua", package / "particles.lua", package / "screen_fx.lua", package / "pixel_deform.lua", package / "palette_fx.lua", package / "pseudo3d.lua", package / "flames.lua", package / "electricity.lua")
    missing = [path for path in required_staged if not path.is_file()]
    if missing:
        print("Staging failed; required game files are missing:", file=sys.stderr)
        for path in missing:
            print(f"  {path}", file=sys.stderr)
        return 1
    if args.stage_only:
        print(f"LOVE demo staged successfully: {BUILD}")
        print(f"Launch that folder with LOVE, or rerun this script without --stage-only.")
        return 0

    executable = os.environ.get("LOVE_EXECUTABLE") or shutil.which("love")
    if not executable:
        executable = next((str(path) for path in LOVE_PATHS if path.is_file()), None)
    if not executable:
        print("LÖVE was not found. Set LOVE_EXECUTABLE or add love to PATH.", file=sys.stderr)
        return 127
    return subprocess.call([executable, str(BUILD)])


if __name__ == "__main__":
    raise SystemExit(main())
