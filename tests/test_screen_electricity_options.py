"""Portable contract checks for screen and lightning tuning options."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENGINES = ("pico8", "picotron", "tic80", "love2d")


class ScreenElectricityOptionTests(unittest.TestCase):
    def test_screen_options_are_wired_in_each_backend(self) -> None:
        options = (
            "shake_intensity", "shake_decay", "shake_frequency", "shake_randomness",
            "shake_envelope", "direction_x", "flash_intensity", "flash_mode",
            "max_radius", "thickness", "falloff", "ripple_strength", "ripple_width",
        )
        for engine in ENGINES:
            source = (ROOT / "src" / engine / "screen_fx.lua").read_text(encoding="utf-8")
            with self.subTest(engine=engine):
                for option in options:
                    if option.startswith("ripple_") and engine != "love2d":
                        continue
                    self.assertIn(option, source)
                self.assertIn("options.capacity", source)
                self.assertIn("options.seed", source)

    def test_electricity_options_are_wired_in_each_backend(self) -> None:
        options = (
            "segments", "jaggedness", "branches", "branch_probability", "branch_angle",
            "branch_length", "life", "width", "color", "core_color", "flicker",
            "flicker_speed", "pulse_count", "bolt_count", "max_emit", "options.seed",
        )
        for engine in ENGINES:
            source = (ROOT / "src" / engine / "electricity.lua").read_text(encoding="utf-8")
            with self.subTest(engine=engine):
                for option in options:
                    self.assertIn(option, source)
                self.assertIn("options.capacity", source)
                self.assertIn("frame_used >= self.max_emit", source)

    def test_external_integration_docs_show_event_update_and_draw_flow(self) -> None:
        screen = (ROOT / "docs" / "effects" / "screen_fx.md").read_text(encoding="utf-8")
        electricity = (ROOT / "docs" / "effects" / "electricity.md").read_text(encoding="utf-8")
        for name, document in (("screen", screen), ("electricity", electricity)):
            with self.subTest(effect=name):
                self.assertIn("function on_hit", document)
                self.assertIn("update(dt)", document)
                self.assertTrue("function love.draw()" in document or "function draw_game()" in document)


if __name__ == "__main__":
    unittest.main()
