# Implementation plan

## Goal and scope

Build a collection of composable 2D visual effects for games with widely varying resources. Each effect should produce a recognizable result on the four engines while keeping code and costs specific to each platform. The first effect, an adaptive particle system, is implemented for all four engines; the remaining effects are planned.

The first version will use Lua or each engine's Lua dialect and native drawing primitives. It will not require external assets, extra frameworks, or a mandatory shared runtime. Advanced capabilities will remain optional.

## Conventions to establish with the first implementation

1. Use the five names `particles`, `screen_fx`, `pixel_deform`, `palette_fx`, and `pseudo3d` in `src/<engine>/`, `examples/<engine>/`, and `docs/effects/`. Each module gets one dedicated page covering its variants.
2. Keep a shared conceptual lifecycle: setup, trigger, update, and draw. The concrete syntax will be idiomatic for each engine and established with the first effect.
3. Make coordinates, time units, and draw order explicit. Fixed-frame fantasy consoles and LÖVE's `dt` must not produce different durations because of implicit conversions.
4. Avoid per-frame allocations where practical: use reusable pools, configurable capacity limits, and deterministic cleanup of expired items.
5. Do not permanently change the game's camera, palette, clip, color, or other graphics state. Document exceptions and verify that state is restored.
6. Define a saturation policy for every effect, such as dropping new emissions or replacing the oldest item. The policy must be deterministic and described on the effect page.
7. Distribute each effect as a file that can be included in an existing game without defining the engine's main callbacks. Demos use the same inclusion mechanisms described in [integration.md](integration.md).

## Scalability

The three profiles represent **quality targets**, not a promise of the same object count on every device.

| Profile | Expected behavior | Typical parameters |
| --- | --- | --- |
| `low` | Minimum cost and a cautious default for fantasy consoles | few objects, simple drawing, short duration |
| `medium` | More detail with a controlled cost | more objects, more trail samples, smoother animation |
| `high` | Higher quality on engines that support it | greater density, more layers, or optional drawing passes |

Configuration should support both a profile and explicit limits, such as maximum capacity and new emissions per frame. Actual capacities are engine-specific. A profile that exceeds a limit must be clamped explicitly or omitted; work per frame must never grow silently. Numeric values will be set after benchmarking.

## Development sequence

The order below is the development priority: first, feedback useful in almost any game; then effects with increasing complexity. Each phase delivers the module on every engine claimed as supported, a demo per engine, a dedicated page, and reproducible measurements. When a visual result requires different techniques, the page must describe the visual difference and avoid promising framebuffer processing where it is not practical.

### 1. Adaptive particle system — `particles`

- **Variants:** explosions, sparks, trails, smoke, and landing dust; presets built on the same base routine.
- **Emission:** point, line segment, and bounded area. Parameters for gravity, inertia, lifetime, color ramping, and shrinking pixel size over time.
- **Budget:** fixed-capacity pool, per-frame emission limit, active-item update limit, and explicit behavior when the pool is full.
- **Scaling:** `low` uses few items and simple primitives; higher profiles increase density, trail samples, and detail within configured limits.

**Status:** implemented for PICO-8, Picotron, LÖVE, and TIC-80. The module provides all five presets, three emission types, fixed-capacity pools, update-interval emission caps, and `low`/`medium`/`high` profiles. Demos and usage documentation are connected. Actual engine execution, performance measurements, and benchmarked budgets remain to be verified; values are conservative starting limits, not measured results.

**Deliverable:** all five presets and three emission types work in demos for supported engines; saturation does not exceed the declared work budget. This module establishes the shared interface and benchmark method.

### 2. Screen shake and distortion — `screen_fx`

- **Shake:** directional impulse and damped trauma-based oscillation with controllable amplitude, duration, and decay. The final offset must compose with the game's camera and then be restored.
- **Shockwave/ripple:** a circular wave that displaces surrounding pixels where feasible. A simplified rendering with primitives or sampled bands is acceptable on engines with tighter budgets, but must be identified as such.
- **Global flash:** temporary screen flash and color inversion, with a defined duration and restoration of the palette/graphics state. Pausing gameplay during a hit remains the application's choice.
- **Scaling:** shake intensity and frequency; resolution, affected area, and sample/pass count for ripple and flash.

**Deliverable:** effects can be combined without leaving the camera or colors altered after drawing; each engine's ripple implementation is described and measured.

### 3. Pixel-based deformation and animation — `pixel_deform`

- **Wave/wobble:** sinusoidal motion for water, vegetation, or flags, applied to coordinates, rows, or a buffer depending on the engine.
- **Squash and stretch:** procedural elastic scaling of a sprite, with an anchor point and return to its original shape.
- **Dissolve:** appearance/disappearance through dithering matrices, with checkerboard, spiral, and burn variants where the engine budget allows.
- **Scaling:** rows/samples updated, transformed surface, animation steps, and pattern complexity.

**Deliverable:** each variant has a demo showing the object before, during, and after the effect; transformations do not corrupt sprites, UI, or shared buffers.

### 4. Palette and color cycling — `palette_fx`

- **Color cycling:** timed rotation of color indices or color maps for water, lava, waterfalls, and signs.
- **Local flash/glow:** a pulse on a hit or selectable object. Whole-screen flash belongs to `screen_fx`.
- **Scene filters:** day/night, sepia, and monochrome maps, with defined priority when multiple filters are active.
- **Scaling:** number of colors or animated areas and update frequency. Measure cost and fidelity separately on indexed-palette engines and LÖVE, where the concrete technique may differ.

**Deliverable:** multiple color effects can coexist, and disabling them restores the exact previous palette or color state.

### 5. Pseudo-3D rasterizer — `pseudo3d`

- **Perspective plane:** Mode 7-style ground or road with controllable camera and horizon.
- **3D starfield:** stars at different depths, perspective projection, and multi-layer parallax.
- **Projected sprites:** depth-based apparent scale, clipping, and Z ordering consistent with the plane.
- **Budget:** limit sampled rows/columns, draw distance, star count, and objects. Reuse projection tables when parameters are unchanged; avoid per-pixel work in the cautious profile unless measurements show it fits.

**Deliverable:** one demo combines the plane, stars, and projected objects; all three profiles show visible quality differences and have measured costs. This module comes last because it requires the most projection work and verification.

### Polish and initial release

- Test combinations of the five modules in one scene, checking draw order, palette priority, and graphics state.
- Reduce benchmark regressions without compromising clarity or integration.
- Prepare examples that can be copied into carts/projects and choose a license before public distribution.
- Publish a compatibility matrix with the minimum engine versions verified.

## Required page for each effect

Each `docs/effects/<name>.md` must include:

1. **Result** and use cases, with an image or GIF where useful.
2. **Support:** engines and versions tested, including visual differences.
3. **Integration:** files to copy/include and a complete minimal example for every supported engine.
4. **API:** parameters, defaults, units, lifecycle, and draw order.
5. **Quality:** `low`/`medium`/`high` settings, configurable limits, and saturation behavior.
6. **Cost:** memory, code size where relevant, CPU/frame time, and measurement method.
7. **Limits and interactions:** palette, clipping, camera, composition with other effects, and state cleanup.

## Measurements and acceptance criteria

Each benchmark must be repeatable: record the same scene, activation sequence, frame count, engine version, and profile. Measure at least a typical case and a saturated case. Compare the effect scene with an equivalent scene without the effect.

For PICO-8, record CPU usage and cartridge code/token cost; for TIC-80, code consumption and observable execution time; for Picotron and LÖVE, frame time and memory where engine tools allow it. Separate measurements from estimates. Store results in `benchmarks/` and link them from the effect page.

An effect is complete when:

- it works in the demo of every engine claimed as supported;
- it respects the configured item/work limit under saturation;
- it leaves no altered graphics state after drawing;
- it has a dedicated page, copyable examples, and reproducible measurements;
- it can be included in an existing game/cartridge without replacing its callbacks, input, or assets;
- its cautious profile is verified on the actual engine, with higher profiles verified where available.

## Technical references

- [PICO-8 manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html): API, tokens, CPU, and memory.
- [Picotron manual](https://www.lexaloffle.com/dl/docs/picotron_manual.html): carts, Lua files, and `include()`.
- [LÖVE wiki](https://love2d.org/wiki/Main_Page): lifecycle, graphics, and measurement tools.
- [TIC-80 documentation](https://tic80.com/learn): console specifications, API, and cartridge format.
