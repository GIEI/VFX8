# Cross-Engine Performance Checklist

Use `benchmarks/README.md` for the shared workload definitions and `benchmarks/results/template.md` when adding a new manual result. Keep raw observations, runtime version, host, code revision, warm-up, sample count, and repetitions with each report.

## Completed or runnable in this checkout

- [x] PICO-8 visual checks and performance measurements are complete per user confirmation (2026-10-03), in addition to the historical typical-load measurements, repeated saturated particle/pseudo-3D reports, and showcase code-token budgets. Exact new measurements have not been added to this repository; the local bridge still cannot capture native console output.
- [x] Picotron has an automated benchmark for all seven effects, baseline/typical/saturated scenarios, three profiles, CPU budget, operating FPS mode, Lua heap deltas, and pool/workload counts. Its complete five-run report is generated as `benchmarks/results/picotron-effects.md` with raw rows in `benchmarks/results/picotron-effects.csv`.
- [x] LÖVE has a repeatable five-run benchmark for all seven effects at low/medium/high quality, with baseline/typical/saturated workloads, update/draw CPU time, Lua heap deltas, texture memory, and Mode 7 shader availability. The harness and run procedure are documented in `benchmarks/love2d/` and `benchmarks/README.md`.
- [x] TIC-80 source include build, native visual checks, and performance measurements are complete per user confirmation (2026-10-03); the user previously confirmed all seven effects work. Exact new measurement values have not been added to this repository.

## Measurements that still require an available native runtime or explicit user-machine data

- [x] Complete native PICO-8 visual and performance checks. The user confirms completion; raw 600-frame records and five-run medians have not been imported into the repository, and this environment's bridge does not expose the running cart's `printh()` output.
- [ ] Measure PICO-8 code tokens for each module included alone, and repeat showcase token counts if source changes. Current token reports cover the four sample carts.
- [ ] Measure Picotron's full program memory or allocation ceiling where the runtime exposes it; the current report records only Lua heap deltas and the runtime's CPU/FPS indicators.
- [x] Complete LÖVE's native visual/profile checks. The user confirms these are complete; screenshots and profile notes have not been added here.
- [ ] Measure additional LÖVE window resolutions for shockwave cost; the 320×180 all-effects benchmark is automated, but GPU completion time is not exposed by its Lua timing.
- [x] Complete native TIC-80 visual and performance checks. The user confirms completion; raw `time()` samples, code usage, memory limits, and frame pacing values have not been imported into the repository. This workstation still has no TIC-80 executable for independent capture.
- [ ] Repeat all reported results on the intended release machine and include its CPU model, operating system, engine versions, display scale, and frame-cap settings.

Do not treat a clean startup, source inspection, or a measurement from another engine as a performance result for the target runtime.
