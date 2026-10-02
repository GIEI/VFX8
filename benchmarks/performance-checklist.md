# Cross-Engine Performance Checklist

Use `benchmarks/README.md` for the shared workload definitions and `benchmarks/results/template.md` when adding a new manual result. Keep raw observations, runtime version, host, code revision, warm-up, sample count, and repetitions with each report.

## Completed or runnable in this checkout

- [ ] PICO-8 has historical typical-load measurements for particles, screen effects, deformation helpers, palette mapping, and pseudo-3D, plus repeated saturated particle and pseudo-3D reports. New 600-frame stress carts now cover screen effects, deformation, palette mapping, flames, and electricity at all three profiles; they pass native boot validation, but this environment cannot capture their output as repeatable automated measurements. Showcase code-token budgets are recorded for all sample carts.
- [x] Picotron has an automated benchmark for all seven effects, baseline/typical/saturated scenarios, three profiles, CPU budget, operating FPS mode, Lua heap deltas, and pool/workload counts. Its complete five-run report is generated as `benchmarks/results/picotron-effects.md` with raw rows in `benchmarks/results/picotron-effects.csv`.
- [x] LÖVE has a repeatable five-run baseline/typical/saturated particle benchmark with update/draw CPU time and Lua heap deltas.
- [x] TIC-80 has a repeatable source include build; its native demo has previously been confirmed by the user.

## Measurements that still require an available native runtime or explicit user-machine data

- [ ] Capture 600-frame output from `tests/pico8/*_stress_<profile>.p8` in PICO-8 for at least five independent launches per effect/profile. The carts report CPU min/mean/max, memory before/after, active pool size, and emissions where applicable. This environment's bridge verifies clean startup but does not expose the running cart's `printh()` output or long-running samples.
- [ ] Measure PICO-8 code tokens for each module included alone, and repeat showcase token counts if source changes. Current token reports cover the four sample carts.
- [ ] Measure Picotron's full program memory or allocation ceiling where the runtime exposes it; the current report records only Lua heap deltas and the runtime's CPU/FPS indicators.
- [ ] Extend LÖVE's current particle-only five-run benchmark to all seven effects and collect shader/canvas memory, frame time, and resolution-specific shockwave cost after the native filesystem issue is resolved.
- [ ] Run the TIC-80 performance cart in the native executable and record `time()` samples, code usage, memory limits, and frame pacing at all profiles. This workstation currently has no TIC-80 executable available.
- [ ] Repeat all reported results on the intended release machine and include its CPU model, operating system, engine versions, display scale, and frame-cap settings.

Do not treat a clean startup, source inspection, or a measurement from another engine as a performance result for the target runtime.
