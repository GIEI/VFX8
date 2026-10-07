"""Portable API contracts for configurable pseudo-3D scenes."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENGINES = ("pico8", "picotron", "tic80", "love2d")


class Pseudo3DOptionsTests(unittest.TestCase):
    def test_scene_controls_are_available_on_every_backend(self) -> None:
        required = (
            "options.perspective or 0.62",
            "options.star_speed or 1",
            "options.star_parallax or 0.08",
            "options.star_layers or 3",
            "options.star_near or 8",
            "options.star_far or 127",
            "options.star_seed or 0",
            "options.lane_count or 3",
            "options.speed or 18",
            "options.angle ~= nil",
            "scroll_speed_x",
            "scroll_speed_y",
            "options.speed or self.speed",
            "options.z_order or object.z",
        )
        for engine in ENGINES:
            source = (ROOT / "src" / engine / "pseudo3d.lua").read_text(encoding="utf-8")
            with self.subTest(engine=engine):
                for token in required:
                    self.assertIn(token, source)
        tic80 = (ROOT / "src/tic80/pseudo3d.lua").read_text(encoding="utf-8")
        picotron = (ROOT / "src/picotron/pseudo3d.lua").read_text(encoding="utf-8")
        pico8 = (ROOT / "src/pico8/pseudo3d.lua").read_text(encoding="utf-8")
        self.assertIn("sample_step", tic80)
        self.assertIn("high_quality", picotron)
        self.assertIn("mode7_width", pico8)

    def test_external_configuration_and_engine_limits_are_documented(self) -> None:
        guide = (ROOT / "docs/effects/pseudo3d.md").read_text(encoding="utf-8")
        for token in (
            "star_parallax", "star_near", "star_far", "star_seed",
            "scroll_speed_x", "scroll_speed_y", "sample_step", "high_quality",
            "width_fraction", "options.speed", "options.z_order",
            "function love.update(dt)", "function love.draw()",
        ):
            with self.subTest(token=token):
                self.assertIn(token, guide)


if __name__ == "__main__":
    unittest.main()
