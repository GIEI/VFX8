# VFX8 Integration Game

A minimal game for checking that VFX8 can be embedded in a project that owns its input, update, and draw callbacks. A square moves with the arrow keys and remains within the play area. One action triggers the selected effect; the other advances through a 41-entry effect-and-variant sequence. The centered header shows the selected effect and variant.

## Controls

| Action | PICO-8 | Picotron | LÖVE | TIC-80 |
| --- | --- | --- | --- | --- |
| Move | Arrow keys | Arrow keys | Arrow keys | Arrow keys |
| Trigger selected effect | O | Z | Space | A |
| Select next effect or variant | X | X | Tab | B |

Each project creates only the active effect. The selector visits all five particle presets with point, line, and area emission, all screen feedback modes, wave warp and rotation, squash and the three dissolve masks, palette cycles and filters, all three pseudo-3D demonstrations, both flame types, and both lightning types. Switching variants clears transient state. The game calls the effect's `update()` from its update callback and draws it from its draw callback. Screen effects wrap the game's scene callback so their temporary render state is restored before the interface is drawn.

## Engine projects

### PICO-8

Copy the `pico8/` folder into PICO-8's carts directory, enter that folder with `cd`, then open `main.p8`. Its includes use the local `vfx8/` folder. PICO-8's 8,192-token cartridge limit does not leave enough room for the complete library in one integration cart, so the seven effects are split into two cartridges:

- `main.p8`: particles, screen FX, pixel deformation, and palette FX.
- `advanced.p8`: pseudo-3D, flames, and electricity.

The X button advances through the effects in order. Moving past the last effect in one cart uses `load()` to open the other cart and passes the square's coordinates, so the sequence feels continuous. Keep both carts and the `vfx8/` folder together in the same PICO-8 virtual directory, and run the cart with that directory as the current directory so its includes and handoff resolve.

### Picotron

Open `picotron/main.lua` as a cartridge. Its `include("vfx8/<module>.lua")` paths refer to the module copies in `picotron/vfx8/`.

### LÖVE

Run `love .` from `love2d/`. Lua's `require("vfx8.<module>")` resolves the local files under `love2d/vfx8/`. The game renders at a 480 × 272 logical resolution and scales it by an integer factor of two into a 960 × 544 window.

### TIC-80

From the repository root, expand the local includes into a single source file:

```text
python tools/tic80_include.py examples/integration_game/tic80/main.lua -o examples/integration_game/tic80/build/main.lua
```

Copy `build/main.lua` to TIC-80's working folder, then run `import code main.lua` and `run`. The generated source contains all seven modules, so no module files need to be copied into the console.

Each project has its own copy of the engine modules in its `vfx8/` directory. This keeps the examples self-contained and makes each include point directly to the matching engine implementation.

## Quick validation

1. Start the engine project using the instructions above. The playfield should show the square and a centered `effect / variant` header.
2. Move the square in all four directions and hold each direction at an edge; it should remain in the play area.
3. Trigger the selected effect. The square should continue moving, and the effect should appear at or around it.
4. Advance through all 41 entries. The header should change each time, including while PICO-8 switches cartridges, and movement should continue from the same position.
5. Trigger each entry once. In particular, the wave-warp variants should bend the playfield grid behind the square; after screen FX runs, the header and controls should render normally; pseudo-3D should keep the square and header visible.
