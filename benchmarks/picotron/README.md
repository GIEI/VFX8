# Picotron Performance Benchmark

Run from the repository root on a machine with Picotron installed:

```powershell
./benchmarks/picotron/run.ps1 -PicotronExe "K:\Games\picotron\picotron.exe"
```

The runner creates a disposable Picotron home, stages the current engine modules, runs every scenario, validates the expected records, writes a raw CSV and a Markdown summary under `benchmarks/results/`, then removes the temporary home. On failure it preserves the home and runtime logs for diagnosis.

The default run records 225 rows: seven effects plus a baseline, typical and saturated work at `low`, `medium`, and `high`, repeated five times. Each repetition warms up for 30 frames and samples 120 frames. Shorter settings can be used to validate the runner; they are not release measurements:

```powershell
./benchmarks/picotron/run.ps1 -PicotronExe "K:\Games\picotron\picotron.exe" -WarmupFrames 2 -SampleFrames 5 -Repetitions 1 -Output "$env:TEMP\picotron-pilot.csv"
```

The test uses Picotron's `stat(1)` CPU fraction and `stat(7)` operating FPS mode. It reports the minimum observed FPS mode, which is quantized to 60/30/20/15, rather than claiming precise frame times. It samples Lua heap with `collectgarbage("count")` in KB before construction, after setup, after warm-up, and after measurement. The measured heap delta includes collection and allocator reuse; it is not a per-frame allocation counter. Pool counts are reported where an effect owns a pool; coordinate and color mapping rows use explicit operation counts. Pseudo-3D additionally reports its star count.

CPU readings include a fixed 240×136 background field in every case. They are runtime CPU-budget fractions on this host; they do not measure GPU completion. The `pixel_deform` and `palette_fx` saturated workloads are helper-call stress levels because these APIs do not own object pools. The screen effects module does not scale its wave capacity by quality, so that pool remains eight waves in all three profile runs.

The runtime documents `stat(1)` and `stat(7)` and a 32 MB process memory limit in the [Picotron manual](https://www.lexaloffle.com/dl/docs/picotron_manual.html). This benchmark records Lua heap deltas separately from the process limit; it does not infer total process memory from the Lua heap.
