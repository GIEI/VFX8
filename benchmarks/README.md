# Benchmarking

Performance numbers are deliberately kept separate from implementation limits. The values in each effect page are hard capacity bounds; they are not measured frame-time guarantees.

## Current verification

| Engine | Runtime/version | Checks completed | Measurements |
| --- | --- | --- | --- |
| PICO-8 | Version not exposed by the available bridge | Full demo, palette contract, profile benchmark, and 600-frame pseudo-3D and particle stress carts pass clean boot checks | Five short runs recorded typical-load CPU for all effects and saturated pseudo-3D draw CPU; single-run before/after particle saturation samples added at all profiles. Token count and repeated saturation runs unavailable; see [profile results](results/pico8-profile-smoke.md) and [particle stress results](results/pico8-particles-stress.md) |
| Picotron | Installed Picotron, isolated headless run | All seven modules load; update/draw calls pass, including textured and fallback pseudo-3D paths | Not measured |
| LÖVE | 11.5.0 | Native runtime contracts pass for particles, pseudo-3D, screen effects, and palette; actual image userdata and graphics-state stack are exercised | Five runs each for baseline, typical, and saturated particles at 320×180; CPU-side update/draw and Lua heap samples recorded in the [particle benchmark report](results/love2d-particles.md) and [raw CSV](results/love2d-particles-latest.csv). The pseudo-3D shader path remains mocked in its API contract and the interactive demo MCP bridge was unavailable |
| TIC-80 | 1.2.0 (user-confirmed demo) | Showcase reported working; portable contracts and include tests pass | Runtime timing and code usage not measured |

PICO-8 interactive lockstep boot timed out, while non-interactive boot checks pass. The LÖVE runtime contract now runs under the installed LÖVE executable; visual demo verification and shader compilation through the live demo remain open because its MCP bridge did not connect. The PICO-8 profile cart uses two warm-up frames and ten sampled frames per scenario, repeated over five launches. The pseudo-3D stress carts use three warm-up frames and 600 samples per profile, repeated over five launches; they fill the profile's star and object limits and keep them stable. These measurements cover rendering cost, not maximum particle emissions or sustained update-heavy simulations.

## Repeatable procedure

For LÖVE particle measurements, run `python benchmarks/love2d/run.py`. This creates a hidden, VSync-disabled 320×180 window, warms up each scenario for 120 frames, samples 600 frames, and runs five repetitions of baseline, typical, and saturated workloads. It writes the raw observations under `benchmarks/results/`.

For every run, record the engine version, OS/device, display and vsync settings, source revision, quality profile, resolution, warm-up frames, sample frames, and at least five runs. Measure an equivalent scene with the effect disabled as a baseline. Keep the trigger sequence and object counts identical between baseline and effect runs.

Use these three workload levels for each effect:

1. **Baseline:** module loaded, no active effect instances.
2. **Typical:** the effect's documented demo at `low` or the engine's cautious profile, with one normal trigger.
3. **Saturated:** fill each fixed pool and reach the documented per-update emission limit; continue drawing for at least 600 frames after warm-up.

Record minimum, median, and 95th-percentile frame time when the runtime exposes frame timing. Also record peak active items and confirm the configured limits are not exceeded. Do not compare FPS readings while vsync or an external frame cap is active.

## Engine-specific measurements

- **PICO-8:** record CPU percentage from the runtime profiler and the cart's code/token count. Save the token count for the demo and for each module included alone. A clean boot is not a CPU or token measurement.
- **Picotron:** record frame time, memory use, and any code limits exposed by the installed runtime. Include the cartridge resolution and color count.
- **LÖVE:** record `love.timer.getFPS()` only when uncapped, plus CPU frame-time samples and Lua heap before/after the run. For the shockwave, include canvas dimensions and whether a canvas or shader fallback was used.
- **TIC-80:** record code usage and frame timing from the target runtime, along with cartridge dimensions and palette mode.

## Result template

Copy [`results/template.md`](results/template.md) for each engine/effect/profile group. Enter `unavailable` where an engine does not expose a metric; do not estimate it from a different engine.
