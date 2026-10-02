# Public Release Checklist

This checklist summarizes the remaining work required for a dependable first public release. The source contains all seven effect modules for PICO-8, Picotron, LÖVE, and TIC-80; implementation coverage alone is not a release sign-off.

## Release blockers

- [x] **Fit the PICO-8 showcase within the 8,192-token limit.** The showcase is split into three native-boot-tested carts. Exact code token counts and headroom are recorded in [`benchmarks/results/pico8-showcase-token-budget.md`](../benchmarks/results/pico8-showcase-token-budget.md).
- [ ] **Finish native visual checks across the supported engines and profiles.** The automated Picotron smoke now exercises all seven effects, covered variants, and low/medium/high on Picotron 0.3.0d. PICO-8 profile contracts also pass at all three settings. Interactive screenshots and controls remain to be reviewed in the native windows; LÖVE 11.5.0 cannot initialize its filesystem in this environment and its MCP endpoint is offline. Follow [`docs/native-visual-checklist.md`](native-visual-checklist.md) and record captures before sign-off.
- [x] **Add a repeatable regression path for native runtimes and portable build gaps.** [`tests/run-regression.ps1`](../tests/run-regression.ps1) runs the Python suite, TIC-80 include build, LÖVE staging, and all supported native checks; [`tests/README.md`](../tests/README.md) documents skips and runtime requirements. PICO-8 core/advanced contracts and Picotron smoke now exercise invalid inputs as well as successful drawing paths at low/medium/high. GitHub Actions runs the portable gate on pushes and pull requests. Native LÖVE remains blocked by filesystem initialization on this workstation, and TIC-80 native automation requires an installed runtime; both are reported explicitly by the runner.
- [ ] **Complete performance and resource measurements.** The full five-run Picotron report covers all seven effects, three profiles, baseline/typical/saturated cases, CPU/FPS indicators, Lua heap deltas, and pool/workload counts; the runnable benchmark is [`benchmarks/picotron/run.ps1`](../benchmarks/picotron/run.ps1). PICO-8 adds 600-frame stress carts for every effect/profile, but the local runtime bridge does not expose their long-run measurements. LÖVE still needs all-module coverage after native startup is restored, TIC-80 needs native measurements, and results need release-machine confirmation. See [`benchmarks/performance-checklist.md`](../benchmarks/performance-checklist.md).
- [ ] **Verify the public integration contract end to end.** For each engine, start from a small game/cart with its own callbacks, include one VFX8 module, trigger it, and confirm update/draw order and input remain owned by the game. Check state restoration for camera, clipping, palette, color, and render targets, including combinations where state is shared.
- [ ] **Resolve issues found by those checks and update the effect pages.** Record tested engine versions, supported behavior, quality limits, measured costs, and known visual differences. Do not describe an effect as measured or visually verified until the result is recorded.

## Publication preparation

- [ ] **Add release metadata:** choose the first semantic version, create a `CHANGELOG.md`, write release notes, and create a matching Git tag. This checkout has no release tag or changelog yet.
- [ ] **Track the MIT license in the release commit.** `LICENSE` is present in the working directory but is currently untracked.
- [x] **Add a reproducible CI gate** for the portable Python contracts, include/build steps, and demo staging. Native runtime requirements and checks that remain manual are documented.
- [ ] **Prepare a clean download package:** retain `src/`, per-effect docs, install/integration guidance, examples, tests, and the MIT license; exclude temporary files and generated local runtime data unless they are intentional release assets.
- [ ] **Review the repository diff and leave a clean, tested release commit.** The current checkout contains uncommitted changes and untracked files, so audit which ones belong to the release before tagging.
- [ ] **Confirm the GitHub repository's public visibility and publish the tagged release** with source archive, compatibility matrix, supported engine versions, and links to demos. The `origin` remote is configured; the repository's current public visibility has not been verified here.

## Already in place

- [x] Seven effect modules have engine-specific implementations for all four targets.
- [x] A dedicated English effect page, integration guidance, and a demo adapter exist for each effect/engine family.
- [x] The portable Python suite passes 29 checks; one LÖVE runtime check is skipped because its user filesystem cannot initialize in this environment.
- [x] Picotron headless smoke exercises all seven modules, covered variants, all quality profiles, and textured/fallback pseudo-3D paths in an isolated home; interactive composition remains to be reviewed.
- [x] The TIC-80 1.2.0 showcase has been confirmed working by the user.
- [x] The repository already contains an MIT license file and a configured GitHub `origin` remote; both still need to be included or checked as listed above.

## Optional launch polish

- [ ] Add representative screenshots or short captures for the effect pages and release notes.
- [ ] Provide ready-to-open sample carts or a staging script for each fantasy console, especially a Picotron package that copies the `vfx8/` modules automatically.
