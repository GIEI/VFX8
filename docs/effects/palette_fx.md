# Palette effects and color cycling

`palette_fx` maps palette indices for color cycling, local flashes, glow pulses, temporary palette negatives, and day/night, sepia, and monochrome filters. It does not change the engine's global palette or framebuffer. Apply `map_color()` to the color argument of draw calls that should receive an effect; leave UI and unrelated objects unmapped.

## Support and status

| Engine | Module | Integration | Status |
| --- | --- | --- | --- |
| PICO-8 | `src/pico8/palette_fx.lua` | `#include` | Native palette contract and profile carts pass; temporal cycle and pulse phases are cached during update |
| Picotron | `src/picotron/palette_fx.lua` | `include()` | Headless runtime smoke covers cycle/filter/flash mapping; interactive palette review pending |
| LÖVE | `src/love2d/palette_fx.lua` | `require()` | Automated runtime contract passes on LÖVE 11.5; temporal cycle and pulse phases are cached during update |
| TIC-80 | `src/tic80/palette_fx.lua` | build-time include | User-confirmed working showcase on TIC-80 1.2.0; benchmark and automated native regression pending |

The built-in filters are 16-entry index maps designed for a PICO-8-style palette. Picotron accepts up to 64 colors, but its built-in filters affect only indices 0 through 15. Use `set_filter_map()` for a custom palette layout or to map all 64 Picotron indices.

## Integration

Copy and load only the module for your engine. It does not define callbacks or change global palette state. In the following examples, create the instance once, advance it in the game's existing update callback, and map only the colors that should receive the effect.

### PICO-8

```lua
#include vfx8/palette_fx.lua
local palette = vfx8_palette_fx.new({quality = "low", color_count = 16})
palette:set_cycle(8, 11, 2)

function _update60()
  palette:update(1 / 60)
end

function draw_actor(x, y)
  rectfill(x, y, x + 7, y + 7, palette:map_color(8))
end
```

### Picotron

```lua
include("vfx8/palette_fx.lua")
local palette = vfx8_palette_fx.new({quality = "low", color_count = 16})

function _update()
  palette:update(1 / 60)
end

function draw_actor(x, y)
  rectfill(x, y, x + 7, y + 7, palette:map_color(8))
end
```

### LÖVE

```lua
local palette_fx = require("vfx8.palette_fx")
local palette = palette_fx.new({quality = "low", color_count = 16})

function love.update(dt)
  palette:update(dt)
end

function draw_actor(x, y, rgb_palette)
  local index = palette:map_color(8)
  love.graphics.setColor(rgb_palette[index + 1])
  love.graphics.rectangle("fill", x, y, 8, 8)
end
```

### TIC-80

```lua
--#include "vfx8/palette_fx.lua"
local palette = vfx8_palette_fx.new({quality = "low", color_count = 16})

function TIC()
  palette:update(1 / 60)
  rect(20, 20, 8, 8, palette:map_color(8))
end
```

```lua
local palette = vfx8_palette_fx.new({quality = "low", color_count = 16})
palette:set_cycle(8, 11, 2)

function update_game(dt)
  palette:update(dt)
end

function draw_actor(x, y, color_index)
  rectfill(x, y, x + 7, y + 7, palette:map_color(color_index))
end
```

For LÖVE, use the returned index to select the corresponding RGB value from your game's palette table before calling `love.graphics.setColor()`. `map_color()` accepts an integer palette index, not an RGB triplet.

## API

```lua
local palette = vfx8_palette_fx.new({quality = "low", color_count = 16})
palette:set_cycle(8, 11, 2)       -- Rotate indices 8..11 twice per second.
palette:set_filter("night")      -- Or "sepia" or "mono".
palette:set_pulse(8, 10, 4)       -- Alternate two indices four times per second.
palette:flash(8, 11, 7, 0.18)    -- Map the selected range to index 7 temporarily.
palette:set_invert_palette(rgb_palette) -- Configure RGB colors in index order, components 0..1.
palette:invert(0.18)             -- Apply the nearest-color negative map temporarily.
local color = palette:map_color(index)
palette:update(dt)
palette:clear()
```

- `set_cycle(first, last, rate)` rotates an inclusive index range. `rate` is complete range rotations per second. It returns `false` for invalid ranges.
- `clear_cycle()` disables cycling.
- `set_filter(name)` selects `night`, `sepia`, or `mono` and returns `false` for an unknown name. `clear_filter()` disables it.
- `set_filter_map(map)` copies a custom index map after validating one integer target per configured color. Targets must be within `0..color_count-1`. Invalid maps return `false` and leave the active filter unchanged. Extra entries are ignored.
- `set_pulse(first, second, frequency)` alternates between two indices. A non-positive frequency disables the pulse.
- `flash(first, last, target, duration)` temporarily maps an inclusive input range to one index. Apply it only to the object that needs feedback.
- `set_invert_palette(rgb_palette)` accepts an RGB triple per configured index, with components in the 0..1 range, and builds a nearest-color negative lookup once. It returns `false` if the palette is incomplete or malformed.
- `invert(duration)` temporarily applies that lookup and returns `false` until a valid RGB palette has been configured. `clear_invert()` ends it immediately.
- `map_color(index)` composes effects in this order: cycle, filter, pulse, temporary inversion, then flash. Indices outside the configured color range pass through unchanged.
- `update(dt)` advances timers, clamps `dt` to 0..0.1 seconds, and allocates no tables. `clear()` resets the instance to its neutral mapping.

For a four-color palette, a custom map can be configured like this:

```lua
local small_palette = vfx8_palette_fx.new({color_count = 4})
small_palette:set_filter_map({0, 1, 1, 2})

local rgb_palette = {{0, 0, 0}, {1, 1, 1}, {1, 0, 0}, {0, 1, 1}}
small_palette:set_invert_palette(rgb_palette)
small_palette:invert(0.18)
```

## Demo controls

Select `palette_fx` with the module controls. Trigger flashes the actor's mapped colors; in the negative-flash variant it applies a temporary palette negative. The variant control cycles through color cycling, night, sepia, monochrome, glow pulse, a custom dusk map, and negative flash. The demo maps scene draw colors while leaving the HUD unchanged.

## Quality, cost, and limits

Mapping uses constant-time arithmetic and at most two table lookups per draw color. Cycle shifts and pulse phases are calculated in `update()` and reused by each mapping call. One PICO-8 stress-cart run with 128 mappings per frame recorded an average CPU fraction of `0.1076` before and `0.1056` after caching over 600 frames. This is a small whole-workload improvement, not a universal speedup guarantee; repeated timer and phase calculations have been removed from the per-color path. The module does not scan pixels, copy a framebuffer, or allocate memory while updating or mapping colors. Negative-map construction compares each configured RGB pair once (at most 64×64 comparisons on Picotron), not per frame. `color_count` is clamped to 16 on PICO-8, TIC-80, and LÖVE; Picotron supports 1..64 indices. Quality profiles do not change the fixed per-call cost.

Filters are direct index substitutions, not RGB color grading, so their output depends on the palette's index ordering. Built-in filters cover the first 16 indices; a custom map covers every configured index. Since this module avoids global palette changes, native sprite and tilemap calls that draw many indexed pixels are not intercepted; map their colors in the game renderer or draw path where feasible.

## State and interactions

The module owns only its instance state. It does not call `pal()`, `palt()`, alter LÖVE colors, or leave camera, clipping, or draw state changed. Apply `map_color()` only to scene elements that should participate. `flash()` affects mapped indices in its selected range; whole-screen flashes belong to `screen_fx`.
