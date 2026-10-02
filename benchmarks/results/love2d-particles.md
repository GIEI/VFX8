# LÖVE particle benchmark

- Engine: LÖVE 11.5.0
- OS: Windows
- Source revision: `482f1b15ed8f281ad23f93b6747c34418eff1e0c` plus the uncommitted working-tree changes for this run
- Resolution: 320×180, hidden window, VSync disabled
- Warm-up: 120 frames per scenario and repetition
- Samples: 600 frames per scenario and repetition
- Repetitions: 5
- Timing: CPU-side Lua wall-clock around `update()` and the particle draw calls, using `love.timer.getTime()`
- Memory: Lua heap delta after system construction and between the end of warm-up and the end of sampling

The baseline, typical, and saturated scenarios share the same 40-rectangle background. The typical scenario uses the `low` profile with 16 long-lived explosion particles. The saturated scenario fills a 640-particle high-profile pool with long-lived particles. Values below are medians of the five per-run means or per-run p95 values. The raw per-run observations are in [`love2d-particles-latest.csv`](love2d-particles-latest.csv).

| Scenario | Active / capacity | Update mean | Update P95 | Draw mean | Draw P95 | Setup heap | Sample heap delta median (range) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Baseline | 0 / 0 | 0.00012 ms | 0.00020 ms | 0.00009 ms | 0.00020 ms | 0 KB | 0 KB (0–3.57 KB) |
| Typical | 16 / 128 | 0.00050 ms | 0.00080 ms | 0.00281 ms | 0.00420 ms | 12.80 KB | 0 KB (0–3.00 KB) |
| Saturated | 640 / 640 | 0.00337 ms | 0.00510 ms | 0.08196 ms | 0.12880 ms | 89.99 KB | 0 KB (0–1.64 KB) |

`setup heap` is the Lua heap increase from constructing the instance and filling its pool. The small, occasional sample deltas are transient runtime noise; the median measured delta was zero after warm-up. The module does not allocate a per-particle Lua object during update or draw. The measured draw interval is CPU-side command submission only; it does not measure GPU completion or end-to-end frame time. It excludes the common background and HUD draw calls.

An experimental per-frame `SpriteBatch` rebuild was also measured in five runs, then removed. Its median draw means were 0.01423 ms for the typical pool and 0.08821 ms for the saturated pool, compared with 0.00281 ms and 0.08196 ms for the direct-rectangle runs above. The trial added a retained graphics resource and did not improve the measured CPU-side draw cost, so the shipped LÖVE backend keeps direct rectangle rendering.

## Reproduction

From the repository root, run:

```sh
python benchmarks/love2d/run.py
```

The runner stages the current LÖVE particle module into a temporary game directory, runs all 15 cases, and writes the raw CSV to `benchmarks/results/love2d-particles-latest.csv`. Set `LOVE_EXECUTABLE` if LÖVE is not on `PATH` or installed in a standard location. The run disables VSync and uses a hidden window to avoid a display frame cap.

The measurements characterize this host and LÖVE 11.5.0. Repeat them on target hardware before using these values as capacity guarantees.
