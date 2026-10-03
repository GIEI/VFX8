# Picotron Effect Performance

- Runtime: Picotron 0.3.0d (stat(5)=0x1b)
- Run mode: isolated headless home; 240×136 logical display
- Repetitions: 5 per row; 30 warm-up frames and 120 sampled frames per repetition
- CPU metric: `stat(1)` fraction of the runtime CPU budget; table values are percentages
- FPS metric: minimum observed `stat(7)` operating mode (60/30/20/15), not a high-resolution frame-time measurement
- Memory metric: Lua heap delta in KB from `collectgarbage("count")`; setup delta includes allocations made by the effect constructor and initial trigger
- Host OS: Microsoft Windows NT 10.0.26200.0
- CPU: AMD Ryzen 7 5800X 8-Core Processor
- Baseline scene: fixed background field with no effect; every other row uses the same field before drawing the effect
- Saturated: fills fixed pools where possible or reaches the profile's configured workload cap; `pixel_deform` and `palette_fx` use explicit high call counts because their APIs do not own pools
- Source/runtime limits: CPU and frame-mode readings are headless runtime measurements on this host, not guarantees for a different display, cart, or machine

CPU values are medians across 5 repetition-level means. `CPU Δ` subtracts the same profile's baseline. Heap values are medians. Sample heap delta includes garbage collection and allocator reuse during rendering; it is not a per-frame allocation counter, so negative values or small repeated plateaus are possible.

| Profile | Effect | Workload | Active / limit | CPU mean | CPU p95 | CPU Δ vs baseline | Min FPS mode | Setup heap Δ | Sample heap Δ |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| low | baseline | baseline | 0 / 0 | 1.93% | 1.93% | +0.00 pp | 60 | 0.06 KB | +19.00 KB |
| low | particles | typical | 12 / 64 | 2.23% | 2.23% | +0.29 pp | 60 | 12.48 KB | -7.61 KB |
| low | particles | saturated | 64 / 64 | 3.47% | 3.47% | +1.54 pp | 60 | 12.48 KB | -7.64 KB |
| low | screen_fx | typical | 1 / 8 | 2.49% | 2.49% | +0.56 pp | 60 | 1.27 KB | +19.00 KB |
| low | screen_fx | saturated | 8 / 8 | 2.64% | 2.64% | +0.70 pp | 60 | 2.88 KB | -5.34 KB |
| low | pixel_deform | typical | 32 / 32 | 3.87% | 3.87% | +1.94 pp | 60 | 0.90 KB | +19.00 KB |
| low | pixel_deform | saturated | 256 / 256 | 17.33% | 17.33% | +15.40 pp | 60 | 0.90 KB | +19.00 KB |
| low | palette_fx | typical | 32 / 32 | 2.88% | 2.88% | +0.95 pp | 60 | 1.77 KB | +19.00 KB |
| low | palette_fx | saturated | 1024 / 1024 | 32.19% | 32.19% | +30.26 pp | 60 | 1.77 KB | +19.00 KB |
| low | pseudo3d | typical | 1 / 8 (+24 stars) | 6.87% | 6.87% | +4.94 pp | 60 | 5.66 KB | +4.85 KB |
| low | pseudo3d | saturated | 8 / 8 (+24 stars) | 7.66% | 7.66% | +5.73 pp | 60 | 6.81 KB | -17.73 KB |
| low | flames | typical | 8 / 48 | 2.13% | 2.13% | +0.20 pp | 60 | 11.31 KB | -8.16 KB |
| low | flames | saturated | 48 / 48 | 3.09% | 3.09% | +1.15 pp | 60 | 11.31 KB | -8.19 KB |
| low | electricity | typical | 18 / 64 | 2.36% | 2.36% | +0.43 pp | 60 | 10.83 KB | -7.70 KB |
| low | electricity | saturated | 64 / 64 | 3.56% | 3.56% | +1.62 pp | 60 | 11.58 KB | -8.27 KB |
| medium | baseline | baseline | 0 / 0 | 1.93% | 1.93% | +0.00 pp | 60 | 0.06 KB | +19.00 KB |
| medium | particles | typical | 12 / 160 | 2.23% | 2.23% | +0.29 pp | 60 | -3.78 KB | +19.00 KB |
| medium | particles | saturated | 160 / 160 | 5.77% | 5.77% | +3.84 pp | 60 | -3.78 KB | +19.00 KB |
| medium | screen_fx | typical | 1 / 8 | 2.49% | 2.49% | +0.56 pp | 60 | 1.23 KB | +19.00 KB |
| medium | screen_fx | saturated | 8 / 8 | 2.64% | 2.64% | +0.70 pp | 60 | 2.88 KB | -6.38 KB |
| medium | pixel_deform | typical | 96 / 96 | 7.71% | 7.71% | +5.78 pp | 60 | 0.90 KB | +19.00 KB |
| medium | pixel_deform | saturated | 768 / 768 | 48.09% | 48.09% | +46.16 pp | 60 | 0.90 KB | +19.00 KB |
| medium | palette_fx | typical | 32 / 32 | 2.88% | 2.88% | +0.95 pp | 60 | 1.73 KB | +19.00 KB |
| medium | palette_fx | saturated | 1024 / 1024 | 32.19% | 32.19% | +30.26 pp | 60 | 1.73 KB | +19.00 KB |
| medium | pseudo3d | typical | 1 / 16 (+48 stars) | 7.38% | 7.38% | +5.45 pp | 60 | 9.73 KB | -20.93 KB |
| medium | pseudo3d | saturated | 16 / 16 (+48 stars) | 9.75% | 9.75% | +7.82 pp | 60 | 12.19 KB | -21.67 KB |
| medium | flames | typical | 8 / 96 | 2.13% | 2.13% | +0.20 pp | 60 | 21.31 KB | -11.19 KB |
| medium | flames | saturated | 96 / 96 | 4.22% | 4.22% | +2.28 pp | 60 | 21.31 KB | -11.19 KB |
| medium | electricity | typical | 15 / 128 | 2.25% | 2.25% | +0.31 pp | 60 | 17.70 KB | -10.80 KB |
| medium | electricity | saturated | 128 / 128 | 4.82% | 4.82% | +2.89 pp | 60 | 18.83 KB | -10.52 KB |
| high | baseline | baseline | 0 / 0 | 1.93% | 1.93% | +0.00 pp | 60 | 0.06 KB | +19.00 KB |
| high | particles | typical | 12 / 320 | 2.23% | 2.23% | +0.29 pp | 60 | -3.78 KB | +19.00 KB |
| high | particles | saturated | 320 / 320 | 9.61% | 9.61% | +7.67 pp | 60 | -3.78 KB | +19.00 KB |
| high | screen_fx | typical | 1 / 8 | 2.49% | 2.49% | +0.56 pp | 60 | 1.23 KB | +19.00 KB |
| high | screen_fx | saturated | 8 / 8 | 2.64% | 2.64% | +0.70 pp | 60 | 2.88 KB | +19.00 KB |
| high | pixel_deform | typical | 240 / 240 | 16.37% | 16.37% | +14.44 pp | 60 | 0.90 KB | +19.00 KB |
| high | pixel_deform | saturated | 1920 / 1920 | 117.30% | 117.30% | +115.37 pp | 30 | 0.90 KB | +19.00 KB |
| high | palette_fx | typical | 32 / 32 | 2.88% | 2.88% | +0.95 pp | 60 | 1.73 KB | +19.00 KB |
| high | palette_fx | saturated | 1024 / 1024 | 32.19% | 32.19% | +30.26 pp | 60 | 1.73 KB | +19.00 KB |
| high | pseudo3d | typical | 1 / 32 (+80 stars) | 8.07% | 8.07% | +6.14 pp | 60 | 15.85 KB | +6.11 KB |
| high | pseudo3d | saturated | 32 / 32 (+80 stars) | 15.77% | 15.77% | +13.84 pp | 60 | 20.94 KB | +5.69 KB |
| high | flames | typical | 8 / 160 | 2.13% | 2.13% | +0.20 pp | 60 | -3.92 KB | +19.00 KB |
| high | flames | saturated | 160 / 160 | 5.76% | 5.76% | +3.83 pp | 60 | -3.92 KB | +19.00 KB |
| high | electricity | typical | 21 / 224 | 2.35% | 2.35% | +0.42 pp | 60 | -3.88 KB | +19.00 KB |
| high | electricity | saturated | 224 / 224 | 6.76% | 6.76% | +4.83 pp | 60 | -2.50 KB | +19.00 KB |

`active / limit` reports active pool items and capacity. For coordinate deformation and palette mapping it reports helper calls used as a fixed synthetic workload, not internal allocations. Pseudo-3D also reports its star count. Screen effects use an eight-wave capacity on all quality profiles because that module has no profile-specific capacity.

Raw measurements: [`picotron-effects.csv`](picotron-effects.csv). Reproduce them with [`benchmarks/picotron/run.ps1`](../picotron/run.ps1).
