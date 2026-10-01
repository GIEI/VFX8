# VFX8

A 2D visual effects library for **PICO-8, Picotron, LÖVE, and TIC-80**. The goal is to make effects easy to integrate into games, with predictable costs on fantasy consoles and richer quality options where resources allow.

> **Status:** the adaptive particle system is implemented for all four engines. The remaining four modules and measured benchmarks are planned.

## Principles

- **One effect, four focused implementations.** Versions share behavior and terminology while using each engine's APIs and formats. Fantasy console code remains usable without a mandatory central runtime.
- **Predictable costs.** Each effect will have explicit limits for active objects, per-frame work, and temporary memory. When it reaches a limit, it degrades predictably.
- **Scalable quality.** The `low`, `medium`, and `high` profiles will adjust density, duration, detail, and drawing passes. Each engine will have a verified default profile; unsupported options will be documented.
- **Quick integration.** Each effect will have engine-specific setup instructions, a minimal working example, and one page in `docs/effects/`.
- **Measured performance.** Final budgets will come from tests on the actual engines, with the engine version and test scene recorded.

## Engines and integration strategy

| Engine | Planned distribution | Approach |
| --- | --- | --- |
| PICO-8 | P8 Lua source included or copied into a cartridge | Small API, fixed-capacity pools, attention to token and CPU budgets |
| Picotron | Lua files included in a cartridge | Separate modules with additional quality options |
| LÖVE | Lua modules loaded into a project | Idiomatic Lua API; use engine graphics features where helpful |
| TIC-80 | Lua source integrated into a cartridge | Limited memory and per-frame work, native drawing APIs |

The particle module is available for all four engines. See its [effect page](docs/effects/particles.md) for integration, API, limits, and known verification gaps.

## Project structure

The repository has separate engine folders under `src/`, `examples/`, and `tests/`, per-effect pages under `docs/effects/`, and reproducible scenarios/results under `benchmarks/`. `docs/implementation-plan.md` describes the roadmap, while `docs/integration.md` explains how to include an effect in an existing game. `tools/tic80_include.py` expands TIC-80 include directives before importing code into a cartridge. `examples/love2d/stage_demo.py` stages the LÖVE demo with the current source module.

The implemented particle module follows the short-name convention across source and documentation. Other effect slots are roadmap placeholders.

## Try the demo scenes

Four demos are available, one per engine, with module selection, `low`/`medium`/`high` profiles, a particle trigger at the crosshair, and an effects on/off comparison. Startup instructions are in [`examples/README.md`](examples/README.md).

To include only the effects you need in an **existing game or cartridge**, follow the [integration guide](docs/integration.md). The engines use `#include`, `include()`, `require()`, or a pre-import include expansion for TIC-80. Effects must not replace the game's main loop.

## Planned effects

The roadmap contains five modules, in the requested order of utility, visual impact, and incremental complexity:

| Order | Module | Included effects |
| --- | --- | --- |
| 1 | **Adaptive particle system** (`particles`) | explosions, sparks, trails, smoke, and landing dust; point, line, and area emission |
| 2 | **Screen shake and distortion** (`screen_fx`) | directional or damped shake, shockwave/ripple, temporary screen flash and color inversion |
| 3 | **Pixel-based deformation** (`pixel_deform`) | water/flag waves, squash and stretch, dithered dissolve |
| 4 | **Palette and color cycling** (`palette_fx`) | color cycling, local flash/glow, day/night and color filters |
| 5 | **Pseudo-3D rasterizer** (`pseudo3d`) | perspective plane, 3D starfield, depth-scaled and sorted sprites |

The distinction between a **screen flash** (`screen_fx`) and an **object flash** (`palette_fx`), and between **particle trails** and other trail use cases, avoids duplicate implementations. Engine-specific variants and limits are defined in the [implementation plan](docs/implementation-plan.md).

## Documentation for each effect

Each module has or will have its own page in `docs/effects/`, with sections for its variants: visual result, supported engines, a minimal example for each engine, parameters and defaults, quality profiles, measured cost, limits, graphics-state interactions, and advice for adapting it to a game. The page ships alongside the module source and demo.

## Engine references

Technical choices will be checked against official documentation: [PICO-8](https://www.lexaloffle.com/dl/docs/pico-8_manual.html), [Picotron](https://www.lexaloffle.com/dl/docs/picotron_manual.html), [LÖVE](https://love2d.org/wiki/Main_Page), and [TIC-80](https://tic80.com/learn).

## Contributing

The particle system is the first implemented module. Further implementations should follow the plan and include source, an effect page, a minimal demo, and reproducible measurements for every engine claimed as supported.
