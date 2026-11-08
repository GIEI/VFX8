"""Portable API and integration checks for rain and snow on each target."""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ENGINES = ("pico8", "picotron", "love2d", "tic80")
RAIN_METHODS = ("set_intensity", "set_angle", "update", "draw", "clear", "stats")
SNOW_METHODS = ("set_intensity", "add_surface", "set_surface", "clear_surfaces", "update", "draw", "clear", "stats")


class WeatherModuleContractTests(unittest.TestCase):
    def test_all_engines_have_bounded_rain_and_snow_apis(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                limits = {"pico8": {"rain": 64, "snow": 40}, "picotron": {"rain": 192, "snow": 128}, "love2d": {"rain": 512, "snow": 320}, "tic80": {"rain": 96, "snow": 80}}
                for effect, methods in (("rain", RAIN_METHODS), ("snow", SNOW_METHODS)):
                    source = (ROOT / "src" / engine / f"{effect}.lua").read_text(encoding="utf-8")
                    for method in methods:
                        self.assertRegex(source, rf"function [\w.]+\.{method}\(")
                    for intensity in ("light", "heavy", "storm"):
                        self.assertIn(f'"{intensity}"', source)
                    self.assertRegex(source, rf"min\({limits[engine][effect]},")
                    self.assertIn("dt or 1 / 60", source)
                    self.assertIn("0.1", source)

    def test_rain_has_vertical_and_clamped_oblique_directions(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "rain.lua").read_text(encoding="utf-8")
                self.assertIn("set_angle", source)
                self.assertRegex(source, r"-35,\s*min\(35")
                self.assertIn("lengths", source)
                self.assertIn("self.max_length", source)
                self.assertNotIn("self.length[i]", source)

    def test_snow_has_bounded_surface_and_one_to_three_second_settling(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "snow.lua").read_text(encoding="utf-8")
                self.assertIn("surface_count >= 32", source)
                self.assertIn("settle_min", source)
                self.assertIn("settle_max", source)
                self.assertIn("min(3", source)
                self.assertIn("settle_age", source)

    def test_desktop_and_console_demos_expose_weather_effects(self) -> None:
        for path in (
            ROOT / "examples/love2d/demo_extension.lua",
            ROOT / "examples/picotron/demo_extension.lua",
            ROOT / "examples/tic80/demo_extension.lua",
        ):
            source = path.read_text(encoding="utf-8")
            self.assertRegex(source, r"fx\[8\]")
            self.assertRegex(source, r"fx\[9\]")
        self.assertIn('"rain"', (ROOT / "examples/love2d/main.lua").read_text(encoding="utf-8"))
        self.assertIn('"snow"', (ROOT / "examples/picotron/main.lua").read_text(encoding="utf-8"))
        self.assertIn('"snow"', (ROOT / "examples/tic80/demo.lua").read_text(encoding="utf-8"))

    def test_pico8_weather_player_is_drawn_without_a_gray_backing(self) -> None:
        source = (ROOT / "examples/integration_game/pico8/weather.p8").read_text(encoding="utf-8")
        self.assertNotIn("rectfill(player.x-8,player.y-5,player.x+7,player.y+5,5)", source)
        self.assertIn("rectfill(player.x-4,player.y-4,player.x+3,player.y+3,8)", source)
        self.assertIn("effect:set_surface(surface,player.x-4,player.y-4,8)", source)

    def test_love_weather_runtime_contract_when_love_is_available(self) -> None:
        love = Path(r"I:\Program Files\LOVE\love.exe")
        if not love.is_file():
            self.skipTest("LÖVE is not installed at the configured path")
        with tempfile.TemporaryDirectory() as temporary:
            game_folder = Path(temporary) / "love-weather-contract"
            game_folder.mkdir()
            result_file = Path(temporary) / "weather-result.txt"
            for name in ("weather_main.lua", "rain_contract.lua", "snow_contract.lua"):
                target_name = "main.lua" if name == "weather_main.lua" else name
                shutil.copy2(ROOT / "tests" / "love2d" / name, game_folder / target_name)
            try:
                result = subprocess.run(
                    [str(love), str(game_folder)], capture_output=True, text=True, timeout=8,
                    check=False, cwd=str(ROOT),
                    env={**os.environ, "VFX8_TEST_ROOT": str(ROOT), "VFX8_TEST_RESULT": str(result_file)},
                )
            except subprocess.TimeoutExpired:
                self.skipTest("LÖVE did not exit the standalone weather harness in time")
            if "Failed to initialize filesystem" in result.stdout + result.stderr:
                self.skipTest("LÖVE cannot initialize its user filesystem in this sandbox")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(result_file.read_text(encoding="utf-8"), "passed")
            self.assertIn("LOVE rain runtime contract passed", result.stdout)
            self.assertIn("LOVE snow runtime contract passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
