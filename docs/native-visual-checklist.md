# Native Visual Verification Checklist

This checklist covers interactive appearance, controls, draw order, and state restoration. Headless tests verify API calls and rendering paths, but they do not replace visual review in each native engine.

## Recorded automated checks

| Engine | Runtime observed | Automated coverage | Visual review |
| --- | --- | --- | --- |
| PICO-8 | Version unavailable from the runtime bridge | Core and advanced profile contracts pass at low, medium, and high. The three showcase carts and standalone electricity cart pass clean boot checks. | Pending. Interactive lockstep startup timed out; screenshots and control navigation were unavailable. |
| Picotron | 0.3.0d, build 260527-061316 | Native headless smoke passes for all seven effects, covered variants, and low/medium/high. Textured and fallback pseudo-3D drawing are exercised. | Pending. The smoke test checks draw calls, not the composed window. |
| LÖVE | 11.5.0 | Portable source contracts pass. Direct runtime startup fails while initializing the user filesystem; the local `love2d-mcp` endpoint is not running. | Pending. |
| TIC-80 | 1.2.0, user-confirmed | Portable source and include-build checks pass. The user previously confirmed that the demo runs. | Pending for this release pass. No native visual capture or profile-by-profile result is recorded. |

## Manual run checklist

### PICO-8

- [ ] Open `examples/pico8/demo.p8`. At each quality (`low`, `medium`, `high`), cycle particles, screen effects, pixel warp, and palette effects. Trigger each effect and try its available variants. For particles, cycle the preset and emission-shape combinations.
- [ ] Open `examples/pico8/pseudo3d_demo.p8`. At each quality, inspect the road texture, starfield, perspective coverage, projected objects, and camera/road variation.
- [ ] Open `examples/pico8/flames_electricity_demo.p8`. At each quality, inspect campfire and flamethrower variants, then branched and clean lightning. Confirm repeated triggers do not leave stale pixels or stop updates.
- [ ] Open `examples/pico8/electricity_demo.p8` and check the standalone branched/clean bolt toggle and repeated strikes.
- [ ] Confirm arrow and O/X controls do not behave as if held continuously, the active scene field stays filled, and the game returns to a stable frame after each effect.

### Picotron

- [ ] Launch the interactive showcase from [`examples/README.md`](../examples/README.md), then test low, medium, and high for every effect and each displayed variant.
- [ ] Check the full 240×136 composition, clipping at the screen edges, and the update/draw order when particles or lightning overlap the scene.
- [ ] Check that camera, clipping, palette, and drawing state return to normal after switching effects or profiles.

### LÖVE

- [ ] Run `python examples/love2d/stage_demo.py` with LÖVE 11.5.0. If the local MCP bridge is available, connect it and capture the initial screen plus each effect/profile; otherwise use the regular game window.
- [ ] At every quality, inspect all seven effects and their variants. Check shader shockwave and its fallback, Mode 7 texture edges, particle bounds, and window resize behavior.
- [ ] Trigger overlapping effects and confirm canvases, shader state, color, blend mode, and scissor state are restored after drawing.

### TIC-80

- [ ] Build the current showcase with `python tools/tic80_include.py examples/tic80/demo.lua -o examples/tic80/build/demo.lua`, import that generated file into TIC-80, and run it.
- [ ] At each quality, cycle through all seven effects and variants, checking the 240×136 view, clipping, controls, and frame stability.
- [ ] Check scroll/camera, palette, and clipping restoration after each effect and after switching modules.

## Shared effect and state checks

- [ ] Particles: explosion, sparks, trail, smoke, dust; point, line, and area emission.
- [ ] Screen effects: trauma shake, directional impulses in each supported direction, flash, and shockwave/ring.
- [ ] Pixel deformation: wave-only and line rotation, squash/stretch, and every supported dissolve/dither mode.
- [ ] Palette: color cycle, night, sepia, monochrome, glow/pulse, custom mapping where exposed, and negative/inversion flash.
- [ ] Pseudo-3D: textured and fallback ground, curved road, starfield, camera variation, and projected objects.
- [ ] Flames: campfire and directional flamethrower.
- [ ] Electricity: branched and clean bolts, varied endpoints, and repeated strikes.
- [ ] In each engine, exercise effect combinations where the demo allows it and verify that one effect does not leave camera, palette, clipping, color, blend, shader, or canvas state behind.

## Record results

For each engine/profile run, record the runtime version, cartridge or staged folder, effects and variants exercised, control result, visual result, state-restoration result, and screenshot or capture path. Record expected engine differences separately; for example, fantasy-console shockwaves are ring cues rather than framebuffer ripples.

| Engine / version | Quality | Effects and variants | Controls / draw order / state | Result and capture path |
| --- | --- | --- | --- | --- |
|  | low |  |  |  |
|  | medium |  |  |  |
|  | high |  |  |  |
