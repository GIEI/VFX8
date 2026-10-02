# Pixel deformation and animation

`pixel_deform` provides small coordinate and visibility helpers for water/flag waves, squash and stretch, and deterministic pixel dissolve masks. It does not copy or rewrite sprite sheets or framebuffers: apply its returned offsets, scales, and per-pixel visibility decisions while drawing your own object.

## Support and status

| Engine | Module | Integration | Runtime status |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/pixel_deform.lua` | `#include` | Native profile cart records helper-only typical-load samples at low, medium, and high; it does not rasterize transformed game sprites |
| Picotron | `src/picotron/pixel_deform.lua` | `include()` | Headless runtime smoke covers wave, rotation, squash, and scale helpers; interactive visual review pending |
| LÖVE | `src/love2d/pixel_deform.lua` | `require()` | Wave and grid-rotation demo smoke-tested live on LÖVE 11.5; benchmarks not collected |
| TIC-80 | `src/tic80/pixel_deform.lua` | build-time include | User-confirmed working showcase on TIC-80 1.2.0; benchmark and automated native regression pending |

Wave output is deterministic and uses the engine's sine implementation. Squash/stretch changes scale over one trigger duration and returns smoothly to `(1, 1)`. Dissolve uses a fixed 4×4 threshold matrix, with ordered, checker, and spiral variants. The demo caches one offset per four-pixel column and reuses it across grid rows to limit sine calls. It applies these helpers to a small sample object and grid; it does not establish a universal sprite drawing API.

## Integration

Copy the engine module to `vfx8/pixel_deform.lua`, include it once, and keep your game's callbacks and sprite drawing. The helper returns values; your own draw code applies them.

```lua
-- PICO-8, Picotron, or TIC-80 after including the engine module
local deform = vfx8_pixel_deform.new({quality = "low"})

function update_game(dt)
  deform:update(dt)
  if landed then deform:set_squash(1.25, 0.75, 0.2) end
end

function draw_plant(x, y, time)
  local wave_y = deform:wave_offset(x, time, 2, 24, 0.4)
  local scale_x, scale_y = deform:scale()
  -- Apply wave_y and scale_x/scale_y in this game's sprite renderer.
  spr(plant_sprite, x, y + wave_y)
end
```

For LÖVE, load `require("vfx8.pixel_deform")`; all helper method names and units are the same. LÖVE projects can apply `scale()` with a local `push`/`translate`/`scale`/`pop`, while fantasy console sprite APIs generally need the game to draw a scaled sprite or reconstruct it from pixels.

## API

```lua
local deform = vfx8_pixel_deform.new({quality = "medium", phase = 0})
local offset = deform:wave_offset(x, time, amplitude, wavelength, speed, phase)
deform:set_squash(horizontal_scale, vertical_scale, duration)
deform:set_rotation(center_x, center_y, angle_radians)
local rotated_x, rotated_y = deform:rotate_point(x, y)
local left, top, right, bottom = deform:rotation_bounds(view_left, view_top, view_right, view_bottom, margin)
deform:update(dt)
local scale_x, scale_y = deform:scale()
local keep_pixel = deform:visible(x, y, dissolve_amount, "ordered")
deform:clear()
```

`wave_offset` returns a vertical offset in pixels. `wavelength` is clamped to at least one pixel; `time` is in seconds; the optional phase is measured in wave cycles. If `time` is omitted, the object's accumulated phase is used. `set_squash` clamps each scale to at least 0.1; `scale()` returns neutral scales after the duration expires. `update(dt)` advances wave phase and the squash animation, clamping `dt` to 0..0.1 seconds.

`visible` returns a boolean for a pixel at integer coordinates. Amount is clamped to 0..1: zero keeps all pixels and one removes all pixels. Modes are `ordered` (default), `checker`, and `spiral`. The 4×4 matrix repeats in object/screen coordinates; keep coordinates stable if the dissolve pattern should not crawl while the sprite moves.

The rotation variant rotates the complete grid around the moving orange square. The wave offset is calculated first; then every vertical and horizontal grid-line endpoint is transformed with the same angle. The square, crosshair, background, floor, particles, and UI stay fixed. Press `P` in LÖVE or the variant button (`X` on PICO-8, `Z` on Picotron, `X` on TIC-80) to toggle grid rotation.

For a point `(x, y)`, rotation center `(cx, cy)`, and angle `θ`, the transform is:

```text
dx = x - cx
dy = y - cy
x' = cx + dx*cos(θ) - dy*sin(θ)
y' = cy + dx*sin(θ) + dy*cos(θ)
```

Call `set_rotation(cx, cy, angle)` once before drawing a frame. `rotation_bounds()` inverse-transforms the four corners of the visible area and returns the source-space bounds needed to draw enough grid lines to cover the viewport after rotation. Then use `rotate_point(x, y)` for each grid-line endpoint. Both methods reuse sine and cosine cached once per frame. The demos use `θ = time * 0.35` radians; PICO-8 converts the angle to its turn-based trigonometry unit internally. For horizontal grid lines, transform `(x, y + wave_offset(x, time, ...))` to preserve the original wave while rotating the whole grid around the actor. The generated lines are clipped to the playfield so they do not overwrite the fixed HUD.

## Quality, cost, and limits

The object stores a phase and squash timer/scales. Wave and dissolve calls have constant work and no allocation. Dissolve is intended to be evaluated only for pixels actually drawn. Quality does not alter the helper calculations. The module does not change palette, clipping, camera, or shared graphics state. Performance has not yet been measured on the target engines.

The wave helper supplies coordinates but does not split a sprite into rows. The squash helper supplies scales but cannot resize native sprites on all fantasy consoles. The dissolve helper supplies a visibility mask; drawing a large object pixel-by-pixel can be expensive, so use it on small sprites or a coarse sample grid on constrained targets.
