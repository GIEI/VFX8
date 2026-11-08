# Cross-Engine Performance Checklist

Use `benchmarks/README.md` for the shared workload definitions and `benchmarks/results/template.md` when adding a new manual result. Keep raw observations, runtime version, host, code revision, warm-up, sample count, and repetitions with each report.

## Completed or runnable in this checkout

- [x] PICO-8 visual checks and performance measurements for the original seven effects are complete per user confirmation (2026-10-03), in addition to historical typical-load measurements, repeated saturated particle/pseudo-3D reports, and showcase token budgets. Rain/snow boot and contract checks pass; their visual and performance evidence is still open.
- [x] Picotron has an automated benchmark for the original seven effects, baseline/typical/saturated scenarios, three profiles, CPU budget, operating FPS mode, Lua heap deltas, and pool/workload counts. Its five-run report is in `benchmarks/results/picotron-effects.md`, with raw rows in `benchmarks/results/picotron-effects.csv`. Rain and snow are not included.
- [x] LÖVE has a repeatable five-run benchmark for the original seven effects at low/medium/high quality, with baseline/typical/saturated workloads, update/draw CPU time, Lua heap deltas, texture memory, and Mode 7 shader availability. Rain/snow runtime contracts pass, but the modules are not included in the benchmark.
- [x] TIC-80 source include build, native visual checks, and performance measurements for the original seven effects are complete per user confirmation (2026-10-03). Rain and snow still need a native visual run and measured results.

## Measurements that still require an available native runtime or explicit user-machine data

- [x] Complete native PICO-8 visual and performance checks. The user confirms completion; raw 600-frame records and five-run medians have not been imported into the repository, and this environment's bridge does not expose the running cart's `printh()` output.
- [ ] Measure PICO-8 code tokens for each module included alone, and repeat showcase token counts if source changes. Current token reports cover the four sample carts.
- [ ] Measure Picotron's full program memory or allocation ceiling where the runtime exposes it; the current report records only Lua heap deltas and the runtime's CPU/FPS indicators.
- [x] Complete LÖVE's native visual/profile checks. The user confirms these are complete; screenshots and profile notes have not been added here.
- [ ] Measure additional LÖVE window resolutions for shockwave cost; the 320×180 all-effects benchmark is automated, but GPU completion time is not exposed by its Lua timing.
- [x] Complete native TIC-80 visual and performance checks. The user confirms completion; raw `time()` samples, code usage, memory limits, and frame pacing values have not been imported into the repository. This workstation still has no TIC-80 executable for independent capture.
- [ ] Repeat all reported results on the intended release machine and include its CPU model, operating system, engine versions, display scale, and frame-cap settings.

## VFX8 1.1.0 weather follow-up

- [ ] Measure rain and snow on PICO-8, Picotron, LÖVE, and TIC-80 at `low`, `medium`, and `high` using the shared baseline/typical/saturated protocol. The current benchmark runners and result tables cover only the original seven modules.
- [ ] Record PICO-8 oblique/vertical rain CPU and token costs, Picotron/LÖVE timing and memory, and TIC-80 code/time usage. Report unavailable metrics as unavailable; do not estimate them from another engine.
- [ ] Attach native weather screenshots or record the visual result for each engine, profile, and variant in `docs/native-visual-checklist.md`.

Do not treat a clean startup, source inspection, or a measurement from another engine as a performance result for the target runtime.
