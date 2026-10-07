"""Ensure each effect guide references its captured documentation image."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
EFFECTS = (
    "particles",
    "screen_fx",
    "pixel_deform",
    "palette_fx",
    "pseudo3d",
    "flames",
    "electricity",
)
PNG_SIGNATURE = bytes((137, 80, 78, 71, 13, 10, 26, 10))


class EffectScreenshotTests(unittest.TestCase):
    def test_each_effect_page_embeds_its_screenshot(self) -> None:
        for effect in EFFECTS:
            with self.subTest(effect=effect):
                page = (ROOT / "docs/effects" / f"{effect}.md").read_text(encoding="utf-8")
                image = ROOT / "docs/effects/images" / f"{effect}.png"
                self.assertIn(f"images/{effect}.png", page)
                self.assertEqual(image.read_bytes()[:8], PNG_SIGNATURE)


if __name__ == "__main__":
    unittest.main()
