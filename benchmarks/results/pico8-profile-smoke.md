# PICO-8 profile smoke measurements

- Engine: PICO-8 (`stat(1)` VM CPU fraction)
- Runtime version: unavailable from the runtime bridge
- Host CPU / device: unavailable from the runtime bridge
- Run mode: headless `pico8 -x` through the runtime bridge
- Cartridge: `tests/pico8/profile_contract.p8`
- Screen viewport: 128×128; pseudo-3D logical viewport: 128×96
- Repetitions: 5 clean launches
- Samples: 10 steady draw frames per scenario per launch; 2 initial frames discarded; 50 measured frames per table cell
- Statistic: median of the five per-launch mean CPU fractions; range shows the smallest per-launch minimum through the largest per-launch maximum
- Vsync / frame cap: not reported by the runtime bridge

`stat(1)` reports PICO-8 CPU load as a fraction of its VM budget ([PICO-8 manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#CPU)). Values below are percentages. They include the benchmark cart's small status label and the scene/effect draw calls. The baseline draws the same simple field used by the screen, deformation, and palette slots. The particle slot draws the field plus one explosion. The pseudo-3D slot replaces the field with its own Mode 7 road, stars, and one projected object, so its baseline comparison is not scene-equivalent.

| Profile | Scenario | Median run mean CPU | Observed sample range |
| --- | --- | ---: | ---: |
| low | Baseline field | 4.28% | 4.28–4.28% |
| low | Particles, one explosion | 5.46% | 5.45–5.47% |
| low | Screen shake, flash, one ring | 4.76% | 4.54–5.99% |
| low | Pixel deformation helpers on field | 4.47% | 4.47–4.47% |
| low | Palette mapping on field | 4.48% | 4.47–4.48% |
| low | Mode 7, stars, one object | 20.22% | 20.22–20.22% |
| medium | Baseline field | 4.35% | 4.35–4.35% |
| medium | Particles, one explosion | 6.22% | 6.20–6.24% |
| medium | Screen shake, flash, one ring | 4.84% | 4.62–6.07% |
| medium | Pixel deformation helpers on field | 4.55% | 4.55–4.55% |
| medium | Palette mapping on field | 4.56% | 4.55–4.56% |
| medium | Mode 7, stars, one object | 25.21% | 25.21–25.21% |
| high | Baseline field | 4.30% | 4.30–4.30% |
| high | Particles, one explosion | 6.85% | 6.82–6.88% |
| high | Screen shake, flash, one ring | 4.79% | 4.57–6.02% |
| high | Pixel deformation helpers on field | 4.50% | 4.50–4.50% |
| high | Palette mapping on field | 4.51% | 4.50–4.51% |
| high | Mode 7, stars, one object | 30.53% | 30.53–30.53% |

## Pseudo-3D saturated scene

Each quality profile was launched five times using the matching `tests/pico8/pseudo3d_stress_<profile>.p8` cart. Each run warmed up for three frames, then measured 600 frames with the profile's maximum star count and a full projected-object pool. Objects and stars remain at stable depths, and the camera speed is zero, so every measured frame exercises the fully populated draw path. The viewport is 128×96 with the default Mode 7 coverage for that profile. Each cell is the median of five run means; the range spans per-run frame-sample minima through maxima.

| Profile | Stars | Projected objects | Median run mean CPU | Observed sample range |
| --- | ---: | ---: | ---: | ---: |
| low | 8 | 3 | 20.84% | 20.79–20.85% |
| medium | 14 | 6 | 26.50% | 26.45–26.50% |
| high | 22 | 10 | 33.04% | 32.99–33.04% |

## Method and limitations

The cart advances through a baseline and all five effect adapters at each quality. It triggers one normal event per effect, updates once per frame, and renders for 13 frames per scenario. The first two rendered frames are discarded; the following 10 `stat(1)` readings are summarized and emitted with `printh()`. Five headless launches produced 50 readings per scenario.

The effect-slot table contains short typical-load observations. The separate pseudo-3D table contains 600-frame saturated draw-path measurements at each profile's star and object limits. The stress cart updates the scene at a zero time step, so it measures rendering with full pools rather than motion/update cost. Particle and shockwave pools in the effect-slot table are not filled. The deformation slot exercises its coordinate helpers while drawing the unchanged field; raster integration remains game-owned. Compare pseudo-3D absolute CPU use with the 100% VM limit rather than subtracting the simple-field baseline. Low/medium Mode 7 profiles sample a centered 55%/75% viewport width and fill the rest with ground color; high retains full width. Runtime version, host details, token count, and percentile values are unavailable. These measurements are not performance guarantees for different maps, resolutions, or runtimes.
