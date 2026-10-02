# Public Release Checklist

This checklist summarizes the remaining work required for a dependable first public release. The source contains all seven effect modules for PICO-8, Picotron, LÖVE, and TIC-80; implementation coverage alone is not a release sign-off.

## Release blockers

- [ ] **Fit the PICO-8 showcase within the 8,192-token limit.** The current all-effects cart exceeds the limit. Split it into focused carts or trim the showcase, then record token counts for the showcase and standalone effect carts.
- [ ] **Finish native visual checks across the supported engines and profiles.** Exercise low, medium, and high settings, every effect variant, input controls, draw order, and effect combinations. Picotron's isolated headless smoke passes all seven modules and both pseudo-3D render paths, but the interactive showcase still needs visual review. The TIC-80 1.2.0 showcase is user-confirmed working; capture repeatable per-effect/profile results before release sign-off. LÖVE's full staged demo and shader visuals still need a recorded end-to-end review.
- [ ] **Add repeatable native regression coverage for the remaining gaps.** The Python suite passes 28 checks with one LÖVE runtime check skipped because this environment cannot initialize LÖVE's user filesystem. Picotron has a headless runtime smoke; TIC-80 currently has include-build and source contracts, with the user-confirmed showcase as manual evidence. Make the release test path reproducible outside this workstation and cover failures as well as clean startup.
- [ ] **Complete performance and resource measurements.** Run baseline, typical, and saturated workloads at each quality profile on every engine. Record runtime version, hardware, CPU/frame time, memory where available, and peak pool counts. Record PICO-8 token/code cost. Current data is strongest for PICO-8 typical effects, PICO-8 pseudo-3D saturation, and repeated LÖVE particle scenarios; most other saturated effect costs and all Picotron/TIC-80 timing/code-use figures are missing.
- [ ] **Verify the public integration contract end to end.** For each engine, start from a small game/cart with its own callbacks, include one VFX8 module, trigger it, and confirm update/draw order and input remain owned by the game. Check state restoration for camera, clipping, palette, color, and render targets, including combinations where state is shared.
- [ ] **Resolve issues found by those checks and update the effect pages.** Record tested engine versions, supported behavior, quality limits, measured costs, and known visual differences. Do not describe an effect as measured or visually verified until the result is recorded.

## Publication preparation

- [ ] **Add release metadata:** choose the first semantic version, create a `CHANGELOG.md`, write release notes, and create a matching Git tag. This checkout has no release tag or changelog yet.
- [ ] **Track the MIT license in the release commit.** `LICENSE` is present in the working directory but is currently untracked.
- [ ] **Add a reproducible CI gate** for the portable Python contracts, include/build steps, and any engine checks that can run without paid or interactive desktop software. Document which native checks remain manual.
- [ ] **Prepare a clean download package:** retain `src/`, per-effect docs, install/integration guidance, examples, tests, and the MIT license; exclude temporary files and generated local runtime data unless they are intentional release assets.
- [ ] **Review the repository diff and leave a clean, tested release commit.** The current checkout contains uncommitted changes and untracked files, so audit which ones belong to the release before tagging.
- [ ] **Confirm the GitHub repository's public visibility and publish the tagged release** with source archive, compatibility matrix, supported engine versions, and links to demos. The `origin` remote is configured; the repository's current public visibility has not been verified here.

## Already in place

- [x] Seven effect modules have engine-specific implementations for all four targets.
- [x] A dedicated English effect page, integration guidance, and a demo adapter exist for each effect/engine family.
- [x] The portable Python suite passes 28 checks; one LÖVE runtime check is skipped by the current sandbox limitation.
- [x] Picotron headless smoke exercises module loading, updates, draw calls, and textured/fallback pseudo-3D paths in an isolated home.
- [x] The TIC-80 1.2.0 showcase has been confirmed working by the user.
- [x] The repository already contains an MIT license file and a configured GitHub `origin` remote; both still need to be included or checked as listed above.

## Optional launch polish

- [ ] Add representative screenshots or short captures for the effect pages and release notes.
- [ ] Provide ready-to-open sample carts or a staging script for each fantasy console, especially a Picotron package that copies the `vfx8/` modules automatically.
