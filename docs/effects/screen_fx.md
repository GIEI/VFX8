# Screen shake and distortion

`screen_fx` adds short camera shake, a solid color flash, and a bounded expanding shockwave. It is designed for hit feedback, explosions, and other brief impacts. LÖVE can displace the captured scene around the newest active shockwave with a shader. PICO-8, Picotron, and TIC-80 draw a low-cost expanding ring cue because their portable drawing APIs do not expose framebuffer sampling.

## Support and status

| Engine | Module | Integration | Runtime status |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/screen_fx.lua` | `#include` | Native profile cart measures typical rendering; camera composition and restoration contract passes; saturated and sustained timing remain open |
| Picotron | `src/picotron/screen_fx.lua` | `include()` | Headless runtime smoke covers shake, shockwave, scene rendering, and overlays; interactive visual review pending |
| LÖVE | `src/love2d/screen_fx.lua` | `require()` | Canvas shader ripple rendered live on LÖVE 11.5; benchmarks not collected |
| TIC-80 | `src/tic80/screen_fx.lua` | build-time include | Ring cue and scroll-register shake; user-confirmed working showcase on TIC-80 1.2.0; benchmark pending |

The module implements trauma shake, directional impulse, color flash, and bounded shockwaves. On LÖVE, it captures the scene into a reusable canvas and applies one shader pass while a shockwave is active. This samples nearby pixels around the newest wave. It uses `love.graphics.newCanvas` and `love.graphics.newShader`; if those resources cannot be created, rendering falls back to the ring cue. The shader path needs a single render target and temporarily captures the scene, so it costs more than the primitive-only console path. For indexed scenes, use `palette_fx:set_invert_palette()` and `palette_fx:invert()` to apply a temporary negative to draw calls routed through `map_color()`; this avoids mutating global palette or framebuffer state. Short typical-load PICO-8 CPU samples are linked in the [profile report](../../benchmarks/results/pico8-profile-smoke.md); saturated and sustained performance measurements remain open. Low and high profiles currently affect the demo's effect capacity; engine-specific hard ring limits default to 4 on PICO-8 and 8 on the other fantasy consoles, and the LÖVE demo uses 8 or 16.

## Integration

Copy the engine module to `vfx8/screen_fx.lua` and include it once. Create the effect object and update it once per simulation tick. For a game that uses the camera origin, wrap its scene draw call with `render(draw_scene)`. The callback must draw the scene exactly once.

```lua
-- PICO-8 / Picotron / TIC-80 after including the engine module
local impact_fx = vfx8_screen_fx.new({width = 128, height = 128})

function on_hit(x, y)
  impact_fx:add_trauma(0.8)
  impact_fx:impulse(4, 1, 0.18)
  impact_fx:flash(0.07, 7)
  impact_fx:shockwave(x, y, 2, 10, 0.3)
end

function update_game(dt)
  impact_fx:update(dt)
end

function draw_game()
  impact_fx:render(draw_scene)
end
```

For LÖVE, use `require("vfx8.screen_fx")` and the same object API. Its `render` method uses a graphics push/translate/pop around the callback and restores the prior draw color after overlays. Set `ripple = false` to disable framebuffer capture, or tune `ripple_strength` and `ripple_width` in pixel units. The defaults are 4 and 8 respectively.

## API

```lua
local fx = vfx8_screen_fx.new({width = 240, height = 136, capacity = 8, seed = 1})
fx:add_trauma(amount)                         -- additive trauma, clamped to 1
fx:impulse(offset_x, offset_y, duration)       -- directional shake in pixels, seconds
fx:flash(duration, color)                      -- seconds; indexed color on consoles, RGB table in LÖVE
fx:shockwave(x, y, start_radius, strength, duration) -- returns false when ring pool is full
fx:update(dt)                                  -- seconds, clamped to 0..0.1
local dx, dy = fx:get_shake_offset()             -- cached offset from the last update
fx:draw_overlays()                              -- draw flash and rings only
fx:render(draw_scene)                          -- draws the scene once, then overlays
fx:clear()                                     -- clears active effects
```

Trauma decays at 2.5 units per second and shake amplitude follows the squared remaining trauma and impulse envelope. Calling `impulse()` starts trauma automatically; `add_trauma()` adds undirected shake energy. Shake direction is provided as pixel offsets, not an angle. `get_shake_offset()` returns the same offset until the next `update()`, so the game can combine it with its own camera. Flash and wave timers advance in `update()`. The wave expands by `strength * 8` logical pixels over its lifetime and fades in LÖVE; fantasy consoles use a two-color stepped ring. When its fixed wave pool is full, a new wave is rejected and existing waves remain active. LÖVE distorts around the newest active wave while retaining geometric rings for all active waves.

## Rendering differences and limits

The scene callback is drawn with a temporary offset on PICO-8 and TIC-80. PICO-8 reads the active camera offsets from draw-state memory (`0x5f28` and `0x5f2a`), adds shake for the callback, uses a zero camera for screen-space flash and ring overlays, then restores the original camera. TIC-80 has no `camera()` function, so its wrapper composes shake with screen-scroll registers `0x3ff9` and `0x3ffa`, restores both registers after the scene callback, and then draws overlays in screen space. Picotron does not expose a portable camera getter, so its wrapper assumes a camera origin; games with a moving camera on Picotron should apply shake in their own camera system instead. LÖVE composes shake as a temporary transform and preserves the caller's transform stack.

When integrating with a game-owned camera, `get_shake_offset()` returns the cached offset for the current update. This path works on every engine and avoids relying on camera getters. Draw `draw_overlays()` afterward to show the flash and rings without drawing the scene a second time:

```lua
local base_x, base_y = camera_x, camera_y
local shake_x, shake_y = impact_fx:get_shake_offset()
camera(base_x + shake_x, base_y + shake_y)
draw_game_scene()
camera(base_x, base_y)
impact_fx:draw_overlays()
```

This avoids relying on a camera getter and preserves the camera position owned by the game.

In LÖVE, apply the returned offset as a temporary transform instead of calling `camera()`:

```lua
local shake_x, shake_y = impact_fx:get_shake_offset()
love.graphics.push()
love.graphics.translate(shake_x, shake_y)
draw_game_scene()
love.graphics.pop()
impact_fx:draw_overlays()
```

Console flashes are solid palette-color overlays; they do not alpha blend or invert the palette. Console shockwaves are expanding ring cues rather than framebuffer displacement. LÖVE requires a single active canvas target for the shader path; rendering to multiple canvases or lacking canvas/shader support uses the geometric fallback. Overlay effects are drawn before the game's UI when the caller draws UI after `render()`.

No actual-engine timing or memory measurements have been recorded yet. The implementation bounds ring storage and update/draw work by `capacity`; shake and flash add constant work. See the [implementation plan](../implementation-plan.md) for measurement acceptance criteria.
