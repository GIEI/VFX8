# VFX8

A 2D visual effects library for **PICO-8, Picotron, LÖVE, and TIC-80**. The goal is to make effects easy to integrate into games, with predictable costs on fantasy consoles and richer quality options where resources allow.

> **Status:** all seven effect modules are implemented for all four engines. Selected native checks pass; full-matrix verification and measured benchmark coverage remain open.

**License:** MIT. See [LICENSE](LICENSE).

## Principles

- **One effect, four focused implementations.** Versions share behavior and terminology while using each engine's APIs and formats. Fantasy console code remains usable without a mandatory central runtime.
- **Predictable costs.** Each effect has explicit limits for active objects, per-update work, and temporary memory. When it reaches a limit, it degrades predictably.
- **Scalable quality.** The `low`, `medium`, and `high` profiles adjust density, duration, detail, and drawing passes. Each engine has a conservative default; higher profiles remain subject to native verification.
- **Quick integration.** Each effect has engine-specific setup instructions, a minimal working example, and one page in `docs/effects/`.
- **Measured performance.** Final budgets will come from tests on the actual engines, with the engine version and test scene recorded.

## Engines and integration strategy

| Engine | Distribution | Approach |
| --- | --- | --- |
| PICO-8 | P8 Lua source included or copied into a cartridge | Small API, fixed-capacity pools, attention to token and CPU budgets |
| Picotron | Lua files included in a cartridge | Separate modules with additional quality options |
| LÖVE | Lua modules loaded into a project | Idiomatic Lua API; use engine graphics features where helpful |
| TIC-80 | Lua source integrated into a cartridge | Limited memory and per-frame work, native drawing APIs |

All seven effect modules now have source implementations, demo adapters, and effect pages for all four engines. Native verification and measured performance data remain release requirements.

## Project structure

The repository has separate engine folders under `src/`, `examples/`, and `tests/`, per-effect pages under `docs/effects/`, and the benchmark protocol and result template under `benchmarks/`. `docs/implementation-plan.md` describes the roadmap, while `docs/integration.md` explains how to include an effect in an existing game. `tools/tic80_include.py` expands TIC-80 include directives before importing code into a cartridge. `examples/love2d/stage_demo.py` stages the LÖVE demo with the current source module.

The implemented modules follow the short-name convention across source, demos, and documentation.

## Try the demo scenes

Four engine demo environments are available with `low`/`medium`/`high` profiles and effect triggers. PICO-8 uses focused carts for the core effects, pseudo-3D, and flames/electricity to stay below its 8,192-token cap. Startup instructions are in [`examples/README.md`](examples/README.md).

To include only the effects you need in an **existing game or cartridge**, follow the [integration guide](docs/integration.md). The engines use `#include`, `include()`, `require()`, or a pre-import include expansion for TIC-80. Effects must not replace the game's main loop.

## Trigger an explosion when an enemy is defeated

Create one particle system when the game starts. LÖVE loads it with `require`; PICO-8, Picotron, and TIC-80 use `vfx8_particles.new()` after including their engine-specific module. The [particle integration guide](docs/effects/particles.md) shows setup for each engine.

The enemy's defeat handler emits the explosion once at the enemy's center. Update the particle system once per game tick and draw it after the scene so the particles appear above the background:

```lua
-- LÖVE initialization. On fantasy consoles, use:
-- local particles = vfx8_particles.new({quality = "medium"})
local particles = require("vfx8.particles").new({quality = "medium"})

local enemy = {x = 120, y = 72, health = 3, alive = true}

local function damage_enemy(enemy, damage)
  if not enemy.alive then return end

  enemy.health = enemy.health - damage
  if enemy.health <= 0 then
    enemy.alive = false
    particles:emit("explosion", enemy.x, enemy.y, {
      count = 28,
      speed = 58,
      gravity = 12,
      life = 0.45,
      spread = 1
    })
  end
end

function love.update(dt)
  update_game(dt) -- Combat calls damage_enemy() when a hit lands.
  particles:update(dt)
end

function love.draw()
  draw_game_scene()
  if enemy.alive then draw_enemy(enemy) end
  particles:draw()
  draw_hud()
end
```

`enemy.alive` prevents repeated hits from emitting duplicate explosions after defeat. Use the enemy's actual center coordinates and tune `count`, `speed`, `gravity`, `life`, and `spread` to match the game's scale. For multiple enemies, pass the defeated enemy to the same handler; the particle system's fixed capacity and emission limit keep the cost bounded.

## Effects

The library contains seven modules:

| Order | Module | Included effects |
| --- | --- | --- |
| 1 | **Adaptive particle system** (`particles`) | explosions, sparks, trails, smoke, and landing dust; point, line, and area emission |
| 2 | **Screen shake and distortion** (`screen_fx`) | trauma and directional shake, temporary color flash, shader shockwave in LÖVE, expanding ring cue on fantasy consoles |
| 3 | **Pixel-based deformation** (`pixel_deform`) | coordinate waves, squash and stretch scales, ordered/checker/spiral dither masks |
| 4 | **Palette and color cycling** (`palette_fx`) | color cycling, local flash/glow, negative flashes, built-in and custom index-map filters |
| 5 | **Pseudo-3D rasterizer** (`pseudo3d`) | textured Mode 7 ground plane, layered starfield, road-aligned depth projection for objects |
| 6 | **Flames** (`flames`) | fixed-pool campfire and directional flamethrower jet simulations |
| 7 | **Electric arcs** (`electricity`) | irregular point-to-point lightning with optional deterministic side branches |

The distinction between a **screen flash** (`screen_fx`) and an **object flash** (`palette_fx`), and between **particle trails** and other trail use cases, avoids duplicate implementations. Engine-specific variants and limits are defined in the [implementation plan](docs/implementation-plan.md).

## Documentation for each effect

Each module has its own page in `docs/effects/`, with sections for integration, parameters, quality profiles, cost, and limitations. Native test results and measured costs will be recorded as engines become available.

## Engine references

Technical choices will be checked against official documentation: [PICO-8](https://www.lexaloffle.com/dl/docs/pico-8_manual.html), [Picotron](https://www.lexaloffle.com/dl/docs/picotron_manual.html), [LÖVE](https://love2d.org/wiki/Main_Page), and [TIC-80](https://tic80.com/learn).

## Compatibility status

| Engine | Source/API review | Demo build | Native runtime | Measured profiles |
| --- | --- | --- | --- | --- |
| PICO-8 | Source and API contract checks pass | Three focused showcase carts fit the token limit | User confirms the self-contained pseudo-3D demo works; all three showcase carts and standalone electricity cart also pass clean boot checks | Showcase code tokens measured; see [token report](benchmarks/results/pico8-showcase-token-budget.md) |
| Picotron | Portable source/API contracts pass | Include layout prepared | User confirms all seven effects work in the native demo; headless smoke also covers variants and all profiles | Performance measurements are in the [Picotron report](benchmarks/results/picotron-effects.md) |
| LÖVE | Portable source/API contracts pass | Staging script passes | LÖVE 11.5 is installed; native launch fails during filesystem initialization and the local MCP endpoint is offline | Not measured |
| TIC-80 | Portable source/API contracts pass | Include expansion tests pass | User-confirmed native test: all seven effects work on TIC-80 1.2.0; per-profile measurements pending | Not measured |

“Implemented” describes source and demo adapters; it does not imply that every runtime or performance gate has passed. See [benchmark status and procedure](benchmarks/README.md). Record engine versions and profile measurements as they become available.

See the [public release checklist](docs/release-checklist.md) for the remaining runtime, performance, packaging, and publication work.

Run portable contracts and available native runtime checks with [`tests/run-regression.ps1`](tests/run-regression.ps1). See [`tests/README.md`](tests/README.md) for coverage, runtime requirements, and skip behavior. The portable regression path runs in GitHub Actions.

## Contributing

Contributions should include engine-specific source, an effect page, a minimal demo, and reproducible measurements for every engine claimed as supported.
