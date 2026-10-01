# Integrating VFX8 into an existing game

**Status:** the inclusion infrastructure is ready; the five VFX modules have not been implemented yet. The `<effect>.lua` paths below describe the planned filenames. The `demo_extension.lua` files in the demos can be used to verify module loading today.

VFX8 is a collection of selective modules. Developers include only the files they use. No module should define or replace `_init`, `_update`, `_update60`, `_draw`, `TIC`, or the game's `love.*` callbacks. The game retains its own lifecycle and explicitly calls the effect API, which will be documented on that effect's page in `docs/effects/`.

## PICO-8 — native `#include`

Place the effect file next to your cartridge, for example `vfx8/particles.lua`, and add this to the code of your **existing cartridge**:

```lua
#include vfx8/particles.lua

function _update60()
  -- update the game
  -- call the effect's update function when available
end

function _draw()
  -- draw the game
  -- call the effect's draw function when available
end
```

`#include` expands the source when the cartridge starts; included files count toward the usual code and token limits. The path is relative to the `.p8` file. Includes are not recursive, so declare any dependencies directly in the cartridge. The [PICO-8 demo](../examples/pico8/demo.p8) already uses this pattern with `demo_extension.lua`.

## Picotron — cartridge `include()`

Copy `vfx8/<effect>.lua` into your cartridge and load it once near the start of your existing `main.lua`:

```lua
include("vfx8/particles.lua")

function _update()
  -- update the game and the effect
end

function _draw()
  -- draw the game and the effect
end
```

`include()` runs the file at runtime and resolves its path from the program's working directory, which normally starts at the cartridge root. Do not call it every frame. The [Picotron demo](../examples/picotron/main.lua) loads `demo_extension.lua` this way.

## LÖVE — project `require()`

Copy the future module into `vfx8/<effect>.lua` in your project and load it in your existing `main.lua`:

```lua
local particles = require("vfx8.particles")

function love.update(dt)
  -- update the game and the effect
end

function love.draw()
  -- draw the game and the effect
end
```

Each LÖVE module will return a Lua table; its constructor and concrete methods will be specified on the effect page. The [LÖVE demo](../examples/love2d/main.lua) uses `require("demo_extension")`.

## TIC-80 — build-time include

TIC-80 imports Lua code into the cartridge. To combine your **existing game source** with an effect before importing, add a directive at the desired location:

```lua
--#include "vfx8/particles.lua"

function TIC()
  -- update and draw the game and the effect
end
```

The directive is a valid Lua comment expanded by [`tools/tic80_include.py`](../tools/tic80_include.py). Copy the effect next to your game source or use a relative path. Nested includes are supported; cycles and missing files report errors. Run the command from the project root:

```text
python tools/tic80_include.py path/to/game.lua -o path/to/build/game.lua
```

Import the **generated file** into the TIC-80 cartridge already used by your game with `import code game.lua`, using a path visible to the TIC-80 console. Importing the `code` section does not require a new cartridge and leaves the cart's other sections outside the source build. The generator will not overwrite included files. The [TIC-80 demo](../examples/tic80/demo.lua) uses this directive.

## Integration contract

For every published module:

1. Its dedicated page will show which files to copy and provide a complete example in an existing game for each supported engine.
2. Its public API will use module-specific names; the `fx` table in the demos is only a test adapter.
3. The module will not take ownership of the game's main loop, input, or window.
4. The game will be able to create/configure, trigger, update, draw, and disable the effect through documented calls.
5. Quality profiles and resource limits will be local to the effect, so including one module does not impose the cost of the other four.

The [demo instructions](../examples/README.md) explain how to compare effects against a reference scene; the demos are not required to use VFX8 in your own game.
