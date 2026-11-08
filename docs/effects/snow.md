# Snow

`snow` draws gently drifting flakes and brief snow deposits on horizontal surfaces. Deposits fade after a randomized lifetime between one and three seconds by default. Register ledges and object tops so flakes can settle on them; a ground surface at the bottom of the configured bounds is provided automatically.

## Quick start

```lua
-- LÖVE
local snow = require("vfx8.snow").new({
  quality = "medium", width = 480, height = 272,
  intensity = "heavy", seed = 11
})
local roof = snow:add_surface(80, 96, 120)

function love.update(dt)
  snow:set_surface(roof, 80, 96, 120) -- Update this if the roof moves.
  snow:update(dt)
end

function love.draw()
  draw_game_scene()
  snow:draw() -- Draw after the scene so flakes and deposits are visible.
end
```

For Picotron, include `vfx8/snow.lua` and construct `vfx8_snow.new(options)`. For PICO-8, include the module and use the same `vfx8_snow` global. TIC-80 can include the file with `--#include` at build time and also uses `vfx8_snow.new(options)`.

## API

| Method | Description |
| --- | --- |
| `snow.new(options)` | Create a bounded flake pool and a default floor catch surface. |
| `snow:set_intensity(level)` | Select `"light"`, `"heavy"`, or `"storm"`. |
| `snow:add_surface(x, y, width)` | Register a horizontal surface; returns its ID, or `nil` when 32 surfaces are already registered. |
| `snow:set_surface(id, x, y, width)` | Move or resize a registered surface. The default floor (ID 1) cannot be changed. |
| `snow:clear_surfaces()` | Remove registered object surfaces and retain the default floor. |
| `snow:update(dt)` | Drift flakes, detect surface crossings, and expire deposits. `dt` is clamped to 0.1 seconds. |
| `snow:draw()` | Draw flakes and settled snow with native primitives. |
| `snow:clear()` | Clear active flakes and deposits. |
| `snow:stats()` | Return active flakes, pool capacity, and settled deposits. |

### Options

| Option | Default | Notes |
| --- | --- | --- |
| `quality` | `"low"` | `"low"`, `"medium"`, or `"high"`; selects a platform-specific hard pool size. |
| `width`, `height` | `240`, `136` | Logical play-area bounds and default floor position. |
| `intensity` | `"light"` | `"light"`, `"heavy"`, or `"storm"`; uses about 42%, 76%, or 100% of the selected flake pool. |
| `speed` | `28` | Base fall speed in logical pixels per second. |
| `min_amplitude`, `max_amplitude` | `1`, `4` | Horizontal sway amplitude in pixels. |
| `flake_size` | `2` | Pixel size, clamped to 1–4. |
| `settle_min`, `settle_max` | `1`, `3` | Deposit lifetime in seconds; both values are clamped to the required 1–3 second range. |
| `settle_capacity` | Profile-derived | Maximum number of simultaneous short-lived deposits. |
| `color` | Engine-specific | LÖVE accepts `{r, g, b, a}` in 0–1 range. Fantasy consoles accept a palette index. |
| `capacity` | Profile value | Optional flake-pool override, clamped by each engine's hard limit. |
| `seed` | `1` | Seed for repeatable initial placement and deposit lifetimes. |

Flake pool limits stay small on the fantasy consoles and scale up for LÖVE:

| Engine | Low | Medium | High | Hard maximum |
| --- | ---: | ---: | ---: | ---: |
| PICO-8 | 16 | 24 | 32 | 40 |
| Picotron | 32 | 64 | 112 | 128 |
| LÖVE | 64 | 128 | 224 | 320 |
| TIC-80 | 20 | 40 | 72 | 80 |

## Adding snow to moving objects

Register a surface once, then update its position before advancing the snow simulation. This lets flakes follow moving platforms without rebuilding the effect:

```lua
local platform_surface = snow:add_surface(platform.x, platform.y, platform.width)

function game_update(dt)
  update_platform(platform, dt)
  snow:set_surface(platform_surface, platform.x, platform.y, platform.width)
  snow:update(dt)
end
```

Surface checks are horizontal and bounded to 32 registrations. The system chooses the first surface crossed from above and stores a small deposit there for its configured lifetime. For curved objects, register several short horizontal segments.

## Performance notes

- Flake and deposit arrays are preallocated; update and draw avoid per-frame object allocation.
- Profile-specific pool and deposit limits bound both CPU work and memory use.
- Surface collision checks visit at most 32 registered surfaces per active flake. Register only relevant ledges and object tops.
- The effect uses point/rectangle primitives and does not modify the game's palette or screen buffer.
