# VFX8 1.1.0

VFX8 is a modular 2D visual-effects library for PICO-8, Picotron, LÖVE, and TIC-80. Include only the modules a game needs, then call their update and draw methods from the game's existing callbacks.

## Included modules

1. **Particles** — explosions, sparks, trails, smoke, and landing dust; point, line, and area emission.
2. **Screen effects** — trauma and directional shake, flash and inversion, shockwave shader on LÖVE, and a lightweight ring cue on fantasy consoles.
3. **Pixel deformation** — coordinate waves, squash and stretch, and ordered, checker, and spiral dissolve masks.
4. **Palette effects** — color cycling, local flashes and glow, palette filters, custom maps, and negative flashes.
5. **Pseudo-3D** — Mode 7 ground, layered starfields, and depth-projected objects.
6. **Flames** — campfire plume and directional flamethrower jet.
7. **Electricity** — irregular lightning between points, with optional branches.
8. **Rain** — vertical or oblique drops, with light, heavy, and storm intensity.
9. **Snow** — drifting flakes and temporary deposits on registered horizontal surfaces, with light, heavy, and blizzard intensity.

Every module has engine-specific source, a dedicated English guide, and integration examples. The demo adapters and minimal integration games preserve game-owned input, update, and draw callbacks. The [PICO-8 integration example](examples/integration_game/README.md) splits its nine-module catalog across three cartridges to respect the code-token limit.

## Verification

| Engine | Verified in this release |
| --- | --- |
| PICO-8 | Core, advanced, and weather contracts pass in native profile checks. The weather demo and integration cartridge boot. Oblique movement is explicitly tested. Version was not reported by the bridge. |
| Picotron | The original seven modules and integration game were previously user-tested on 0.3.0d. A nine-module native smoke harness is included; rain and snow still need a native run and visual review. |
| LÖVE | Version 11.5.0. Native API/runtime contracts pass for all nine modules, and the staged demo builds. Rain and snow still need visual review. |
| TIC-80 | Version 1.2.0. Demo and integration source include builds pass; the original seven modules were previously user-tested. Rain and snow still need a native run and visual review. |

The portable regression suite passes **50 tests**. The Picotron and LÖVE five-run performance reports cover the original seven modules, not rain and snow. Weather performance measurements, native visual review, and detailed raw PICO-8/TIC-80 measurements are not included in this release's evidence.

## Quick start

Run portable checks from the repository root:

```powershell
./tests/run-regression.ps1 -PortableOnly
```

See [`README.md`](README.md) for the module list, [`docs/integration.md`](docs/integration.md) for include and callback examples, [`examples/README.md`](examples/README.md) for demos, and [`docs/effects/`](docs/effects/) for the API of each module. Known verification and measurement gaps are listed in [`docs/release-checklist.md`](docs/release-checklist.md).

VFX8 is distributed under the MIT License.
