# Demo environment

Four reference scenes, one per engine, let you try VFX8 modules against a shared control surface. The first four slots use the reference grid scene; pseudo-3D replaces it with perspective bands, a starfield, and depth-projected objects.

## Startup

| Engine | Files | How to run |
| --- | --- | --- |
| PICO-8 | [`pico8/electricity_demo.p8`](pico8/electricity_demo.p8) or [`pico8/demo.p8`](pico8/demo.p8) + [`demo_extension.lua`](pico8/demo_extension.lua) | Load the standalone electric arc cart to test lightning. The all-effects showcase currently exceeds PICO-8's token limit. |
| Picotron | [`picotron/main.lua`](picotron/main.lua) + [`demo_extension.lua`](picotron/demo_extension.lua) + `vfx8/*.lua` | Put the files in the cartridge root and copy the implemented modules from `src/picotron/` to `vfx8/`; run with Ctrl+R. |
| LÖVE | [`love2d/stage_demo.py`](love2d/stage_demo.py) | Run `python examples/love2d/stage_demo.py` from the repository root; the script stages the source module and launches LÖVE. |
| TIC-80 | [`tic80/demo.lua`](tic80/demo.lua) + [`demo_extension.lua`](tic80/demo_extension.lua) | Build the combined file first, import it into a Lua cartridge, then use `run`. |

Do not pass `examples/love2d/main.lua` directly to `love.exe`. LÖVE loads a game folder, and the source example depends on modules that the staging script copies into `examples/love2d/build/vfx8/`. To prepare and launch it, run `python examples/love2d/stage_demo.py` from the repository root. To prepare the folder without opening a window, add `--stage-only`; then launch `examples/love2d/build/` with LÖVE.

### Optional LÖVE MCP controls

After restarting Codex to load `love2d-mcp`, run `python examples/love2d/stage_demo.py --mcp` to launch the demo with its local MCP bridge. The bridge listens only on `127.0.0.1:21110`. The MCP provides game screenshots, state inspection, Lua execution in a sandbox, simulated input, pause/resume, frame stepping, and hot reload. The demo state is available under `VFX8_DEMO_STATE`. Run without `--mcp` for the regular demo without a network listener.

For TIC-80, run this command from the repository root:

```text
python tools/tic80_include.py examples/tic80/demo.lua -o examples/tic80/build/demo.lua
```

The path passed to `import code` must be visible from the TIC-80 console's working directory. Use `folder` in TIC-80 to open that directory, copy `examples/tic80/build/demo.lua` there, then run `import code demo.lua` and `run`. For Picotron, put both files at the cartridge root because `main.lua` is the entry point.

The demos use `#include`, `include()`, `require()`, and `--#include` respectively to load their adapter and effect modules. PICO-8 includes seven modules in one showcase cart; include only the module needed by a production game to preserve source and token budget. The same mechanisms for adding effects to an **existing game** are described in [`docs/integration.md`](../docs/integration.md).

## Controls

| Action | PICO-8 | Picotron | TIC-80 | LÖVE |
| --- | --- | --- | --- |
| Previous/next module | Left / right | Left / right | Left / right | Left / right arrow |
| Previous/next profile | Up / down | Up / down | Up / down | Up / down arrow |
| Trigger at crosshair | O | O | A | Space or Z |
| Compare effects on/off | — | X | B | X |
| Variant / next particle preset | X | Z | X | P |
| Next emission shape | — | C | Y | M |

The starting profile is `low`. Changing module or profile reinitializes the active slot; turning effects off calls `on_exit`, displays `FX DISABLED`, and leaves the scene unprocessed. With the particle module selected, trigger emits the selected preset using the selected shape. Shapes are point, horizontal line, and rectangular area. In `pixel_deform`, the variant button rotates the grid around the moving square while the square and rest of the scene stay fixed. In `palette_fx`, it cycles color cycling, night, sepia, monochrome, glow, custom dusk mapping, and negative flash; trigger flashes mapped scene colors or applies the selected negative. In `pseudo3d`, the scene displays a textured Mode 7 ground plane and parallax starfield; trigger adds an object aligned to the road. In `flames`, the campfire emits continuously and trigger adds a burst; cycle the variant to switch to a directional flamethrower jet. In `electricity`, trigger creates a brief jagged bolt between the crosshair and the far side of the scene; cycle the variant for an unbranched arc. PICO-8 has only two action buttons: `O` triggers the active effect and `X` cycles the active variant or particle preset.

## Connecting a module

Each `demo_extension.lua` defines an `fx` table with one slot for each of the seven effect modules:

| Slot | Module |
| --- | --- |
| `fx[1]` | `particles` (implemented) |
| `fx[2]` | `screen_fx` (implemented) |
| `fx[3]` | `pixel_deform` (implemented) |
| `fx[4]` | `palette_fx` (implemented) |
| `fx[5]` | `pseudo3d` (textured Mode 7 implementation) |
| `fx[6]` | `flames` (campfire and directional flamethrower jet) |
| `fx[7]` | `electricity` (irregular point-to-point lightning) |

The table is a **demo adapter**, not the public library API. Optional adapter methods:

```lua
fx[1] = {
  on_enter = function(quality) end, -- "low", "medium", or "high"
  on_exit = function() end,         -- clean up or restore state
  trigger = function(x, y) end,     -- crosshair position
  update = function(dt) end,        -- dt in seconds
  render_scene = function(draw_scene)
    draw_scene()                    -- for effects over the full scene
  end,
  draw = function() end             -- overlay after the scene
}
```

`render_scene` must call `draw_scene()` **once**. Effects that change the camera, buffer, or palette can set the state before that call and restore it immediately afterward. Use `draw` for overlays such as particles. If a method is missing, the demo uses its default behavior. On fantasy consoles, the demo passes `dt = 1/60`; LÖVE uses the real `love.update` callback time.

On PICO-8 and TIC-80, connect one module at a time: including all seven in one test cartridge would skew measurements and use code space unnecessarily. The demos do not yet contain automatic measurements; final benchmarks will be added with each module.

## Quick demo check

At startup, the grid, moving square, crosshair, and `READY` status should be visible. The arrows should change module and profile. In the particle module, the trigger emits particles at the crosshair; preset and shape controls cycle the variants. In `screen_fx`, the trigger applies shake, flash, and an expanding ring at the crosshair. In `pixel_deform`, wave lines twist around the moving square while it responds to squash/stretch and a dissolve mask. In `palette_fx`, the actor color cycles and the variant control selects filters, glow, and a temporary palette negative. In `pseudo3d`, the scene displays a checker-textured Mode 7 ground plane and a parallax starfield; trigger adds a depth-projected object.
