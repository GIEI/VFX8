# Adaptive particle system

The particle system provides compact, reusable feedback for impacts and movement. It includes explosions, sparks, trails, smoke, and dust, with point, line, and rectangular-area emission. Each implementation uses a fixed-capacity structure-of-arrays pool and indexed-color drawing on fantasy consoles.

![PICO-8 particle burst screenshot](images/particles.png)

## Support and status

| Engine | Module | Include method | Runtime verification |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/particles.lua` | `#include` | Native demo and 600-frame saturated-pool carts pass at low, medium, and high; one-run CPU comparison recorded |
| Picotron | `src/picotron/particles.lua` | `include()` | Headless runtime smoke and five-run baseline/typical/saturated benchmark cover all profiles; see the [Picotron report](../../benchmarks/results/picotron-effects.md) |
| LÖVE | `src/love2d/particles.lua` | `require()` | Automated runtime contract and five-run benchmark cover all profiles and workloads on LÖVE 11.5; see the [all-effects report](../../benchmarks/results/love2d-effects-latest.md) |
| TIC-80 | `src/tic80/particles.lua` | build-time include | User confirms visual checks and performance measurements are complete; detailed results are not yet recorded in the benchmark report |

The `low`, `medium`, and `high` settings are conservative starting budgets. Picotron and LÖVE have repeatable measurements at every profile; the user confirms visual and performance checks are complete for PICO-8 and TIC-80, but their detailed results are not yet recorded. Standalone PICO-8 module token costs remain open. See the [cross-engine benchmark status](../../benchmarks/README.md).

## Integration

Copy the appropriate source file into your game's own `vfx8/` directory. Include or require it once during startup, create one system, then call `update(dt)` from the game's update loop and `draw()` after the scene. The module never defines or replaces the game's callbacks.

### PICO-8

```lua
#include vfx8/particles.lua
particles = vfx8_particles.new({quality = "low"})

function _update60()
  particles:update(1 / 60)
  if btnp(4) then particles:emit("explosion", 64, 64) end
end

function _draw()
  cls()
  -- Draw the game scene first.
  particles:draw()
end
```

### Picotron

```lua
include("vfx8/particles.lua")
particles = vfx8_particles.new({quality = "medium"})

function _update()
  particles:update(1 / 60)
end

function _draw()
  -- Draw the game scene first.
  particles:draw()
end
```

### LÖVE

```lua
local particle_module = require("vfx8.particles")
local particles = particle_module.new({quality = "high"})

function love.update(dt)
  particles:update(dt)
end

function love.draw()
  -- Draw the game scene first.
  particles:draw()
end
```

### TIC-80

```lua
--#include "vfx8/particles.lua"
local particles = vfx8_particles.new({quality = "low"})

function TIC()
  particles:update(1 / 60)
  cls(0)
  -- Draw the game scene first.
  particles:draw()
end
```

For TIC-80, run `python tools/tic80_include.py path/to/game.lua -o path/to/build/game.lua` and import the generated Lua source into the existing cartridge's code section.

## API

```lua
local system = vfx8_particles.new({
  quality = "medium", -- "low", "medium", or "high"
  capacity = 160,      -- optional; clamped by the engine limit
  max_emit = 96,       -- optional; particles admitted per update interval
  seed = 1             -- optional deterministic emission sequence
})

system:emit("explosion", x, y, {
  count = 20, min_speed = 36, max_speed = 64, life = 0.5,
  radius = 3, emission_shape = "disc", gravity = 20,
  drag = 0.7, wind = {x = 0, y = 2}, start_size = 3,
  end_size = 0, colors = {10, 9, 7}
})
system:emit_line("sparks", x1, y1, x2, y2, {spread = 2})
system:emit_area("smoke", x, y, width, height)
system:update(dt) -- dt is seconds; defaults to 1/60 and is clamped to 0..0.1
system:draw()
system:clear()
local active, capacity, last_interval_emissions = system:stats()
```

Preset names are `explosion`, `sparks`, `trail`, `smoke`, and `dust`. Every option is optional; omitted fields retain the preset's existing values.

| Option | Meaning |
| --- | --- |
| `count` | Requested particle count, bounded by pool and per-update budgets. |
| `speed` | Base speed used by the preset's existing random speed range. |
| `min_speed`, `max_speed` | Explicit inclusive speed interval; when either is set, this replaces the preset random range. |
| `direction` | Optional normalized direction vector `{x = ..., y = ...}` (or `{dx, dy}` array). It overrides the preset's radial/ambient direction. A zero vector creates stationary particles. |
| `direction_spread` | Random sideways velocity ratio around `direction`; `0` is straight, `1` allows sideways speed up to the forward speed. |
| `life` | Particle lifetime in seconds, clamped to at least `0.05`. |
| `radius`, `emission_shape` | For point emission only: `"ring"` places particles on a ring of this radius; `"disc"` distributes them inside it. Supplying `radius` without a shape defaults to `"disc"`. With neither option, particles spawn at the point as before. |
| `gravity` | Vertical acceleration in pixels/second²; positive values point down. |
| `drag` | Linear velocity reduction per second. |
| `wind` | Constant acceleration vector in pixels/second², as `{x, y}` or `{x, y}` array. |
| `start_size`, `size`, `end_size` | Initial and final square size in pixels. `size` is an alias for `start_size`; zero is valid. |
| `colors` | Three palette indices `{start, middle, end}` interpolated as three age bands. Fantasy consoles use native palette indices; LÖVE accepts the same PICO-8 palette indices. |
| `spread` | Existing positional jitter for point emission and line jitter. |
| `spacing` | Optional spacing in pixels for `emit_line`; the requested count is derived from segment length and then clamped by budgets. This is useful for evenly spaced trail marks. |

The current renderers draw axis-aligned square pixels. Nonzero `rotation` or `angular_speed` options raise an explicit error instead of being silently ignored. Gravity, speed, wind, and lifetime use pixels, seconds, and pixels/second². Drag reduces velocity linearly each update. A line distributes particles along its endpoints; area emission samples a rectangle extending right and down from `(x, y)`. Ring/disc placement is currently limited to point emission. `colors` values must be valid engine palette indices (0–15 for PICO-8 palette mapping); custom RGB ramps and rotated particle geometry are not supported by these fixed-pixel renderers.

### Triggering an explosion from an enemy defeat

Keep the library inside the game-owned callbacks. Include/require the particle module once, update it once per game tick, and call `emit` in the enemy's defeat handler. The following LÖVE example can be adapted to the other engine-specific include syntaxes above:

```lua
local particles = require("vfx8.particles").new({quality = "medium", seed = 7})

local function defeat_enemy(enemy)
  if enemy.dead then return end
  enemy.dead = true
  particles:emit("explosion", enemy.x, enemy.y, {
    count = 24,
    radius = 2,
    emission_shape = "disc",
    min_speed = 36,
    max_speed = 68,
    life = 0.48,
    gravity = 24,
    drag = 0.7,
    start_size = 4,
    end_size = 0,
    colors = {10, 9, 7}
  })
end

function love.update(dt)
  update_enemies(dt, defeat_enemy)
  particles:update(dt)
end

function love.draw()
  draw_world()
  particles:draw()
  draw_ui()
end
```

`emit*` returns the number admitted. Unknown presets and exhausted budgets return zero. When capacity or the emission budget is reached, new particles are dropped; existing particles are never evicted. The emission counter resets at the end of each `update()` call. Call `update()` exactly once per simulation tick and group all emissions for that tick before it to get one shared per-tick cap. `stats()` reports the number admitted in the most recently completed tick. The random sequence is local to each system and does not alter a game's random generator.

## Quality profiles and hard limits

| Engine | Profile capacities (`low` / `medium` / `high`) | Per-update emission caps | Hard capacity cap |
| --- | --- | --- | --- |
| PICO-8 | 24 / 48 / 72 | 12 / 24 / 32 | 96 |
| Picotron | 64 / 160 / 320 | 48 / 96 / 160 | 512 |
| TIC-80 | 48 / 96 / 160 | 32 / 64 / 96 | 256 |
| LÖVE | 128 / 320 / 640 | 96 / 192 / 384 | 1,024 |

Profiles set the default pool and emission limits. Explicit capacity or `max_emit` values are clamped to the hard engine cap and to the system capacity. Higher profiles increase possible density; they do not add framebuffer passes or allocations per particle. Pool storage is allocated once when the system is created. Expired entries are removed by swapping in the last active entry, so particle ordering is not stable.

## Rendering, limits, and cost

Particles are square filled pixels/sprites. Palette-index engines use fixed palette ramps per preset; LÖVE maps the same ramp to RGB values based on the PICO-8 palette. The module does not change camera, clip, or palette state. LÖVE restores the caller's draw color after rendering. `draw()` should run after the scene and before UI that must appear above effects.

The implementation updates and draws at most the active pool capacity. The pool uses structure-of-arrays storage to avoid per-particle tables and avoids temporary allocations in update/draw. Hot loops cache references to the pool arrays and active count in locals, reducing repeated instance-table lookups; dead particles are still removed by swapping the final active slot. LÖVE uses direct rectangle calls, which tested faster on this workload than rebuilding a SpriteBatch for each frame. The [all-effects LÖVE report](../../benchmarks/results/love2d-effects-latest.md) records update/draw CPU-call time and heap data at 320×180; the [Picotron report](../../benchmarks/results/picotron-effects.md) records runtime CPU and heap deltas. PICO-8 reserves eleven arrays up to its configured capacity. A saturated 600-frame PICO-8 run at each profile measured 5.06% / 7.82% / 10.44% CPU with the baseline implementation and 4.37% / 6.40% / 8.30% after local caching. These are single-run means, not repeated-run guarantees; method and ranges are in the [PICO-8 particle stress report](../../benchmarks/results/pico8-particles-stress.md). The user confirms additional PICO-8 and TIC-80 performance checks are complete, but did not provide raw values for this report. Standalone PICO-8 module token cost remains open. Portable contract checks live in `tests/test_particle_contract.py`; TIC-80 include handling is tested in `tests/tic80/`.

## Demo

Each engine's demo connects this module to the shared test harness. Trigger emits at the crosshair. Use the preset and shape controls described in [`examples/README.md`](../../examples/README.md) to explore all combinations. The demos are reference scenes; include only the module you need in your own game.
