# Flame simulation

`flames` provides two compact, pixel-based fire effects: a directional flamethrower jet and a continuously emitted campfire plume. Each engine has its own implementation and fixed particle budget; neither mode installs or replaces game callbacks.

## Support status

| Engine | Source | Include method | Verification |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/flames.lua` | `#include` | User confirms visual checks and performance measurements are complete; standalone module token count remains open |
| Picotron | `src/picotron/flames.lua` | `include()` | User confirms visual checks are complete; headless runtime smoke and five-run benchmark cover all profiles. See the [Picotron report](../../benchmarks/results/picotron-effects.md) |
| LÖVE | `src/love2d/flames.lua` | `require()` | User confirms visual checks are complete; native API tests and five-run benchmark cover all profiles. See the [LÖVE report](../../benchmarks/results/love2d-effects-latest.md) |
| TIC-80 | `src/tic80/flames.lua` | Build-time include expansion | User confirms visual checks and performance measurements are complete; detailed results are not yet recorded in the benchmark report |

## Integration

Include only the engine-specific module. Call `update(dt)` once each update and `draw()` after the scene. Fantasy console demos pass `1 / 60`; LÖVE uses the `dt` supplied by `love.update`.

```lua
-- LÖVE
local flames = require("vfx8.flames").new({quality = "medium"})

-- In the enemy defeat handler, aim the jet away from the enemy center.
flames:emit_jet(enemy.x, enemy.y, 1, -0.15, {count = 24})

-- Or place a campfire and keep it burning by emitting during update.
local fire_x, fire_y = 120, 100
function love.update(dt)
  flames:emit_campfire(fire_x, fire_y)
  flames:update(dt)
end

function love.draw()
  draw_game_scene()
  flames:draw()
end
```

For PICO-8, Picotron, and TIC-80, construct `vfx8_flames.new({quality = "medium"})` after including the module. Put calls to `emit_jet` or `emit_campfire` in the game's own event and update functions, and call `flames:update(1 / 60)` and `flames:draw()` from the existing loop.

## API

### `new(options)`

Creates an independent fire system. `options.quality` accepts `"low"`, `"medium"`, or `"high"`. Each profile sets a bounded pool capacity and maximum emissions per update. `options.capacity`, `options.max_emit`, and `options.seed` can tune the limits and deterministic random sequence; hard engine limits still apply.

### `emit_jet(x, y, dx, dy, options)`

Emits a directional stream from `(x, y)`. `(dx, dy)` defines the direction and is normalized internally; a zero vector emits nothing. `options.count` overrides the profile count. Optional `speed`, `spread`, `life`, `size`, `gravity`, and `drag` tune the stream. `spread` controls the sideways velocity variation.

```lua
flames:emit_jet(player.x, player.y, aim_x, aim_y, {
  count = 18,
  speed = 92,
  spread = 0.18,
  life = 0.38
})
```

### `emit_campfire(x, y, options)`

Emits a plume upward from a base centered at `(x, y)`. Repeating this call during update keeps the campfire alive. `options.count` overrides the profile count; optional `radius`, `speed`, `life`, `size`, `gravity`, and `drag` control the base width and flame motion.

```lua
flames:emit_campfire(fire.x, fire.y, {radius = 6, count = 3})
```

### `update(dt)`, `draw()`, `clear()`, and `stats()`

`update(dt)` advances motion in seconds and resets the per-update emission budget. `draw()` draws square pixels using an age-based yellow, orange, and red ramp, shrinking each particle toward the end of its life. `clear()` removes all active particles. `stats()` returns active count, pool capacity, and particles emitted in the most recent update.

## Quality profiles and limits

| Engine | Low capacity / update cap | Medium | High | Hard capacity ceiling |
| --- | ---: | ---: | ---: | ---: |
| PICO-8 | 24 / 8 | 40 / 12 | 56 / 16 | 64 |
| Picotron | 48 / 16 | 96 / 32 | 160 / 48 | 256 |
| LÖVE | 128 / 32 | 256 / 64 | 512 / 128 | 512 |
| TIC-80 | 24 / 8 | 48 / 16 | 80 / 24 | 128 |

The first value is the default active pool and the second is the maximum number accepted in one `update()` interval. Higher profiles increase visible density while respecting each engine's ceiling. If a pool or update budget is full, new particles are dropped; existing particles are never evicted. For a campfire, call `emit_campfire` each update and let the pool budget naturally cap the sustained plume.

PICO-8, Picotron, and TIC-80 draw palette-index pixels with engine primitives. LÖVE draws the same style with filled rectangles and restores the caller's color after drawing. Call `draw()` after the world and before UI that should appear above the fire.

Picotron and LÖVE have repeatable all-profile typical and saturated measurements in the [Picotron](../../benchmarks/results/picotron-effects.md) and [LÖVE](../../benchmarks/results/love2d-effects-latest.md) reports. The user confirms PICO-8 and TIC-80 visual/performance checks are complete; their detailed values are not yet recorded. Standalone PICO-8 module token cost remains open.
