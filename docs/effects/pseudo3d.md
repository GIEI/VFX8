# Pseudo-3D rasterizer

`pseudo3d` draws a perspective ground plane with an optional animated Mode 7 texture, a layered starfield, and depth-projected objects. It does not own the game loop, camera, or palette. The fantasy-console backends use each engine's native textured-line or bounded sprite-memory sampling path; the LÖVE backend uses a fragment shader. The untextured road remains available when `set_mode7(false)` is selected.

## Support status

| Engine | Module | Integration | Runtime status |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/pseudo3d.lua` | `#include` | Native smoke cart exercises `tline` Mode 7 drawing at low, medium, and high; user confirms visual/performance checks are complete; standalone module token count remains open |
| Picotron | `src/picotron/pseudo3d.lua` | `include()` | User confirms visual checks are complete; headless smoke covers textured and untextured drawing, and the five-run benchmark covers object/star loads. See the [Picotron report](../../benchmarks/results/picotron-effects.md) |
| LÖVE | `src/love2d/pseudo3d.lua` | `require()` | User confirms visual checks are complete; native API tests and five-run benchmark cover Mode 7 shader availability and all profiles. See the [LÖVE report](../../benchmarks/results/love2d-effects-latest.md) |
| TIC-80 | `src/tic80/pseudo3d.lua` | build-time include | User confirms visual checks and performance measurements are complete; detailed results are not yet recorded in the benchmark report |

## Include only this module

Copy the engine-specific `pseudo3d.lua` file into the game. No other VFX8 module is required.

### PICO-8

```lua
#include vfx8/pseudo3d.lua
road = vfx8_pseudo3d.new({quality = "low"})
road_colors = {sky = 1, road_a = 1, road_b = 13, edge = 11}
-- The cart's map is the PICO-8 texture source for tline.
road:set_mode7({width_tiles = 16, height_tiles = 16, scale = 0.55})

function _update60()
  road:update(1 / 60)
end

function _draw()
  road:draw(road_colors)
end
```

The include path is relative to the cartridge. Keep a single instance and update it once per frame.

### Picotron

```lua
include("vfx8/pseudo3d.lua")
local road = vfx8_pseudo3d.new({quality = "medium", width = 480, height = 270})
local road_colors = {sky = 1, road_a = 1, road_b = 13, edge = 11}
local road_texture = userdata("u8", 64, 64)
-- Fill road_texture once with palette indices before enabling the effect.
road:set_mode7({source = road_texture, width = 64, height = 64, scale = 0.6})

function _update()
  road:update(1 / 60)
end

function _draw()
  road:draw(road_colors)
end
```

### TIC-80

Add the source before the game code with `tools/tic80_include.py`:

```lua
--#include "vfx8/pseudo3d.lua"
local road = vfx8_pseudo3d.new({quality = "medium"})
local road_colors = {sky = 1, road_a = 1, road_b = 13, edge = 11}
-- TIC-80 reads an aligned power-of-two rectangle from sprite memory.
road:set_mode7({x = 0, y = 0, width = 64, height = 64, scale = 0.6})

function TIC()
  road:update(1 / 60)
  road:draw(road_colors)
end
```

### LÖVE

```lua
local road = require("vfx8.pseudo3d").new({quality = "high", width = 320, height = 180})
road:set_mode7(road_texture, {scale = 0.09}) -- road_texture is a LÖVE Image
local road_sprite = {lateral = 0.35, depth = 90}

function love.update(dt)
  road:update(dt)
end

function love.draw()
  road:draw()
  local x, y, scale = road:project_road(road_sprite.lateral, road_sprite.depth, 12)
  love.graphics.draw(car_image, x, y - scale, 0, scale, scale)
end
```

Draw game-owned sprites after the road raster. `project_road()` returns the matching screen position and scale for a normalized road coordinate: `-1` is the left edge, `0` is the center, and `1` is the right edge. For example, set `road_sprite.lateral` from a car's lane and `road_sprite.depth` from its world distance; the helper applies the current curve and camera offset.

## API

- `new(options)` creates one independent scene. `width` and `height` describe its logical viewport. `quality` is `low`, `medium`, or `high`.
- `update(dt)` advances the road and stars; time steps are clamped to 0.1 seconds.
- `draw(colors)` renders the entire pseudo-3D scene. Fantasy-console color options are palette indices: `sky`, `ground`, `road_a`, `road_b`, `edge`, and optional `stars = {near, middle, far}`. LÖVE uses RGB color arrays instead.
- `set_road(width, lanes, curve, curve_strength)` updates optional road width, lane count, and bend without reallocating. `curve` is signed: positive bends screen-right and negative screen-left. `curve_strength` is the maximum screen-space bend scale. Lane count is clamped by each engine.
- `set_mode7(texture, options)` enables the textured ground plane; `set_mode7(false)` restores the procedural road. It returns `true` when enabled and `false` for an invalid resource or unavailable LÖVE shader. Angles are radians in Picotron, TIC-80, and LÖVE, and turns in PICO-8. `scale` controls world-to-texture repetition; increase it for denser texture tiling. PICO-8 reads its map texture and accepts power-of-two `width_tiles` and `height_tiles`. Its `new({mode7_width = fraction})` option and texture's `width_fraction` option control horizontal coverage, clamped from 0.25 to 1; uncovered ground uses `colors.ground`. Defaults are 0.55, 0.75, and 1 for low, medium, and high quality. Picotron accepts a `userdata("u8", width, height)` texture via `source`, with power-of-two dimensions and an optional `high_quality = true` sampling flag. TIC-80 reads an aligned power-of-two region from the 128×128 sprite sheet (`x`, `y`, `width`, `height`); its low/medium/high profiles sample 4×4, 2×2, and 1×1 blocks. LÖVE accepts an `Image` plus `{scale = number, angle = radians}` and requires fragment shader support.
- `add_object(lateral, depth, color, size)` adds a square projected object. Positive lateral values move right; larger depth values are farther away. With `project_road`, lateral is normalized across road half-width (`-1` left edge, `0` center, `1` right edge). It returns `false` when the fixed object pool is full.
- `project(lateral, depth, size)` returns screen `x`, `y`, and projected size for drawing the game's own sprites with the same camera projection.
- `project_road(lateral, depth, size)` uses the road width and bend as well as camera projection, so custom sprites follow the visible road.
- `clear_objects()` removes projected objects.
- `set_camera(lateral, horizon, speed, curve)` changes optional camera values without reallocating scene buffers. The optional fourth argument updates road bend.
- `clear()` removes objects and resets the travel distance.

Call `add_object` when a game event occurs; objects travel toward the camera at the configured speed and expire near the camera. Use `project_road(lateral, depth, size)` to place a game-owned sprite on the same road curve. Stars use a deterministic sequence and do not change the game's random generator. Draw the pseudo-3D scene before HUD elements. The `draw` call intentionally owns the scene area it is given; wrap it in the game's clipping or off-screen-buffer policy if it should occupy only part of the screen. PICO-8 defaults to a 128×96 logical scene so the standard 128×128 screen retains room for a HUD.

## Resource profiles

Profiles bound star count and projected-object capacity; road bands only apply when the Mode 7 texture is disabled. PICO-8 uses `tline` once per visible row. Picotron uses `tline3d` once per visible row and leaves its high-quality sampling flag off by default. TIC-80 samples one texel per 1×1, 2×2, or 4×4 output block depending on quality. LÖVE executes the perspective mapping in a fragment shader. These paths trade fidelity and cost differently; validate the chosen mode on the target runtime. Avoid creating instances each frame. Fantasy-console examples reuse their color-options table, and LÖVE reuses a per-instance color scratch table.

The profile values are conservative code limits. PICO-8 also scales the Mode 7 texture's horizontal coverage: low uses 55% of the viewport, medium 75%, and high 100%. The remaining ground is filled with the configured `ground` color, so the scene stays fully covered. Set `mode7_width` in `new(options)` or `width_fraction` in `set_mode7(texture)` to a value from `0.25` to `1` to choose a different coverage. Five short PICO-8 typical-load runs recorded 20.22%, 25.21%, and 30.53% `stat(1)` CPU for low, medium, and high respectively, with the 128×96 demo viewport, Mode 7 texture, starfield, and one projected object. Five additional 600-frame saturated draw runs recorded 20.84%, 26.50%, and 33.04% with star and projected-object pools at their profile limits. The high profile retains full coverage; all measurements remain below one third of the VM budget in the tested scene. See [the measurement record](../../benchmarks/results/pico8-profile-smoke.md) for ranges and limitations. Cross-engine control names are shared, but each engine uses its own graphics API; test the selected profile in the target runtime before raising limits.

Mode 7 textures replace the road surface; stars and projected objects remain separate overlays. PICO-8 uses the cart map, TIC-80 reserves the selected sprite-memory region, and Picotron/LÖVE use caller-provided image resources. `project_road` only returns placement coordinates; your game still draws and depth-orders its own sprite art. Repeatable all-profile benchmark results are available for Picotron and LÖVE in the [Picotron](../../benchmarks/results/picotron-effects.md) and [LÖVE](../../benchmarks/results/love2d-effects-latest.md) reports. PICO-8 has typical and saturated scene samples in its [profile report](../../benchmarks/results/pico8-profile-smoke.md). The user confirms additional PICO-8 and TIC-80 visual/performance checks are complete; exact new results are not yet recorded. The renderer does not provide collision handling.
