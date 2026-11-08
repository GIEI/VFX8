# Rain

`rain` is a bounded streak system for steady rain, heavy rain, and storms. It supports vertical drops and a restrained oblique angle. Each quality profile caps the number of active streaks; changing intensity adjusts the active count within that cap.

## Quick start

```lua
-- LÖVE
local rain = require("vfx8.rain").new({
  quality = "medium", width = 480, height = 272,
  intensity = "heavy", angle = 12
})

function love.update(dt)
  rain:update(dt)
end

function love.draw()
  draw_game_scene()
  rain:draw() -- Draw over the scene, before the HUD.
end
```

For Picotron, include `vfx8/rain.lua` and construct `vfx8_rain.new(options)`. For PICO-8, include `vfx8/rain.lua` and use the same `vfx8_rain` global. TIC-80 can include the file with `--#include` at build time and also uses `vfx8_rain.new(options)`.

## API

| Method | Description |
| --- | --- |
| `rain.new(options)` | Create a fixed-capacity rain system. |
| `rain:set_intensity(level)` | Select `"light"`, `"heavy"`, or `"storm"`. Unknown values fall back to light. |
| `rain:set_angle(degrees)` | Set the slant from vertical. Values are clamped to −35° through +35°; zero is perpendicular. |
| `rain:update(dt)` | Advance drops with `dt` in seconds. The work step is capped at 0.1 seconds. |
| `rain:draw()` | Draw streaks using the engine's native line primitive. |
| `rain:clear()` | Disable and clear active drops. |
| `rain:stats()` | Return active drops, capacity, and the configured profile rate. |

### Options

| Option | Default | Notes |
| --- | --- | --- |
| `quality` | `"low"` | `"low"`, `"medium"`, or `"high"`; sets the platform-specific hard pool size. |
| `width`, `height` | `240`, `136` | Bounds used to respawn drops. Set these to the game's logical resolution. |
| `intensity` | `"light"` | `"light"`, `"heavy"`, or `"storm"`; these use about 46%, 78%, or 100% of the selected pool. |
| `angle` | `0` | Degrees from vertical; positive values lean to the right. |
| `speed` | `260` | Base drop speed in logical pixels per second. |
| `min_length`, `max_length` | `5`, `9` | Random streak length in pixels. |
| `thickness` | `1` | LÖVE line width; fantasy consoles use their one-pixel line primitive. |
| `color` | Engine-specific | LÖVE accepts `{r, g, b, a}` in 0–1 range. Fantasy consoles accept a palette index. |
| `capacity` | Profile value | Optional pool override; clamped by each engine's hard limit. |
| `seed` | `1` | Seed for repeatable initial placement. |

Capacity by profile is intentionally platform-specific:

| Engine | Low | Medium | High | Hard maximum |
| --- | ---: | ---: | ---: | ---: |
| PICO-8 | 24 | 40 | 56 | 64 |
| Picotron | 48 | 96 | 160 | 192 |
| LÖVE | 72 | 144 | 240 | 512 |
| TIC-80 | 24 | 48 | 80 | 96 |

Profile and `capacity` limits are enforced in the constructor.

## Variants

```lua
rain:set_intensity("storm") -- Dense rain, while respecting the current pool cap.
rain:set_angle(0)             -- Straight down.
rain:set_angle(-14)           -- Lightly slanted to the left.
rain:set_angle(14)            -- Lightly slanted to the right.
```

## Integrating into an existing game

Create the module once, advance it from the game's existing update callback, and draw it after the world but before the interface:

```lua
local weather = rain_module.new({quality = "low", width = 128, height = 128})

function on_weather_changed(is_storm)
  weather:set_intensity(is_storm and "storm" or "light")
end

function game_update(dt)
  update_player(dt)
  update_enemies(dt)
  weather:update(dt)
end

function game_draw()
  draw_world()
  weather:draw()
  draw_hud()
end
```

The library does not take ownership of input, callbacks, or camera state. Use logical-resolution bounds and call `clear()` when the weather system leaves the scene.

## Performance notes

- The particle arrays are allocated at construction; update and draw do not create per-drop tables.
- Pool sizes are fixed and capped per engine. Low quality is the recommended default for fantasy consoles.
- The effect uses one line draw per active drop. It does not sample or copy the screen buffer.
- Keep rain drawing before the HUD and apply the game's own scissor/clip if it should be limited to a region.
