# Benchmarking

Performance numbers are deliberately kept separate from implementation limits. The values in each effect page are hard capacity bounds; they are not measured frame-time guarantees.

## Current verification

| Engine | Runtime/version | Checks completed | Measurements |
| --- | --- | --- | --- |
| PICO-8 | Version not exposed by the available bridge | User confirms visual checks and performance measurements are complete (2026-10-03); core/advanced profile contracts pass at low/medium/high | Historical measurements and showcase token budgets are recorded. The user-confirmed new measurements' raw values and captures have not been added here; the local bridge cannot capture native console output. See [profile results](results/pico8-profile-smoke.md), [particle stress results](results/pico8-particles-stress.md), and [token report](results/pico8-showcase-token-budget.md) |
| Picotron | 0.3.0d, isolated native home; user-tested native demo | User confirms all seven effects work in the native demo; automated smoke also passes covered variants, low/medium/high, and textured/fallback pseudo-3D paths | Five-run benchmark covers baseline/typical/saturated for all effects/profiles. See [Picotron results](results/picotron-effects.md) and [run procedure](picotron/README.md) |
| LÖVE | 11.5.0 | User confirms native visual checks are complete; portable contracts and native API harness pass. The local demo MCP endpoint is offline. | Five-run all-effects benchmark covers baseline/typical/saturated at low/medium/high with update/draw time, heap deltas, texture memory, and shader availability. See [LÖVE results](results/love2d-effects-latest.md) and [raw CSV](results/love2d-effects-latest.csv) |
| TIC-80 | 1.2.0 (user-confirmed native test) | User confirms visual checks and performance measurements are complete (2026-10-03); portable contracts and include tests pass | Raw timing and resource values have not been supplied for this report |

PICO-8 interactive lockstep boot timed out, while non-interactive profile contracts and showcase carts pass. The user confirms completing native visual checks on all four engines and performance measurements on PICO-8/TIC-80; detailed PICO-8/TIC-80 values and captures were not supplied for inclusion in the reports. LÖVE 11.5.0 native contracts pass when the regression runner can initialize its user filesystem; the local MCP connection is offline. The Picotron smoke can be repeated with `tests/picotron/run-smoke.ps1`; it uses a temporary home and checks all three profiles. Historical PICO-8 profile measurements used two warm-up frames and ten sampled frames per scenario, repeated over five launches. The pseudo-3D stress carts use three warm-up frames and 600 samples per profile, repeated over five launches; they fill the profile's star and object limits and keep them stable. Existing measurements cover rendering cost, not maximum particle emissions or sustained update-heavy simulations.

## Repeatable procedure

For Picotron effect measurements, run `./benchmarks/picotron/run.ps1 -PicotronExe <path-to-picotron.exe> -RuntimeVersion <version>` in PowerShell when the isolated runtime does not write its version log. It records all seven effects and the three workload levels across `low`, `medium`, and `high`, with five repetitions per scenario. See [the Picotron benchmark details](picotron/README.md).

For LÖVE all-effects measurements, run `python benchmarks/love2d/run_effects.py`. This creates a hidden, VSync-disabled 320×180 window and runs five repetitions of baseline, typical, and saturated workloads for all seven modules and three profiles. Baseline and typical cases use 30 warm-up and 120 sampled frames; saturated cases use 30 warm-up and 600 sampled frames. It writes a raw CSV and Markdown summary under `benchmarks/results/`. Use `--warmup-frames`, `--sample-frames`, and `--repetitions` for a short runner pilot; pilot results are not release measurements. The earlier particle-only runner remains available as `python benchmarks/love2d/run.py`.

To reproduce PICO-8 stress observations, open each `tests/pico8/<effect>_stress_<profile>.p8` cart in the native runtime and let it complete 600 measured draw frames after warm-up. Read the `VFX8_EFFECT_STRESS` line from the runtime console; it contains the effect/profile, active count, capacity, maximum emitted count, CPU mean/min/max, and PICO-8 memory before/after. `screen_fx_stress.p8` is the low-profile cart. Repeat each profile five times before reporting medians. The user confirms the current PICO-8 visual and performance checks are complete; the bridge itself can validate startup but does not expose this long-run `printh()` record, so raw console data must be transcribed from the user's runs for a reproducible report.

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
