from __future__ import annotations

import re
import unittest
from collections import Counter
from itertools import product
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENTRY = re.compile(r'\{\s*([1-7])\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"(?:\s*,\s*"([^"]+)")?\s*\}')
MODULES = (
    "particles.lua",
    "screen_fx.lua",
    "pixel_deform.lua",
    "palette_fx.lua",
    "pseudo3d.lua",
    "flames.lua",
    "electricity.lua",
)


def catalog(path: Path) -> list[tuple[int, str, str | None]]:
    source = path.read_text(encoding="utf-8")
    start = source.index("local catalog")
    opening = source.index("{", start)
    closing = source.index("\n}", opening)
    block = source[opening:closing]
    return [
        (int(group), mode, shape)
        for group, _label, mode, shape in ENTRY.findall(block)
    ]


class IntegrationGameTests(unittest.TestCase):
    def test_all_engines_expose_the_same_complete_variant_sequence(self) -> None:
        love = catalog(ROOT / "examples/integration_game/love2d/main.lua")
        picotron = catalog(ROOT / "examples/integration_game/picotron/main.lua")
        tic80 = catalog(ROOT / "examples/integration_game/tic80/main.lua")
        pico8 = catalog(ROOT / "examples/integration_game/pico8/main.p8") + catalog(
            ROOT / "examples/integration_game/pico8/advanced.p8"
        )

        self.assertEqual(len(love), 41)
        self.assertEqual(love, picotron)
        self.assertEqual(love, tic80)
        self.assertEqual(love, pico8)
        self.assertEqual(Counter(group for group, _, _ in love), {1: 15, 2: 5, 3: 6, 4: 8, 5: 3, 6: 2, 7: 2})

        expected_variants = {
            2: {"trauma", "left", "right", "shockwave", "flash"},
            3: {"wave", "rotation", "squash", "ordered", "checker", "spiral"},
            4: {"cycle", "night", "sepia", "mono", "glow", "damage", "negative", "dusk"},
            5: {"mode7", "stars", "object"},
            6: {"jet", "campfire"},
            7: {"branched", "clean"},
        }
        for group, variants in expected_variants.items():
            with self.subTest(group=group):
                self.assertEqual({mode for item_group, mode, _ in love if item_group == group}, variants)

        particle_variants = {(mode, shape) for group, mode, shape in love if group == 1}
        self.assertEqual(
            particle_variants,
            set(product(("explosion", "sparks", "trail", "smoke", "dust"), ("point", "line", "area"))),
        )

    def test_love_game_draws_the_wave_warp_and_grid_rotation_variants(self) -> None:
        source = (ROOT / "examples/integration_game/love2d/main.lua").read_text(encoding="utf-8")
        for required in (
            '"WAVE WARP"',
            '"WAVE + ROTATION"',
            "effect:wave_offset(",
            "effect:rotate_point(",
            "effect:rotation_bounds(",
            "love.graphics.setScissor(",
        ):
            with self.subTest(required=required):
                self.assertIn(required, source)

    def test_variant_dispatch_uses_catalog_identifiers_in_every_engine(self) -> None:
        sources = (
            ROOT / "examples/integration_game/love2d/main.lua",
            ROOT / "examples/integration_game/picotron/main.lua",
            ROOT / "examples/integration_game/tic80/main.lua",
            ROOT / "examples/integration_game/pico8/main.p8",
            ROOT / "examples/integration_game/pico8/advanced.p8",
        )
        wrong_label_comparisons = re.compile(
            r'entry\[2\]\s*==\s*"(?:'
            r'trauma|left|right|shockwave|flash|wave|rotation|squash|ordered|checker|spiral|'
            r'cycle|night|sepia|mono|glow|damage|negative|dusk|mode7|stars|object|jet|campfire|branched|clean'
            r')"'
        )
        for path in sources:
            source = path.read_text(encoding="utf-8")
            with self.subTest(path=path):
                self.assertRegex(source, r"local mode\s*=\s*entry\[3\]")
                self.assertIsNone(wrong_label_comparisons.search(source))
        for engine in ("love2d", "picotron", "tic80"):
            source = (ROOT / "examples/integration_game" / engine / "main.lua").read_text(encoding="utf-8")
            with self.subTest(engine=engine):
                self.assertIn("effect:visible", source)
                self.assertRegex(source, r'entry\[3\]\s*==\s*"wave"')
                self.assertRegex(source, r'entry\[3\]\s*==\s*"rotation"')

    def test_each_engine_project_contains_current_local_module_copies(self) -> None:
        for engine in ("pico8", "picotron", "tic80", "love2d"):
            for module in MODULES:
                with self.subTest(engine=engine, module=module):
                    source = (ROOT / "src" / engine / module).read_bytes()
                    local_copy = (ROOT / "examples/integration_game" / engine / "vfx8" / module).read_bytes()
                    self.assertEqual(local_copy, source)


if __name__ == "__main__":
    unittest.main()
