# Integrating VFX8 into an existing game

**Status:** all seven effect modules are implemented on all four engines. Each effect page has its complete options reference and an example for integrating it into an existing game. Use this page for include rules and the reusable enemy-defeat example below.

VFX8 is a collection of selective modules. Developers include only the files they use. No module defines or replaces `_init`, `_update`, `_update60`, `_draw`, `TIC`, or the game's `love.*` callbacks. The game retains its own lifecycle and explicitly calls the effect API documented on that effect's page in `docs/effects/`.

## PICO-8 — native `#include`

Place the effect file next to your cartridge, for example `vfx8/particles.lua`, and add this to the code of your **existing cartridge**:

```lua
-- Copy src/pico8/particles.lua to vfx8/particles.lua in your cart.
#include vfx8/particles.lua
particles = vfx8_particles.new({quality = "medium"})

function _update60()
  -- update the game
  particles:update(1/60)
end

function _draw()
  -- draw the game
  particles:draw()
end
```

`#include` expands the source when the cartridge starts; included files count toward the usual code and token limits. The path is relative to the `.p8` file. Includes are not recursive, so declare any dependencies directly in the cartridge. The [PICO-8 core showcase](../examples/pico8/demo.p8) uses this pattern for its four modules; separate [pseudo-3D](../examples/pico8/pseudo3d_demo.p8) and [flames/electricity](../examples/pico8/flames_electricity_demo.p8) carts keep their source budgets below the console limit.

## Picotron — cartridge `include()`

Copy `vfx8/<effect>.lua` into your cartridge and load it once near the start of your existing `main.lua`:

```lua
-- Copy src/picotron/particles.lua to vfx8/particles.lua in your cart.
include("vfx8/particles.lua")
particles = vfx8_particles.new({quality = "medium"})

function _update()
  particles:update(1 / 60)
end

function _draw()
  particles:draw()
end
```

`include()` runs the file at runtime and resolves its path from the program's working directory, which normally starts at the cartridge root. Do not call it every frame. The [Picotron demo](../examples/picotron/main.lua) loads `demo_extension.lua` this way.

## LÖVE — project `require()`

Copy `src/love2d/particles.lua` into `vfx8/particles.lua` in your project and load it in your existing `main.lua`:

```lua
local particle_system = require("vfx8.particles").new({quality = "medium"})

function love.update(dt)
  particle_system:update(dt)
end

function love.draw()
  particle_system:draw()
end
```

The particle module returns a Lua table; see [its effect page](effects/particles.md) for the complete API. The [LÖVE demo](../examples/love2d/main.lua) stages the source under `vfx8/` before running.

## TIC-80 — build-time include

TIC-80 imports Lua code into the cartridge. To combine your **existing game source** with an effect before importing, add a directive at the desired location:

```lua
--#include "vfx8/particles.lua"
local vfx8_particles_instance = vfx8_particles.new({quality = "medium"})

function TIC()
  vfx8_particles_instance:update(1 / 60)
  cls(0)
  -- Draw the game scene here.
  -- Draw the game first, then call vfx8_particles_instance:draw().
  vfx8_particles_instance:draw()
end
```

The directive is a valid Lua comment expanded by [`tools/tic80_include.py`](../tools/tic80_include.py). Copy the effect next to your game source or use a relative path. Nested includes are supported; cycles and missing files report errors. Run the command from the project root:

```text
python tools/tic80_include.py path/to/game.lua -o path/to/build/game.lua
```

Import the **generated file** into the TIC-80 cartridge already used by your game with `import code game.lua`, using a path visible to the TIC-80 console. Importing the `code` section does not require a new cartridge and leaves the cart's other sections outside the source build. The generator will not overwrite included files. The [TIC-80 demo](../examples/tic80/demo.lua) uses this directive.

## Attach an explosion to a game-owned enemy

Create the system once, emit from the game's enemy-defeat event, update once per tick, and draw between the world and the HUD. Callbacks remain game-owned. Remove the options table to use the unchanged preset defaults. See [particles](effects/particles.md#triggering-an-explosion-from-an-enemy-defeat) for option meanings and pool limits.

### LÖVE

```lua
local particles = require("vfx8.particles").new({quality = "medium", seed = 7})
local function defeat_enemy(enemy)
  if enemy.dead then return end
  enemy.dead = true
  particles:emit("explosion", enemy.x, enemy.y, {
    count = 24, radius = 2, emission_shape = "disc",
    min_speed = 36, max_speed = 68, life = 0.48,
    gravity = 24, drag = 0.7, start_size = 4, end_size = 0,
    colors = {10, 9, 7}
  })
end
function love.update(dt)
  update_enemies(dt, defeat_enemy)
  particles:update(dt)
end
function love.draw()
  draw_world(); particles:draw(); draw_ui()
end
```

### PICO-8

```lua
#include vfx8/particles.lua
particles = vfx8_particles.new({quality = "low", seed = 7})
function defeat_enemy(enemy)
  if enemy.dead then return end
  enemy.dead = true
  particles:emit("explosion", enemy.x, enemy.y, {
    count = 12, radius = 1, emission_shape = "disc",
    min_speed = 30, max_speed = 52, life = 0.42,
    gravity = 20, drag = 0.7, start_size = 3, end_size = 0,
    colors = {10, 9, 7}
  })
end
function _update60()
  update_game(defeat_enemy); particles:update(1 / 60)
end
function _draw()
  cls(); draw_world(); particles:draw(); draw_ui()
end
```

### Picotron

```lua
include("vfx8/particles.lua")
local particles = vfx8_particles.new({quality = "medium", seed = 7})
function defeat_enemy(enemy)
  if enemy.dead then return end
  enemy.dead = true
  particles:emit("explosion", enemy.x, enemy.y, {
    count = 24, radius = 2, emission_shape = "disc",
    min_speed = 36, max_speed = 68, life = 0.48,
    gravity = 24, drag = 0.7, start_size = 4, end_size = 0,
    colors = {10, 9, 7}
  })
end
function _update()
  update_game(defeat_enemy); particles:update(1 / 60)
end
function _draw()
  draw_world(); particles:draw(); draw_ui()
end
```

### TIC-80

```lua
--#include "vfx8/particles.lua"
local particles = vfx8_particles.new({quality = "low", seed = 7})
local function defeat_enemy(enemy)
  if enemy.dead then return end
  enemy.dead = true
  particles:emit("explosion", enemy.x, enemy.y, {
    count = 12, radius = 1, emission_shape = "disc",
    min_speed = 30, max_speed = 52, life = 0.42,
    gravity = 20, drag = 0.7, start_size = 3, end_size = 0,
    colors = {10, 9, 7}
  })
end
function TIC()
  update_game(defeat_enemy); particles:update(1 / 60)
  cls(0); draw_world(); particles:draw(); draw_ui()
end
```

`update_game`, `draw_world`, and `draw_ui` stand for functions already owned by the game. For TIC-80, build the include-expanded source using the command above and import that generated code into the existing cartridge.

## Effect-specific integration guides

- [Particles](effects/particles.md)
- [Screen effects](effects/screen_fx.md)
- [Pixel deformation](effects/pixel_deform.md)
- [Palette effects](effects/palette_fx.md)
- [Pseudo-3D](effects/pseudo3d.md)
- [Flames](effects/flames.md)
- [Electricity](effects/electricity.md)

## Integration contract

For every module:

1. Its dedicated page shows which files to copy and provides an example in an existing game for each supported engine.
2. Its public API will use module-specific names; the `fx` table in the demos is only a test adapter.
3. The module will not take ownership of the game's main loop, input, or window.
4. The game can create/configure, trigger, update, draw, and disable the effect through documented calls.
5. Quality profiles and resource limits will be local to the effect, so including one module does not impose the cost of the other four.

The [demo instructions](../examples/README.md) explain how to compare effects against a reference scene; the demos are not required to use VFX8 in your own game.
