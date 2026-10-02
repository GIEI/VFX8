# Benchmarking

Performance numbers are deliberately kept separate from implementation limits. The values in each effect page are hard capacity bounds; they are not measured frame-time guarantees.

## Current verification

| Engine | Runtime/version | Checks completed | Measurements |
| --- | --- | --- | --- |
| PICO-8 | Version not exposed by the available bridge | Three focused showcase carts and standalone electricity cart boot; split core and advanced contracts pass at low/medium/high; new 600-frame effect stress carts boot at all profiles | Historical typical-load CPU, saturated pseudo-3D/particle samples, and current showcase token budgets are recorded. New cross-effect carts expose repeatable CPU, memory, and pool markers but need manual capture from PICO-8 because the available bridge only reports clean startup. See [profile results](results/pico8-profile-smoke.md), [particle stress results](results/pico8-particles-stress.md), and [token report](results/pico8-showcase-token-budget.md) |
| Picotron | 0.3.0d, isolated native home | All seven modules, covered variants, and low/medium/high pass update/draw smoke; textured and fallback pseudo-3D paths pass | Repeatable benchmark covers baseline/typical/saturated for all effects/profiles. See [Picotron results](results/picotron-effects.md) and [run procedure](picotron/README.md) |
| LÖVE | 11.5.0 installed | Portable contracts pass; native game launch currently fails at filesystem initialization. The local demo MCP endpoint is offline. | Historical five-run particle benchmark is recorded in the [particle benchmark report](results/love2d-particles.md) and [raw CSV](results/love2d-particles-latest.csv). Interactive demo and shader visual checks remain open |
| TIC-80 | 1.2.0 (user-confirmed demo) | Showcase reported working; portable contracts and include tests pass | Runtime timing and code usage not measured |

PICO-8 interactive lockstep boot timed out, while non-interactive profile contracts and showcase carts pass. LÖVE 11.5.0 is installed, but both the native test launch and the local MCP connection are currently unavailable in this environment. The Picotron smoke can be repeated with `tests/picotron/run-smoke.ps1`; it uses a temporary home and checks all three profiles. Historical PICO-8 profile measurements used two warm-up frames and ten sampled frames per scenario, repeated over five launches. The pseudo-3D stress carts use three warm-up frames and 600 samples per profile, repeated over five launches; they fill the profile's star and object limits and keep them stable. The new stress carts for other PICO-8 effects also use a 600-frame measurement window, but native console capture and repeat runs are still needed. Existing measurements cover rendering cost, not maximum particle emissions or sustained update-heavy simulations.

## Repeatable procedure

For Picotron effect measurements, run `./benchmarks/picotron/run.ps1 -PicotronExe <path-to-picotron.exe>` in PowerShell. It records all seven effects and the three workload levels across `low`, `medium`, and `high`, with five repetitions per scenario. See [the Picotron benchmark details](picotron/README.md).

For LÖVE particle measurements, run `python benchmarks/love2d/run.py`. This creates a hidden, VSync-disabled 320×180 window, warms up each scenario for 120 frames, samples 600 frames, and runs five repetitions of baseline, typical, and saturated workloads. It writes the raw observations under `benchmarks/results/`.

For PICO-8 stress observations, open each `tests/pico8/<effect>_stress_<profile>.p8` cart in the native runtime and let it complete 600 measured draw frames after warm-up. Read the `VFX8_EFFECT_STRESS` line from the runtime console; it contains the effect/profile, active count, capacity, maximum emitted count, CPU mean/min/max, and PICO-8 memory before/after. `screen_fx_stress.p8` is the low-profile cart. Repeat each profile five times before reporting medians. The configured native bridge can validate startup but does not expose this long-run `printh()` record.

For every run, record the engine version, OS/device, display and vsync settings, source revision, quality profile, resolution, warm-up frames, sample frames, and at least five runs. Measure an equivalent scene with the effect disabled as a baseline. Keep the trigger sequence and object counts identical between baseline and effect runs. See the [cross-engine performance checklist](performance-checklist.md) for remaining work.

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
