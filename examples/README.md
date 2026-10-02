# Demo environment

Four engine demo environments let you try VFX8 modules with `low`, `medium`, and `high` quality profiles. PICO-8 uses separate focused carts for core effects, pseudo-3D, and flames/electricity to fit its code token budget.

For a callback and input integration check, see the [minimal integration game](integration_game/README.md). It is provided as a self-contained project for each engine and advances through the seven effects with one button.

## Startup

| Engine | Files | How to run |
| --- | --- | --- |
| PICO-8 | [`pico8/demo.p8`](pico8/demo.p8), [`pico8/pseudo3d_demo.p8`](pico8/pseudo3d_demo.p8), and [`pico8/flames_electricity_demo.p8`](pico8/flames_electricity_demo.p8) | Load a focused showcase cart for core effects, pseudo-3D, or flames and electricity. Each includes only the modules it uses. The [`pseudo3d_demo_standalone.p8`](pico8/pseudo3d_demo_standalone.p8) copy has its module embedded for setups where the relative `#include` path is not resolved. See [PICO-8 token measurements](../benchmarks/results/pico8-showcase-token-budget.md). |
| Picotron | [`picotron/main.lua`](picotron/main.lua) + [`demo_extension.lua`](picotron/demo_extension.lua) + `vfx8/*.lua` | Put the files in the cartridge root and copy the implemented modules from `src/picotron/` to `vfx8/`; run with Ctrl+R. |
| LÖVE | [`love2d/stage_demo.py`](love2d/stage_demo.py) | Run `python examples/love2d/stage_demo.py` from the repository root; the script stages the source module and launches LÖVE. |
| TIC-80 | [`tic80/demo.lua`](tic80/demo.lua) + [`demo_extension.lua`](tic80/demo_extension.lua) | Build the combined file, import the generated source into a Lua cartridge, then use `run`. The user-confirmed native test used this compiled showcase and all seven effects worked. |

Do not pass `examples/love2d/main.lua` directly to `love.exe`. LÖVE loads a game folder, and the source example depends on modules that the staging script copies into `examples/love2d/build/vfx8/`. To prepare and launch it, run `python examples/love2d/stage_demo.py` from the repository root. To prepare the folder without opening a window, add `--stage-only`; then launch `examples/love2d/build/` with LÖVE.

### Optional LÖVE MCP controls

After restarting Codex to load `love2d-mcp`, run `python examples/love2d/stage_demo.py --mcp` to launch the demo with its local MCP bridge. The bridge listens only on `127.0.0.1:21110`. The MCP provides game screenshots, state inspection, Lua execution in a sandbox, simulated input, pause/resume, frame stepping, and hot reload. The demo state is available under `VFX8_DEMO_STATE`. Run without `--mcp` for the regular demo without a network listener.

For TIC-80, build a self-contained Lua source file from the repository root:

```text
python tools/tic80_include.py examples/tic80/demo.lua -o examples/tic80/build/demo.lua
```

To create a native `.tic` cartridge, open TIC-80, enter `folder` to open its working directory, copy `examples/tic80/build/demo.lua` there, then run `import code demo.lua` and `run`. Once the demo is running, use `save vfx8-demo.tic` to save the complete cartridge. The resulting `.tic` contains the expanded Lua code; no source files or include paths are needed at runtime. For Picotron, put both files at the cartridge root because `main.lua` is the entry point.

PICO-8 uses `#include` to load the modules required by each focused cart. Picotron, LÖVE, and TIC-80 use `include()`, `require()`, and `--#include` with their demo adapters. For a production game, include only the modules needed to preserve code space. The same mechanisms for adding effects to an **existing game** are described in [`docs/integration.md`](../docs/integration.md).

## Controls

| Action | PICO-8 | Picotron | TIC-80 | LÖVE |
| --- | --- | --- | --- |
| Previous/next module | Left / right (core cart) | Left / right | Left / right | Left / right arrow |
| Previous/next profile | Up / down | Up / down | Up / down | Up / down arrow |
| Trigger at crosshair | O | O | A | Space or Z |
| Compare effects on/off | — | X | B | X |
| Variant / next particle preset | X | Z | X | P |
| Next emission shape | Cycled with particle preset using X | C | Y | M |

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
