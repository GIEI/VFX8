# Native Visual Verification Checklist

This checklist covers interactive appearance, controls, draw order, and state restoration. Headless tests verify API calls and rendering paths, but they do not replace visual review in each native engine.

## Recorded automated checks

| Engine | Runtime observed | Automated coverage | Visual review |
| --- | --- | --- | --- |
| PICO-8 | Version unavailable from the runtime bridge | Core and advanced profile contracts pass at low, medium, and high. The user confirms visual checks and performance measurements are complete. | User confirms visual checks across the showcase/effects and profiles are complete. Exact measurement values and captures were not supplied in this task. |
| Picotron | 0.3.0d, build 260527-061316; user-tested native demo | User confirms all seven effects work in the native demo. Automated smoke also covers update/draw variants at low/medium/high and both pseudo-3D texture and fallback paths. | User confirms native visual checks are complete. Screenshots and profile-by-profile notes are not stored. |
| LÖVE | 11.5.0 | Portable source contracts and the native API contract harness pass. The user confirms the integration game works. | User confirms native visual checks are complete. Screenshots and profile-by-profile notes are not stored; the local `love2d-mcp` endpoint is offline. |
| TIC-80 | 1.2.0, user-confirmed | Portable source and include-build checks pass. The user confirms visual checks and performance measurements are complete. | User confirms visual checks across the showcase/effects and profiles are complete. Exact measurement values and captures were not supplied in this task. |

## Integration game confirmation

| Date | Engines | User-confirmed result | Evidence |
| --- | --- | --- | --- |
| 2026-10-03 | PICO-8, Picotron, LÖVE, TIC-80 | The minimal game with its own input, update, and draw callbacks runs correctly on all four engines. | User confirmation in the project task; no screenshots were attached. |

This confirms the public integration path. The user has confirmed native visual checks are complete on all four engines. Representative captures and run-by-run details remain useful release evidence.

## User-confirmed PICO-8 and TIC-80 checks

On 2026-10-03, the user confirmed completing visual checks and performance measurements in PICO-8 and TIC-80. This closes the manual run items for those two engines. The confirmation did not include raw timings, profile-by-profile values, runtime details beyond the already recorded TIC-80 version, or capture paths; those remain unrecorded evidence rather than pending user testing.

## User-confirmed Picotron and LÖVE visual checks

On 2026-10-03, the user confirmed completing visual checks in Picotron and LÖVE. This closes the manual visual run items for those engines. Screenshots and per-profile notes were not included in the confirmation and remain unrecorded evidence.

## Manual run checklist

### PICO-8

- [x] Open `examples/pico8/demo.p8`. At each quality (`low`, `medium`, `high`), cycle particles, screen effects, pixel warp, and palette effects. Trigger each effect and try its available variants. For particles, cycle the preset and emission-shape combinations. User confirms the visual/profile checks and measurements are complete.
- [x] Open `examples/pico8/pseudo3d_demo_standalone.p8`. The user confirms the self-contained cart works. Separate visual review of every profile and variant remains unrecorded.
- [x] Open `examples/pico8/flames_electricity_demo.p8`. At each quality, inspect campfire and flamethrower variants, then branched and clean lightning. Confirm repeated triggers do not leave stale pixels or stop updates. User confirms the visual/profile checks are complete.
- [x] Open `examples/pico8/electricity_demo.p8` and check the standalone branched/clean bolt toggle and repeated strikes. User confirms the visual checks are complete.
- [x] Confirm arrow and O/X controls do not behave as if held continuously, the active scene field stays filled, and the game returns to a stable frame after each effect. User confirms the visual checks are complete.

### Picotron

- [x] Launch the interactive showcase from [`examples/README.md`](../examples/README.md), then test low, medium, and high for every effect and each displayed variant. User confirms the visual checks are complete.
- [x] Check the full 240×136 composition, clipping at the screen edges, and the update/draw order when particles or lightning overlap the scene. User confirms the visual checks are complete.
- [x] Check that camera, clipping, palette, and drawing state return to normal after switching effects or profiles. User confirms the visual checks are complete.

### LÖVE

- [x] Run the LÖVE 11.5.0 demo in the regular game window. User confirms the visual checks are complete; the local MCP bridge is offline.
- [x] At every quality, inspect all seven effects and their variants. Check shader shockwave and its fallback, Mode 7 texture edges, particle bounds, and window resize behavior. User confirms the visual checks are complete.
- [x] Trigger overlapping effects and confirm canvases, shader state, color, blend mode, and scissor state are restored after drawing. User confirms the visual checks are complete.

### TIC-80

- [x] Build the current showcase with `python tools/tic80_include.py examples/tic80/demo.lua -o examples/tic80/build/demo.lua`, import that generated file into TIC-80, and run it. User confirms the visual checks and measurements are complete.
- [x] At each quality, cycle through all seven effects and variants, checking the 240×136 view, clipping, controls, and frame stability. User confirms the visual checks are complete.
- [x] Check scroll/camera, palette, and clipping restoration after each effect and after switching modules. User confirms the visual checks are complete.

## Shared effect and state checks

- [x] Particles: explosion, sparks, trail, smoke, dust; point, line, and area emission. User confirms all engine visual checks are complete.
- [x] Screen effects: trauma shake, directional impulses in each supported direction, flash, and shockwave/ring. User confirms all engine visual checks are complete.
- [x] Pixel deformation: wave-only and line rotation, squash/stretch, and every supported dissolve/dither mode. User confirms all engine visual checks are complete.
- [x] Palette: color cycle, night, sepia, monochrome, glow/pulse, custom mapping where exposed, and negative/inversion flash. User confirms all engine visual checks are complete.
- [x] Pseudo-3D: textured and fallback ground, curved road, starfield, camera variation, and projected objects. User confirms all engine visual checks are complete.
- [x] Flames: campfire and directional flamethrower. User confirms all engine visual checks are complete.
- [x] Electricity: branched and clean bolts, varied endpoints, and repeated strikes. User confirms all engine visual checks are complete.
- [x] In each engine, exercise effect combinations where the demo allows it and verify that one effect does not leave camera, palette, clipping, color, blend, shader, or canvas state behind. User confirms all engine visual checks are complete.

## Record results

For each engine/profile run, record the runtime version, cartridge or staged folder, effects and variants exercised, control result, visual result, state-restoration result, and screenshot or capture path. Record expected engine differences separately; for example, fantasy-console shockwaves are ring cues rather than framebuffer ripples.

| Engine / version | Quality | Effects and variants | Controls / draw order / state | Result and capture path |
| --- | --- | --- | --- | --- |
|  | low |  |  |  |
|  | medium |  |  |  |
|  | high |  |  |  |

The table above is for detailed reproducibility. Visual checks are user-confirmed complete for all four engines, but individual run data and capture paths have not yet been entered.
