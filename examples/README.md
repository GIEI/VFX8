# Demo environment

Four reference scenes, one per engine, let you try VFX8 modules against the same composition: a grid, floor, moving object, and central crosshair. The adaptive particle system is connected to the first module slot; the other four slots remain planned.

## Startup

| Engine | Files | How to run |
| --- | --- | --- |
| PICO-8 | [`pico8/demo.p8`](pico8/demo.p8) + [`demo_extension.lua`](pico8/demo_extension.lua) | Load the `.p8` cartridge in PICO-8 and use `RUN`/Ctrl+R. Keep both files together. |
| Picotron | [`picotron/main.lua`](picotron/main.lua) + [`demo_extension.lua`](picotron/demo_extension.lua) + `vfx8/particles.lua` | Put the files in the cartridge root and copy `src/picotron/particles.lua` to `vfx8/particles.lua`; run with Ctrl+R. |
| LÖVE | [`love2d/stage_demo.py`](love2d/stage_demo.py) | Run `python examples/love2d/stage_demo.py` from the repository root; the script stages the source module and launches LÖVE. |
| TIC-80 | [`tic80/demo.lua`](tic80/demo.lua) + [`demo_extension.lua`](tic80/demo_extension.lua) | Build the combined file first, import it into a Lua cartridge, then use `run`. |

### Optional LÖVE MCP controls

After restarting Codex to load `love2d-mcp`, run `python examples/love2d/stage_demo.py --mcp` to launch the demo with its local MCP bridge. The bridge listens only on `127.0.0.1:21110`. The MCP provides game screenshots, state inspection, Lua execution in a sandbox, simulated input, pause/resume, frame stepping, and hot reload. The demo state is available under `VFX8_DEMO_STATE`. Run without `--mcp` for the regular demo without a network listener.

For TIC-80, run this command from the repository root:

```text
python tools/tic80_include.py examples/tic80/demo.lua -o examples/tic80/build/demo.lua
```

The path passed to `import code` must be visible from the TIC-80 console's working directory. Use `folder` in TIC-80 to open that directory, copy `examples/tic80/build/demo.lua` there, then run `import code demo.lua` and `run`. For Picotron, put both files at the cartridge root because `main.lua` is the entry point.

The demos use `#include`, `include()`, `require()`, and `--#include` respectively to load their adapter and effect module. The same mechanisms for adding effects to an **existing game** are described in [`docs/integration.md`](../docs/integration.md); the demos are not required to ship a game with VFX8.

## Controls

| Action | PICO-8 | Picotron | TIC-80 | LÖVE |
| --- | --- | --- | --- |
| Previous/next module | Left / right | Left / right | Left / right | Left / right arrow |
| Previous/next profile | Up / down | Up / down | Up / down | Up / down arrow |
| Trigger at crosshair | O | O | A | Space or Z |
| Compare effects on/off | — | X | B | X |
| Next particle preset | X | Z | X | P |
| Next emission shape | — | C | Y | M |

The starting profile is `low`. Changing module or profile reinitializes the active slot; turning effects off calls `on_exit`, displays `FX DISABLED`, and leaves the scene unprocessed. With the particle module selected, trigger emits the selected preset using the selected shape. Shapes are point, horizontal line, and rectangular area. PICO-8 has only two action buttons: `O` triggers emission and `X` cycles the preset; the demo keeps other options available through its source code.

## Connecting a module

Each `demo_extension.lua` defines an `fx` table with one slot for each of the five roadmap modules:

| Slot | Module |
| --- | --- |
| `fx[1]` | `particles` (implemented) |
| `fx[2]` | `screen_fx` |
| `fx[3]` | `pixel_deform` |
| `fx[4]` | `palette_fx` |
| `fx[5]` | `pseudo3d` |

The table is a **demo adapter**, not the final public library API. When a module is implemented, connect its source to the corresponding slot. Optional adapter methods:

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

On PICO-8 and TIC-80, connect one module at a time: including all five in one test cartridge would skew measurements and use code space unnecessarily. The demos do not yet contain automatic measurements; final benchmarks will be added with each module.

## Quick demo check

At startup, the grid, moving square, crosshair, and `READY` status should be visible for particles. The arrows should change module and profile. The comparison button should toggle `FX: ON` and `FX: OFF`. The trigger button emits particles at the crosshair; preset and shape controls cycle the available variants. Other modules show `NOT IMPLEMENTED`.
