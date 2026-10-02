# Implementation plan

## Goal and scope

Build a collection of composable visual effects for games with widely varying resources. Each effect should produce a recognizable result on the four engines while keeping code and costs specific to each platform. All seven modules are implemented for all four engines. Picotron headless runtime smoke now covers each module's main update and draw path; interactive visual verification and benchmark measurements remain open.

The first version will use Lua or each engine's Lua dialect and native drawing primitives. It will not require external assets, extra frameworks, or a mandatory shared runtime. Advanced capabilities will remain optional.

## Conventions to establish with the first implementation

1. Use the seven names `particles`, `screen_fx`, `pixel_deform`, `palette_fx`, `pseudo3d`, `flames`, and `electricity` in `src/<engine>/`, `examples/<engine>/`, and `docs/effects/`. Each module gets one dedicated page covering its variants.
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
- **Budget:** fixed-capacity pool, per-update emission limit, active-item update limit, and explicit behavior when the pool is full.
- **Scaling:** `low` uses few items and simple primitives; higher profiles increase density, trail samples, and detail within configured limits.

**Status:** source implementations, demos, usage documentation, portable API contract checks, and TIC-80 include tests exist for all four engines. The module provides all five presets, three emission types, fixed-capacity pools, per-update emission caps, and `low`/`medium`/`high` profiles. PICO-8 native contracts and Picotron's isolated native profile smoke pass; LÖVE staging passes, but native launch currently fails during filesystem initialization in this environment. PICO-8 saturated 600-frame measurements show 4.37% / 6.40% / 8.30% CPU after local-array/count caching, down from 5.06% / 7.82% / 10.44% in one baseline run per profile. LÖVE 11.5.0 has a repeatable five-run benchmark for baseline, typical, and saturated pools, with update/draw timing and heap deltas, though the native runtime is not currently available here. Showcase code token counts are recorded; standalone per-module token counts, memory costs, saturated measurements on Picotron and TIC-80, and interactive verification remain open.

**Deliverable:** all five presets and three emission types work in demos for supported engines; saturation does not exceed the declared work budget. This module establishes the shared interface and benchmark method.

### 2. Screen shake and distortion — `screen_fx`

- **Shake:** directional impulse and damped trauma-based oscillation with controllable amplitude, duration, and decay. The final offset must compose with the game's camera and then be restored.
- **Shockwave/ripple:** a circular wave that displaces surrounding pixels where feasible. A simplified rendering with primitives or sampled bands is acceptable on engines with tighter budgets, but must be identified as such.
- **Global flash:** temporary screen flash and color inversion, with a defined duration and restoration of the palette/graphics state. Pausing gameplay during a hit remains the application's choice.
- **Scaling:** shake intensity and frequency; resolution, affected area, and sample/pass count for ripple and flash.

**Status:** trauma shake, directional impulses, solid flash overlays, bounded wave pools, and a cached shake-offset API for game-owned cameras are implemented for all four engines and connected to demos. LÖVE captures the scene into a reusable canvas and applies a shader ripple around the newest active wave; PICO-8, Picotron, and TIC-80 use the documented ring cue. PICO-8's `render()` composes shake with the active camera and restores it around screen-space overlays. For indexed scenes, `palette_fx` supports a timed negative-map flash using the game's RGB palette and explicit draw-call color mapping; the APIs do not alter global palette or framebuffer state. Native runtime verification and measurements remain open.

**Deliverable:** effects can be combined without leaving graphics state altered after drawing; each engine's ripple implementation is described and measured.

### 3. Pixel-based deformation and animation — `pixel_deform`

- **Wave/wobble:** sinusoidal motion for water, vegetation, or flags, applied to coordinates, rows, or a buffer depending on the engine.
- **Squash and stretch:** procedural elastic scaling of a sprite, with an anchor point and return to its original shape.
- **Dissolve:** appearance/disappearance through dithering matrices, with checkerboard, spiral, and burn variants where the engine budget allows.
- **Scaling:** rows/samples updated, transformed surface, animation steps, and pattern complexity.

**Status:** deterministic coordinate-wave, squash/stretch scale, and 4×4 ordered/checker/spiral visibility helpers are implemented for all four engines and connected to demos. Native verification and performance measurements remain open; sprite raster integration remains game-owned by design.

**Deliverable:** each variant has a demo showing the object before, during, and after the effect; transformations do not corrupt sprites, UI, or shared buffers.

### 4. Palette and color cycling — `palette_fx`

- **Color cycling:** timed rotation of color indices or color maps for water, lava, waterfalls, and signs.
- **Local flash/glow:** a pulse on a hit or selectable object. Whole-screen flash belongs to `screen_fx`.
- **Scene filters:** day/night, sepia, and monochrome maps, with defined priority when multiple filters are active.
- **Scaling:** number of colors or animated areas and update frequency. Measure cost and fidelity separately on indexed-palette engines and LÖVE, where the concrete technique may differ.

**Status:** all four engine modules and demo variants are implemented. The API maps colors at draw-call boundaries and does not change global palette state. Built-in filters cover 16 entries; custom maps are validated against the configured color count, including Picotron's 64-color range. Timed palette-negative mapping builds from caller-supplied RGB values and is included in the demo variants. Cycle shifts and pulse phases are cached during `update()`; a single PICO-8 stress run showed a small whole-workload reduction from 10.76% to 10.56% CPU for 128 map calls per frame. PICO-8 palette contracts pass natively; Picotron profile smoke exercises all palette variants. LÖVE portable contracts pass, while native launch remains blocked by filesystem initialization; TIC-80 runtime validation is open.

**Deliverable:** color cycles, local flashes, glow pulses, and scene filters work through explicit color mapping without leaving graphics state altered.

### 5. Pseudo-3D rasterizer — `pseudo3d`

- **Perspective plane:** textured Mode 7 ground/road with camera heading and perspective; procedural curved bands remain the fallback.
- **3D starfield:** stars at different depths, perspective projection, and multi-layer parallax.
- **Projected sprites:** depth-based apparent scale, clipping, Z ordering, and a road-aligned projection helper consistent with the plane.
- **Budget:** limit sampled rows/columns, draw distance, star count, and objects. Reuse projection tables when parameters are unchanged; avoid per-pixel work in the cautious profile unless measurements show it fits.

**Status:** all four modules include engine-specific Mode 7 texture paths, layered stars, and depth-sorted projected objects; `set_road()` configures the procedural fallback and `project_road()` provides road-aligned coordinates for game-owned sprites. PICO-8 uses `tline`, Picotron uses `tline3d`, TIC-80 samples sprite memory in quality-scaled blocks, and LÖVE uses a shader. The multi-effect demo builds a small checker road texture at runtime. PICO-8 coverage now scales with quality (55%/75%/100%) while filling the uncovered ground; five typical and five 600-frame saturated draw runs measure 20.22%/25.21%/30.53% and 20.84%/26.50%/33.04% CPU respectively. Other native runtime checks, saturated costs for the remaining effects, and PICO-8 token counts remain open.

### 6. Flame simulation — `flames`

- **Directional jet:** a flamethrower stream emitted from an origin along a caller supplied vector.
- **Campfire:** an upward plume continuously emitted around a base point.
- **Budget:** fixed structure-of-arrays pools, profile-specific capacities, and per-update emission caps; expired particles are swap-removed. Both styles use gravity, drag, color ramps, and pixel contraction.
- **API:** `new`, `emit_jet`, `emit_campfire`, `update`, `draw`, `clear`, and `stats`.

**Status:** implemented for all four engines, with demo adapters and a dedicated effect page. Runtime and visual checks are in progress; measured costs and PICO-8 token checks remain open.

**Deliverable:** both flame styles can be integrated without replacing game callbacks, and sustained emissions stay within each engine's pool and update budgets.

### 7. Electric arcs — `electricity`

- **Geometry:** fixed-endpoint jagged polyline with seeded irregular offsets and optional side branches. Every call to `strike()` selects a new deterministic shape without consuming the host game's random stream.
- **Lifecycle:** generate segments on demand, expire them after a short lifetime, and remove expired entries with swap-delete.
- **Budget:** preallocated segment and scratch-vertex arrays, quality-based subdivision/branch counts, and a hard per-update segment budget.

**Status:** implemented for all four engines, added to each demo, and documented separately. PICO-8 advanced native profile contracts and Picotron's native smoke exercise branched and clean strikes at low/medium/high. TIC-80 demo operation was previously confirmed by the user, but per-profile verification remains open. LÖVE portable contracts pass; native launch is currently blocked by filesystem initialization, and the local MCP endpoint is offline. Showcase token budgets are documented, but standalone per-module token cost remains open.

**Deliverable:** a game can connect arbitrary event points with a brief bolt while bounding geometry generation, storage, and draw work.

### Native verification, measurement, and release polish

- Run every engine demo in its native runtime at all three profiles, beginning with PICO-8's source/token and CPU limits. **Progress:** TIC-80 1.2.0's showcase is user-confirmed working. The user confirms that all seven Picotron effects work in the native demo; isolated smoke passes all modules, covered variants, and both pseudo-3D render modes. Its repeatable five-run benchmark records all seven effects at three profiles and all three workload levels: 225 observations on Picotron 0.3.0d. PICO-8 native core and advanced profile contracts and showcase carts boot successfully; 600-frame stress carts now cover the remaining five effects, but the bridge cannot capture their runtime measurements. LÖVE 11.5 staging passes, but native launch currently fails during filesystem initialization and its MCP endpoint is offline. TIC-80 native timing and standalone per-module token costs remain open. See [benchmark status](../benchmarks/README.md).
- Test effect combinations where supported, checking draw order, palette priority, callbacks, and graphics state.
- Record repeatable typical and saturated benchmark runs, including source/code costs and runtime versions. **Progress:** Picotron report is complete; PICO-8 stress carts are ready for native console capture. Native measurements for all effects in LÖVE, TIC-80, and the release machine remain open.
- Resolve engine-specific API differences found during native verification; mark unsupported behavior accurately in each effect page.
- Prepare examples that can be copied into carts/projects; the repository uses the MIT license.
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
