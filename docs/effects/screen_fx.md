# Screen shake and distortion

`screen_fx` adds short camera shake, a solid color flash, and a bounded expanding ring overlay. It is designed for hit feedback, explosions, and other brief impacts. The ring is a geometric ripple cue; it does not displace the rendered framebuffer.

## Support and status

| Engine | Module | Integration | Runtime status |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/screen_fx.lua` | `#include` | Source and demo connected; native cart check pending |
| Picotron | `src/picotron/screen_fx.lua` | `include()` | Source and demo connected; native cart check pending |
| LÖVE | `src/love2d/screen_fx.lua` | `require()` | Source and demo connected; runtime check pending |
| TIC-80 | `src/tic80/screen_fx.lua` | build-time include | Source and demo connected; native cart check pending |

This first version implements trauma shake, directional impulse, color flash, and expanding ring overlays. True pixel displacement, palette inversion, and measured performance are future work. Low and high profiles currently affect only the demo's ring capacity; engine-specific hard ring limits default to 4 on PICO-8 and 8 on the other fantasy consoles, and the LÖVE demo uses 8 or 16.

## Integration

Copy the engine module to `vfx8/screen_fx.lua` and include it once. Create the effect object, update it once per simulation tick, then wrap the scene draw call with `render(draw_scene)`. The callback must draw the scene exactly once.

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

For LÖVE, use `require("vfx8.screen_fx")` and the same object API. Its `render` method uses a graphics push/translate/pop around the callback and restores the prior draw color after overlays.

## API

```lua
local fx = vfx8_screen_fx.new({width = 240, height = 136, capacity = 8, seed = 1})
fx:add_trauma(amount)                         -- additive trauma, clamped to 1
fx:impulse(offset_x, offset_y, duration)       -- directional shake in pixels, seconds
fx:flash(duration, color)                      -- seconds; indexed color on consoles, RGB table in LÖVE
fx:shockwave(x, y, start_radius, strength, duration) -- returns false when ring pool is full
fx:update(dt)                                  -- seconds, clamped to 0..0.1
fx:render(draw_scene)                          -- draws the scene once, then overlays
fx:clear()                                     -- clears active effects
```

Trauma decays at 2.5 units per second and shake amplitude follows the squared remaining trauma and impulse envelope. Calling `impulse()` starts trauma automatically; `add_trauma()` adds undirected shake energy. Shake direction is provided as pixel offsets, not an angle. Flash and ring timers advance in `update()`. The ring expands by `strength * 8` pixels over its lifetime and fades in LÖVE; fantasy consoles use a two-color stepped ring. When its fixed ring pool is full, a new ring is rejected and existing rings remain active.

## Rendering differences and limits

The scene callback is temporarily drawn with a camera offset on PICO-8, Picotron, and TIC-80. Those APIs do not expose a portable camera getter, so this module resets the camera to `(0, 0)` after the callback. Use the wrapper when the game's camera is at its origin; games with a moving camera should apply shake in their own camera system instead. LÖVE composes shake as a temporary transform and preserves the caller's transform stack.

Console flashes are solid palette-color overlays; they do not alpha blend or invert the palette. The expanding ring is an overlay, not a framebuffer shockwave. LÖVE draws a fading line circle but also does not sample or displace the scene. Overlay effects are drawn before the game's UI when the caller draws UI after `render()`.

No actual-engine timing or memory measurements have been recorded yet. The implementation bounds ring storage and update/draw work by `capacity`; shake and flash add constant work. See the [implementation plan](../implementation-plan.md) for measurement acceptance criteria.
