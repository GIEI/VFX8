# Adaptive particle system

The particle system provides compact, reusable feedback for impacts and movement. It includes explosions, sparks, trails, smoke, and dust, with point, line, and rectangular-area emission. Each implementation uses a fixed-capacity structure-of-arrays pool and indexed-color drawing on fantasy consoles.

## Support and status

| Engine | Module | Include method | Runtime verification |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/particles.lua` | `#include` | Not run in this environment |
| Picotron | `src/picotron/particles.lua` | `include()` | Not run in this environment |
| LÖVE | `src/love2d/particles.lua` | `require()` | Not run in this environment |
| TIC-80 | `src/tic80/particles.lua` | build-time include | Include build verified; console runtime not available |

The `low`, `medium`, and `high` settings are conservative starting budgets. They have not yet been benchmarked on their target engines; values are not performance measurements.

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

system:emit("explosion", x, y, {count = 20, speed = 48, gravity = 20, drag = 0.7, life = 0.5, end_size = 0, spread = 0})
system:emit_line("sparks", x1, y1, x2, y2, {spread = 2})
system:emit_area("smoke", x, y, width, height)
system:update(dt) -- dt is seconds; defaults to 1/60 and is clamped to 0..0.1
system:draw()
system:clear()
local active, capacity, last_interval_emissions = system:stats()
```

Preset names are `explosion`, `sparks`, `trail`, `smoke`, and `dust`. `count`, `speed`, `gravity`, `drag`, `life`, `end_size`, and `spread` override preset defaults. Gravity is in pixels per second squared, speed in pixels per second, and lifetime in seconds. Positive gravity points down. Drag reduces velocity linearly each update. A line distributes particles along its endpoints; area emission samples a rectangle extending right and down from `(x, y)`. Point emission uses `spread` as symmetric positional jitter.

`emit*` returns the number admitted. Unknown presets and exhausted budgets return zero. When capacity or the emission budget is reached, new particles are dropped; existing particles are never evicted. The emission counter resets at the end of each `update()` call, so call update once per simulation tick. Emit before or after update, but keep all emissions for a tick within one update interval. `stats()` reports the number admitted in the most recently completed interval. The random sequence is local to each system and does not alter a game's random generator.

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

The implementation updates and draws at most the active pool capacity. The pool uses structure-of-arrays storage to avoid per-particle tables and avoids temporary allocations in update/draw. PICO-8 currently reserves eleven arrays up to its configured capacity; exact token, memory, and CPU costs have not been measured. See `benchmarks/` when measurements are added.

## Demo

Each engine's demo connects this module to the shared test harness. Trigger emits at the crosshair. Use the preset and shape controls described in [`examples/README.md`](../../examples/README.md) to explore all combinations. The demos are reference scenes; include only the module you need in your own game.
