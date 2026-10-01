"""Portable contract checks for the four engine-specific particle modules."""

from __future__ import annotations

import unittest
import subprocess
import os
import tempfile
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENGINES = ("pico8", "picotron", "tic80", "love2d")
PRESETS = ("explosion", "sparks", "trail", "smoke", "dust")


class ParticleContractTests(unittest.TestCase):
    def read_module(self, engine: str) -> str:
        return (ROOT / "src" / engine / "particles.lua").read_text(encoding="utf-8")

    def test_all_engines_expose_the_shared_api(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                source = self.read_module(engine)
                for method in ("emit", "emit_line", "emit_area", "update", "draw", "clear", "stats"):
                    self.assertRegex(source, rf"function [\w.]+\.{method}\(")

    def test_all_engines_define_the_five_presets(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                source = self.read_module(engine)
                for preset in PRESETS:
                    self.assertIn(f'name = "{preset}"', source)

    def test_capacity_and_emission_budgets_are_hard_clamped(self) -> None:
        expected_caps = {"pico8": 96, "picotron": 512, "tic80": 256, "love2d": 1024}
        for engine, cap in expected_caps.items():
            with self.subTest(engine=engine):
                source = self.read_module(engine)
                self.assertRegex(source, rf"capacity\s*=.*{cap}")
                self.assertIn("frame_room = self.max_emit - self.frame_used", source)
                self.assertIn("pool_room = self.capacity - self.count", source)
                self.assertIn("if spawn > frame_room then spawn = frame_room end", source)
                self.assertIn("if spawn > pool_room then spawn = pool_room end", source)

    def test_update_clamps_dt_and_drops_expired_particles(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                source = self.read_module(engine)
                self.assertTrue("dt > 0.1" in source or "math.min(dt or 1 / 60, 0.1)" in source)
                self.assertIn("age >= self.life[i] then", source)
                self.assertIn("self.count = last - 1", source)

    def test_zero_lifetime_is_clamped_without_allocating_draw_work(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                source = self.read_module(engine)
                self.assertRegex(source, r"if life == nil then life = preset\.life end")
                self.assertIn("0.05", source)

    def test_numeric_zero_overrides_are_preserved(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                source = self.read_module(engine)
                self.assertIn("if life == nil then life = preset.life end", source)
                self.assertIn("local end_size = options.end_size", source)
                self.assertIn("if end_size == nil then end_size = preset.end_size end", source)

    def test_particle_page_describes_tick_budget_not_interval_budget(self) -> None:
        page = (ROOT / "docs" / "effects" / "particles.md").read_text(encoding="utf-8")
        self.assertIn("per-update emission caps", page.lower())
        self.assertIn("resets at the end of each `update()` call", page)
        self.assertNotIn("per-frame emission limit", page.lower())

    def test_screen_effect_api_exists_for_all_engines(self) -> None:
        expected = {"pico8": "vfx8_screen_fx.new", "picotron": "vfx8_screen_fx.new", "tic80": "vfx8_screen_fx.new", "love2d": "screen_fx.new"}
        for engine, constructor in expected.items():
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "screen_fx.lua").read_text(encoding="utf-8")
                self.assertIn(constructor, source)
                for method in ("add_trauma", "impulse", "flash", "shockwave", "update", "render", "clear"):
                    self.assertIn(f"methods.{method}", source)

    def test_love_runtime_contract_when_love_is_available(self) -> None:
        love = Path(r"I:\Program Files\LOVE\love.exe")
        if not love.is_file():
            self.skipTest("LÖVE is not installed at the configured path")
        with tempfile.TemporaryDirectory() as temporary:
            archive = Path(temporary) / "particle-contract.love"
            with zipfile.ZipFile(archive, "w") as package:
                package.write(ROOT / "tests" / "love2d" / "main.lua", "main.lua")
                package.write(ROOT / "tests" / "love2d" / "particle_contract.lua", "particle_contract.lua")
                package.write(ROOT / "src" / "love2d" / "particles.lua", "src/love2d/particles.lua")
        result = subprocess.run(
                [str(love), "--fused", str(archive)],
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
                cwd=str(ROOT),
                env={**os.environ, "VFX8_TEST_ROOT": str(ROOT)},
        )
        if "Failed to initialize filesystem" in result.stdout + result.stderr:
            self.skipTest("LÖVE cannot initialize its user filesystem in this sandbox")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("LÖVE particle runtime contract passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
