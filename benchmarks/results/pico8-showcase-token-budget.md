# PICO-8 Showcase Token Budget

The original seven-effect showcase compiled to 10,188 code tokens, above PICO-8's 8,192-token program limit. The showcase is now split into focused cartridges. Each includes only the modules used by that scene.

## Measured cartridges

| Cartridge | Effects | Code tokens | Remaining budget | Native boot |
| --- | --- | ---: | ---: | --- |
| [`examples/pico8/demo.p8`](../../examples/pico8/demo.p8) | Particles, screen effects, pixel deformation, palette effects | 4,871 | 3,321 | Pass |
| [`examples/pico8/pseudo3d_demo.p8`](../../examples/pico8/pseudo3d_demo.p8) | Mode 7 ground, starfield, projected objects | 2,266 | 5,926 | Pass |
| [`examples/pico8/flames_electricity_demo.p8`](../../examples/pico8/flames_electricity_demo.p8) | Campfire, flamethrower, branched and clean electric arcs | 2,545 | 5,647 | Pass |
| [`examples/pico8/electricity_demo.p8`](../../examples/pico8/electricity_demo.p8) | Standalone electric arc showcase | 1,238 | 6,954 | Pass |

Counts include source expanded from `#include` files and are code tokens, not bytes or compressed cartridge size. The native runtime's `program too large` diagnostic was used to measure temporary copies padded with 3,000 `x=1` assignments (three tokens each); 9,000 tokens were subtracted from the reported totals. Temporary probe carts were removed after measurement.

The former all-effects `tests/pico8/profile_contract.p8` also exceeded the token cap. Its quality-profile checks have been divided between [`profile_contract.p8`](../../tests/pico8/profile_contract.p8) for the four core modules and [`profile_contract_advanced.p8`](../../tests/pico8/profile_contract_advanced.p8) for pseudo-3D, flames, and electricity; both pass natively.

The 8,192-token limit and token counting rules are documented in the [official PICO-8 manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#_code_limits). Native boot checks were run through the configured PICO-8 runtime bridge; its exact runtime version is not exposed by the boot-check output.

## What to open

- Open `demo.p8` for the four core effects. Left/right selects an effect, up/down changes quality, O triggers it, and X cycles its variant. For particles, X cycles through the preset and emission-shape combinations.
- Open `pseudo3d_demo.p8` for the Mode 7 road. O adds a projected object; X changes the camera and road behavior; up/down changes quality.
- Open `flames_electricity_demo.p8` for flame and electric effects. Left/right selects the effect, O triggers it, X changes the variant, and up/down changes quality.
- Open `electricity_demo.p8` for the standalone electric arc scene.

The three focused showcase carts start with the low quality profile; the standalone electricity cart starts at medium. Every cart remains below the program token limit.
