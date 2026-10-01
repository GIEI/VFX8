"""Checks for the build-time include path used by TIC-80 projects."""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[2] / "tools" / "tic80_include.py"


class IncludeTests(unittest.TestCase):
    def run_builder(self, source: Path, output: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(source), "-o", str(output)],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_nested_include_preserves_existing_game(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "vfx8").mkdir()
            (root / "vfx8" / "base.lua").write_text("vfx8 = {}\n", encoding="utf-8")
            (root / "vfx8" / "particles.lua").write_text(
                '--#include "base.lua"\nvfx8.particles = true\n', encoding="utf-8"
            )
            game = root / "game.lua"
            game.write_text(
                '--#include "vfx8/particles.lua"\nfunction TIC() cls(0) end\n', encoding="utf-8"
            )
            output = root / "build" / "game.lua"
            result = self.run_builder(game, output)

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                output.read_text(encoding="utf-8"),
                "vfx8 = {}\nvfx8.particles = true\nfunction TIC() cls(0) end\n",
            )

    def test_cycle_fails_without_writing_output(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "game.lua"
            source.write_text('--#include "game.lua"\n', encoding="utf-8")
            output = root / "built.lua"
            result = self.run_builder(source, output)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("include cycle", result.stderr)
            self.assertFalse(output.exists())

    def test_refuses_to_overwrite_included_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "game.lua"
            included = root / "effect.lua"
            source.write_text('--#include "effect.lua"\n', encoding="utf-8")
            included.write_text("vfx8 = {}\n", encoding="utf-8")
            result = self.run_builder(source, included)

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("would overwrite", result.stderr)
            self.assertEqual(included.read_text(encoding="utf-8"), "vfx8 = {}\n")


if __name__ == "__main__":
    unittest.main()
