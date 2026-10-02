"""Portable contract checks for the four engine-specific particle modules."""

from __future__ import annotations

import unittest
import subprocess
import os
import shutil
import tempfile
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
                self.assertIn("particle_age >= lives[i] then", source)
                self.assertIn("count = last - 1", source)
                self.assertIn("self.count = count", source)

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

    def test_pico8_particle_stress_carts_cover_each_profile(self) -> None:
        expected = {"low": 24, "medium": 48, "high": 72}
        helper = (ROOT / "tests" / "pico8" / "particle_stress.lua").read_text(encoding="utf-8")
        self.assertIn("600", helper)
        self.assertIn("VFX8_PARTICLE_STRESS", helper)
        for profile, capacity in expected.items():
            with self.subTest(profile=profile):
                cart = (ROOT / "tests" / "pico8" / f"particle_stress_{profile}.p8").read_text(encoding="utf-8")
                self.assertIn("#include ../../src/pico8/particles.lua", cart)
                self.assertIn(f'vfx8_particle_stress("{profile}", {capacity})', cart)

    def test_love_particle_benchmark_is_reproducible_and_saturated(self) -> None:
        root = ROOT / "benchmarks" / "love2d"
        harness = (root / "main.lua").read_text(encoding="utf-8")
        runner = (root / "run.py").read_text(encoding="utf-8")
        self.assertIn('{"baseline", "typical", "saturated"}', harness)
        self.assertIn("local repetitions = 5", harness)
        self.assertIn("local warmup_frames = 120", harness)
        self.assertIn("local sample_frames = 600", harness)
        self.assertIn('capacity = 640, max_emit = 640', harness)
        self.assertIn('"particles.lua"', runner)
        self.assertTrue((ROOT / "benchmarks" / "results" / "love2d-particles-latest.csv").is_file())

    def test_screen_effect_api_exists_for_all_engines(self) -> None:
        expected = {"pico8": "vfx8_screen_fx.new", "picotron": "vfx8_screen_fx.new", "tic80": "vfx8_screen_fx.new", "love2d": "screen_fx.new"}
        for engine, constructor in expected.items():
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "screen_fx.lua").read_text(encoding="utf-8")
                self.assertIn(constructor, source)
                for method in ("add_trauma", "impulse", "flash", "shockwave", "update", "get_shake_offset", "draw_overlays", "render", "clear"):
                    self.assertIn(f"methods.{method}", source)

    def test_love_screen_effect_has_bounded_canvas_shader_ripple(self) -> None:
        source = (ROOT / "src" / "love2d" / "screen_fx.lua").read_text(encoding="utf-8")
        doc = (ROOT / "docs" / "effects" / "screen_fx.md").read_text(encoding="utf-8")
        self.assertIn("graphics.newCanvas", source)
        self.assertIn("graphics.newShader", source)
        self.assertIn("Texel(texture, samplePoint)", source)
        self.assertIn("if second_canvas ~= nil then return false end", source)
        self.assertIn("options.ripple ~= false", source)
        self.assertIn("ringStrength", source)
        self.assertIn("framebuffer displacement", doc)

    def test_pixel_deformation_helpers_exist_for_all_engines(self) -> None:
        expected = {"pico8": "vfx8_pixel_deform.new", "picotron": "vfx8_pixel_deform.new", "tic80": "vfx8_pixel_deform.new", "love2d": "pixel_deform.new"}
        for engine, constructor in expected.items():
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "pixel_deform.lua").read_text(encoding="utf-8")
                self.assertIn(constructor, source)
                for method in ("wave_offset", "set_squash", "set_rotation", "rotate_point", "rotation_bounds", "update", "scale", "visible", "clear"):
                    self.assertIn(f"methods.{method}", source)
                self.assertIn("local x4, y4 = left - self.rotation_x, bottom - self.rotation_y", source)
                self.assertIn("local x2, y2 = right - self.rotation_x, top - self.rotation_y", source)
                self.assertIn('mode == "checker"', source)
                if engine != "pico8":
                    self.assertIn('mode == "spiral"', source)

    def test_palette_effect_api_and_demos_exist_for_all_engines(self) -> None:
        constructors = {
            "pico8": "vfx8_palette_fx.new",
            "picotron": "vfx8_palette_fx.new",
            "tic80": "vfx8_palette_fx.new",
            "love2d": "palette_fx.new",
        }
        for engine, constructor in constructors.items():
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "palette_fx.lua").read_text(encoding="utf-8")
                self.assertIn(constructor, source)
                self.assertIn("cycle_shift", source)
                self.assertIn("pulse_phase", source)
                for method in ("set_cycle", "clear_cycle", "set_filter", "set_filter_map", "clear_filter", "set_pulse", "flash", "set_invert_palette", "invert", "clear_invert", "map_color", "update", "clear"):
                    self.assertIn(f"methods.{method}", source)
                adapter = (ROOT / "examples" / engine / "demo_extension.lua").read_text(encoding="utf-8")
                self.assertIn("fx[4]", adapter)
                self.assertIn("map_color", adapter)
                self.assertIn('set_filter("night")', adapter)
                self.assertIn("set_filter_map", adapter)
                self.assertIn("set_invert_palette", adapter)
                self.assertIn("negative flash", adapter)
                self.assertIn("custom dusk map", adapter)

        pico_contract = (ROOT / "tests" / "pico8" / "palette_contract.p8").read_text(encoding="utf-8")
        self.assertIn("#include ../../src/pico8/palette_fx.lua", pico_contract)
        self.assertIn("palette:set_filter_map", pico_contract)
        self.assertIn("palette:map_color", pico_contract)
        self.assertIn("cached cycle phase did not advance", pico_contract)
        stress_cart = (ROOT / "tests" / "pico8" / "palette_map_stress.p8").read_text(encoding="utf-8")
        self.assertIn("PICO8_PALETTE_MAP", stress_cart)

        love_stage = (ROOT / "examples" / "love2d" / "stage_demo.py").read_text(encoding="utf-8")
        self.assertIn('package / "palette_fx.lua"', love_stage)
        for demo in ("pico8/demo.p8", "picotron/main.lua", "tic80/demo.lua"):
            with self.subTest(demo=demo):
                source = (ROOT / "examples" / demo).read_text(encoding="utf-8")
                self.assertIn("map_color" if demo == "pico8/demo.p8" else "scene_color", source)

    def test_pseudo3d_contract_and_all_demo_slots_exist(self) -> None:
        constructors = {"pico8": "vfx8_pseudo3d.new", "picotron": "vfx8_pseudo3d.new", "tic80": "vfx8_pseudo3d.new", "love2d": "pseudo3d.new"}
        for engine, constructor in constructors.items():
            with self.subTest(engine=engine):
                module = (ROOT / "src" / engine / "pseudo3d.lua").read_text(encoding="utf-8")
                adapter = (ROOT / "examples" / engine / "demo_extension.lua").read_text(encoding="utf-8")
                self.assertIn(constructor, module)
                self.assertIn("methods.set_mode7", module)
                for method in ("update", "draw", "add_object", "clear_objects", "set_camera", "set_road", "project", "project_road", "clear"):
                    self.assertIn(f"methods.{method}", module)
                for profile in ("low", "medium", "high"):
                    self.assertIn(profile, module)
                self.assertNotIn("math.random", module)
                if engine != "love2d":
                    self.assertNotIn("rnd(", module)
                self.assertIn("fx[5]", adapter)
                self.assertIn("add_object", adapter)
                self.assertNotIn("pseudo:draw({", adapter, "demo draw should reuse its color table")
                if engine != "love2d":
                    self.assertIn("local empty_colors = {}", module)
                else:
                    self.assertIn("draw_colors = {}", module)
                    self.assertNotIn("options.sky or {", module)
        for demo in ("pico8/pseudo3d_demo.p8", "picotron/main.lua", "tic80/demo.lua", "love2d/main.lua"):
            with self.subTest(demo=demo):
                source = (ROOT / "examples" / demo).read_text(encoding="utf-8")
                self.assertIn("road:draw" if demo == "pico8/pseudo3d_demo.p8" else "active.draw_scene", source)
        doc = (ROOT / "docs" / "effects" / "pseudo3d.md").read_text(encoding="utf-8")
        self.assertIn("## Support status", doc)
        self.assertIn("PICO-8", doc)
        self.assertIn("TIC-80", doc)
        self.assertIn("add_object", doc)
        stage = (ROOT / "examples" / "love2d" / "stage_demo.py").read_text(encoding="utf-8")
        self.assertIn('package / "pseudo3d.lua"', stage)
        benchmark = (ROOT / "benchmarks" / "README.md").read_text(encoding="utf-8")
        self.assertIn("Current verification", benchmark)
        self.assertIn("results/template.md", benchmark)

    def test_pseudo3d_road_controls_and_projection_are_consistent_across_engines(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine):
                module = (ROOT / "src" / engine / "pseudo3d.lua").read_text(encoding="utf-8")
                self.assertEqual(module.count("function methods.project_road("), 1)
                self.assertIn("function methods.set_road(", module)
                self.assertIn("function methods.project_road(", module)
                self.assertIn("local depth =", module)
                self.assertIn("local half = self.road_width * vertical / self.camera_height", module)
                self.assertIn("- self.camera_x * depth + bend", module)
                self.assertIn("self.curve * self.curve_strength * depth * depth", module)
                self.assertIn("self:project_road(object.x, object.z, object.size)", module)
                self.assertIn("self.lane_count", module)
                adapter = (ROOT / "examples" / engine / "demo_extension.lua").read_text(encoding="utf-8")
                self.assertIn("pseudo_curve", adapter)
                self.assertIn("set_road", adapter)
        doc = (ROOT / "docs" / "effects" / "pseudo3d.md").read_text(encoding="utf-8")
        self.assertIn("project_road(lateral, depth, size)", doc)
        self.assertIn("untextured road remains available", doc)

    def test_mode7_has_engine_specific_texture_backends(self) -> None:
        expected = {
            "pico8": "tline(left, y, right, y",
            "picotron": "tline3d(texture.source",
            "tic80": "peek4(0xc000 + ty * 128 + tx)",
            "love2d": "newShader",
        }
        for engine, marker in expected.items():
            with self.subTest(engine=engine):
                module = (ROOT / "src" / engine / "pseudo3d.lua").read_text(encoding="utf-8")
                self.assertIn(marker, module)
                adapter = (ROOT / "examples" / engine / "demo_extension.lua").read_text(encoding="utf-8")
                self.assertIn("set_mode7", adapter)

    def test_flames_api_budgets_demos_and_documentation_exist_for_all_engines(self) -> None:
        constructors = {"pico8": "vfx8_flames.new", "picotron": "vfx8_flames.new", "tic80": "vfx8_flames.new", "love2d": "flames.new"}
        for engine, constructor in constructors.items():
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "flames.lua").read_text(encoding="utf-8")
                self.assertIn(constructor, source)
                for method in ("emit_jet", "emit_campfire", "update", "draw", "clear", "stats"):
                    table_name = "methods" if engine in ("love2d", "picotron", "tic80") else "m"
                    self.assertIn(f"function {table_name}.{method}", source)
                self.assertIn("capacity", source)
                self.assertTrue("emission" in source or "emits" in source)
                adapter = (ROOT / "examples" / engine / "demo_extension.lua").read_text(encoding="utf-8")
                self.assertIn("fx[6]", adapter)
                self.assertIn("emit_jet", adapter)
                self.assertIn("emit_campfire", adapter)
        doc = (ROOT / "docs" / "effects" / "flames.md").read_text(encoding="utf-8")
        self.assertIn("### `emit_jet", doc)
        self.assertIn("### `emit_campfire", doc)
        self.assertIn("nem", doc.lower())
        for demo in ("pico8/flames_electricity_demo.p8", "picotron/main.lua", "tic80/demo.lua", "love2d/main.lua"):
            with self.subTest(demo=demo):
                self.assertIn('"flames"', (ROOT / "examples" / demo).read_text(encoding="utf-8"))
        stage = (ROOT / "examples" / "love2d" / "stage_demo.py").read_text(encoding="utf-8")
        self.assertIn('package / "flames.lua"', stage)

    def test_electricity_api_budgets_demos_and_documentation_exist_for_all_engines(self) -> None:
        constructors = {"pico8": "vfx8_electricity.new", "picotron": "vfx8_electricity.new", "tic80": "vfx8_electricity.new", "love2d": "electricity.new"}
        for engine, constructor in constructors.items():
            with self.subTest(engine=engine):
                source = (ROOT / "src" / engine / "electricity.lua").read_text(encoding="utf-8")
                self.assertIn(constructor if engine == "love2d" else "function electricity.new", source)
                self.assertIn("function methods.strike", source)
                for method in ("update", "draw", "clear", "stats"):
                    self.assertIn(f"function methods.{method}", source)
                self.assertIn("max_emit", source)
                self.assertIn("point_x", source)
                adapter = (ROOT / "examples" / engine / "demo_extension.lua").read_text(encoding="utf-8")
                self.assertIn("fx[7]", adapter)
                self.assertIn(":strike(", adapter)
        doc = (ROOT / "docs" / "effects" / "electricity.md").read_text(encoding="utf-8")
        self.assertIn("### `strike", doc)
        self.assertIn("PICO-8", doc)
        for demo in ("pico8/flames_electricity_demo.p8", "picotron/main.lua", "tic80/demo.lua", "love2d/main.lua"):
            with self.subTest(demo=demo):
                self.assertIn('"electricity"', (ROOT / "examples" / demo).read_text(encoding="utf-8"))
        stage = (ROOT / "examples" / "love2d" / "stage_demo.py").read_text(encoding="utf-8")
        self.assertIn('package / "electricity.lua"', stage)

    def test_pico8_core_profile_cart_covers_core_effects_and_profiles(self) -> None:
        cart = (ROOT / "tests" / "pico8" / "profile_contract.p8").read_text(encoding="utf-8")
        for module in ("particles", "screen_fx", "pixel_deform", "palette_fx"):
            with self.subTest(module=module):
                self.assertIn(f"#include ../../src/pico8/{module}.lua", cart)
        for quality in ("low", "medium", "high"):
            self.assertIn(f'"{quality}"', cart)
        self.assertIn("VFX8_CORE_PROFILE_CONTRACT,PASS", cart)

    def test_pico8_advanced_profile_cart_covers_remaining_effects(self) -> None:
        cart = (ROOT / "tests" / "pico8" / "profile_contract_advanced.p8").read_text(encoding="utf-8")
        for module in ("pseudo3d", "flames", "electricity"):
            with self.subTest(module=module):
                self.assertIn(f"#include ../../src/pico8/{module}.lua", cart)
        for quality in ("low", "medium", "high"):
            self.assertIn(f'"{quality}"', cart)
        self.assertIn("VFX8_ADVANCED_PROFILE_CONTRACT,PASS", cart)

    def test_pico8_electricity_contract_cart_exists(self) -> None:
        cart = (ROOT / "tests" / "pico8" / "electricity_contract.p8").read_text(encoding="utf-8")
        self.assertIn("#include ../../src/pico8/electricity.lua", cart)
        self.assertIn("vfx8_electricity.new", cart)
        self.assertIn("strike", cart)
        demo = (ROOT / "examples" / "pico8" / "electricity_demo.p8").read_text(encoding="utf-8")
        self.assertIn("#include ../../src/pico8/electricity.lua", demo)
        self.assertIn("O: STRIKE", demo)

    def test_pico8_showcase_carts_include_only_their_effect_groups(self) -> None:
        cart = (ROOT / "tests" / "pico8" / "profile_contract.p8").read_text(encoding="utf-8")
        advanced = (ROOT / "tests" / "pico8" / "profile_contract_advanced.p8").read_text(encoding="utf-8")
        self.assertNotIn("pseudo3d.lua", cart)
        self.assertNotIn("flames.lua", cart)
        self.assertNotIn("electricity.lua", cart)
        for module in ("pseudo3d.lua", "flames.lua", "electricity.lua"):
            self.assertIn(module, advanced)
        self.assertIn("#include ../../src/pico8/pseudo3d.lua", (ROOT / "examples" / "pico8" / "pseudo3d_demo.p8").read_text(encoding="utf-8"))

    def test_pico8_pseudo3d_stress_carts_cover_profile_limits(self) -> None:
        helper = (ROOT / "tests" / "pico8" / "pseudo3d_stress.lua").read_text(encoding="utf-8")
        self.assertIn("sample_count == 600", helper)
        self.assertIn("assert(scene.object_count == object_limit", helper)
        self.assertIn('not scene:add_object(0, 80, 8, 4)', helper)
        for quality, stars, objects in (("low", 8, 3), ("medium", 14, 6), ("high", 22, 10)):
            with self.subTest(quality=quality):
                cart = (ROOT / "tests" / "pico8" / f"pseudo3d_stress_{quality}.p8").read_text(encoding="utf-8")
                self.assertIn(f'vfx8_pseudo3d_stress("{quality}", {stars}, {objects})', cart)

    def test_pico8_screen_fx_camera_contract_reads_and_restores_state(self) -> None:
        module = (ROOT / "src" / "pico8" / "screen_fx.lua").read_text(encoding="utf-8")
        cart = (ROOT / "tests" / "pico8" / "screen_fx_contract.p8").read_text(encoding="utf-8")
        self.assertIn("peek2(0x5f28), peek2(0x5f2a)", module)
        self.assertIn("camera(camera_x, camera_y)", module)
        self.assertIn("render must compose shake with the incoming camera", cart)
        self.assertIn("render must restore the incoming camera", cart)
        pico = (ROOT / "src" / "pico8" / "pseudo3d.lua").read_text(encoding="utf-8")
        self.assertIn("mode7_width = 0.55", pico)
        self.assertIn("texture.width_fraction or self.mode7_width", pico)

    def test_tic80_screen_fx_uses_scroll_registers_instead_of_camera_api(self) -> None:
        module = (ROOT / "src" / "tic80" / "screen_fx.lua").read_text(encoding="utf-8")
        self.assertNotRegex(module, r"\bcamera\s*\(")
        self.assertIn("peek(0x3ff9), peek(0x3ffa)", module)
        self.assertIn("(screen_x + dx) % 256", module)
        self.assertIn("(screen_y + dy) % 256", module)
        self.assertIn("poke(0x3ff9, screen_x)", module)
        self.assertIn("poke(0x3ffa, screen_y)", module)
        self.assertIn("local ok, err = pcall(draw_scene)", module)

    def test_pixel_deformation_demos_cache_wave_samples(self) -> None:
        demos = ("pico8/demo.p8", "picotron/main.lua", "tic80/demo.lua", "love2d/main.lua")
        for demo in demos:
            with self.subTest(demo=demo):
                source = (ROOT / "examples" / demo).read_text(encoding="utf-8")
                if demo == "pico8/demo.p8":
                    self.assertIn("wave_samples_x", source)
                    self.assertIn("wave_samples_y", source)
                    self.assertIn("wave_time", source)
                    self.assertIn("system:wave_offset", source)
                    continue
                self.assertIn("wave_samples", source)
                self.assertIn("wave_time", source)
                self.assertIn("active.wave_offset", source)

    def test_love_demo_rotates_the_grid_about_the_moving_actor(self) -> None:
        source = (ROOT / "examples" / "love2d" / "main.lua").read_text(encoding="utf-8")
        self.assertIn("active.prepare_rotation(wave_time, actor_x + 4.5, 70.5)", source)
        self.assertIn("active.rotation_bounds(0, 29, 240, 109, 8)", source)
        self.assertIn("x1, y1 = active.rotate_point(x1, y1)", source)
        self.assertIn("x2, y2 = active.rotate_point(x2, y2)", source)
        self.assertNotIn("love.graphics.rotate", source)
        self.assertGreaterEqual(source.count("if rotating then"), 2)
        adapter = (ROOT / "examples" / "love2d" / "demo_extension.lua").read_text(encoding="utf-8")
        self.assertIn("cycle_variant = function() rotate_screen = not rotate_screen end", adapter)
        self.assertIn('"wave + grid rotation"', adapter)

    def test_console_demos_rotate_wave_geometry_about_the_moving_actor(self) -> None:
        demos = ("picotron/main.lua", "tic80/demo.lua")
        for demo in demos:
            with self.subTest(demo=demo):
                source = (ROOT / "examples" / demo).read_text(encoding="utf-8")
                self.assertIn("active.prepare_rotation(wave_time", source)
                self.assertIn("active.rotation_bounds", source)
                self.assertIn("active.rotate_point", source)
                self.assertIn("active.wave_offset", source)
                self.assertGreaterEqual(source.count("if rotating then"), 2)
        pico = (ROOT / "examples" / "pico8" / "demo.p8").read_text(encoding="utf-8")
        self.assertIn("system:set_rotation(actor_x", pico)
        self.assertIn("system:rotate_point", pico)
        self.assertIn("system:wave_offset", pico)
        self.assertIn("rotate_grid=not rotate_grid", pico)
        for engine in ("pico8", "picotron", "tic80"):
            adapter = (ROOT / "examples" / engine / "demo_extension.lua").read_text(encoding="utf-8")
            with self.subTest(adapter=engine):
                self.assertIn("rotation_enabled", adapter)
                self.assertIn("prepare_rotation", adapter)

    def test_love_runtime_contract_when_love_is_available(self) -> None:
        love = Path(r"I:\Program Files\LOVE\love.exe")
        if not love.is_file():
            self.skipTest("LÖVE is not installed at the configured path")
        with tempfile.TemporaryDirectory() as temporary:
            game_folder = Path(temporary) / "love-contract"
            game_folder.mkdir()
            result_file = Path(temporary) / "love-contract-result.txt"
            for name in ("main.lua", "particle_contract.lua", "pseudo3d_contract.lua", "screen_fx_contract.lua", "palette_contract.lua", "flames_contract.lua", "electricity_contract.lua"):
                shutil.copy2(ROOT / "tests" / "love2d" / name, game_folder / name)
            result = subprocess.run(
                [str(love), str(game_folder)],
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
                cwd=str(ROOT),
                env={**os.environ, "VFX8_TEST_ROOT": str(ROOT), "VFX8_TEST_RESULT": str(result_file)},
            )
            if "Failed to initialize filesystem" in result.stdout + result.stderr:
                self.skipTest("LÖVE cannot initialize its user filesystem in this sandbox")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(result_file.read_text(encoding="utf-8"), "passed")
            self.assertIn("LOVE particle runtime contract passed", result.stdout)
            self.assertIn("LOVE pseudo-3D runtime contract passed", result.stdout)
            self.assertIn("LOVE screen effects runtime contract passed", result.stdout)
            self.assertIn("LOVE palette runtime contract passed", result.stdout)
            self.assertIn("LOVE flames runtime contract passed", result.stdout)
            self.assertIn("LOVE electricity runtime contract passed", result.stdout)


if __name__ == "__main__":
    unittest.main()
