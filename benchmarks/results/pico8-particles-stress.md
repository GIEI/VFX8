# PICO-8 particle saturation measurements

- Engine: PICO-8 (`stat(1)` VM CPU fraction)
- Runtime version: unavailable from the runtime bridge
- Host CPU / device: unavailable from the runtime bridge
- Run mode: headless `pico8 -x` through the runtime bridge
- Workload: full particle pool, one update and draw per frame, 600 sampled frames after 3 warm-up frames
- Repetitions: one baseline and one optimized run per profile
- Vsync / frame cap: not reported by the runtime bridge

Each profile uses the same stress cart and particle counts for the baseline and optimized runs. The baseline loads `src/pico8/particles.lua` from source revision `482f1b15ed8f281ad23f93b6747c34418eff1e0c`; the optimized version caches structure-of-arrays references and active count as local variables inside update/draw. The pool stays full for the sample period with a long lifetime, exercising particle movement and rendering without repeated emissions. Values include the stress cart's status label and are not a frame-time guarantee.

| Profile | Capacity | Baseline mean CPU | Optimized mean CPU | Change | Optimized sample range |
| --- | ---: | ---: | ---: | ---: | ---: |
| low | 24 | 5.06% | 4.37% | -13.6% | 4.34–4.40% |
| medium | 48 | 7.82% | 6.40% | -18.2% | 6.38–6.45% |
| high | 72 | 10.44% | 8.30% | -20.5% | 8.27–8.37% |

## Reproduction

Run `tests/pico8/particle_stress_<profile>.p8` with the PICO-8 runtime bridge for the optimized measurement. Each cart emits a `VFX8_PARTICLE_STRESS` record after 600 frames. To reproduce the baseline, provide `git show 482f1b15ed8f281ad23f93b6747c34418eff1e0c:src/pico8/particles.lua` to the same carts in place of the current module; keep the stress helper and profile parameters unchanged.

These are single-run samples. Repeat each run at least five times before using the percentage changes as representative performance claims. Showcase cart token budgets are now recorded separately; standalone per-module token counts, memory use, and measurements on Picotron and TIC-80 remain unavailable. LÖVE particle measurements are recorded in [the repeated benchmark report](love2d-particles.md).
