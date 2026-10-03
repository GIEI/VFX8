# Public Release Checklist

This checklist summarizes the remaining work required for a dependable first public release. The source contains all seven effect modules for PICO-8, Picotron, LÖVE, and TIC-80; implementation coverage alone is not a release sign-off.

## Release blockers

- [x] **Fit the PICO-8 showcase within the 8,192-token limit.** The showcase is split into three native-boot-tested carts. Exact code token counts and headroom are recorded in [`benchmarks/results/pico8-showcase-token-budget.md`](../benchmarks/results/pico8-showcase-token-budget.md).
- [x] **Finish native visual checks across the supported engines and profiles.** The user confirms visual checks are complete on PICO-8, Picotron, LÖVE, and TIC-80. Representative screenshots and run-by-run notes are tracked separately as release evidence in [`docs/native-visual-checklist.md`](native-visual-checklist.md).
- [x] **Add a repeatable regression path for native runtimes and portable build gaps.** [`tests/run-regression.ps1`](../tests/run-regression.ps1) runs the Python suite, TIC-80 include build, LÖVE staging, and all supported native checks; [`tests/README.md`](../tests/README.md) documents skips and runtime requirements. PICO-8 core/advanced contracts and Picotron smoke exercise invalid inputs as well as successful drawing paths at low/medium/high; the LÖVE 11.5 native API harness now passes. GitHub Actions runs the portable gate on pushes and pull requests. TIC-80 native automation still requires an installed runtime and is reported as skipped when none is available.
- [ ] **Complete performance and resource measurements.** Picotron and LÖVE have five-run reports for all seven effects, three profiles, and baseline/typical/saturated cases; LÖVE samples saturated cases for 600 frames and records update/draw time, heap deltas, texture memory, and shader availability. The user confirms PICO-8 and TIC-80 measurements are complete, but detailed values have not been added to the repository. Picotron full program memory, LÖVE additional resolutions/GPU time, PICO-8 standalone module token costs, and release-machine confirmation remain open. See [`benchmarks/performance-checklist.md`](../benchmarks/performance-checklist.md).
- [x] **Verify the public integration contract end to end.** The user confirmed on 2026-10-03 that the minimal integration game works on PICO-8, Picotron, LÖVE, and TIC-80 with its own input, update, and draw callbacks. The user also confirms visual checks are complete on all four engines; representative captures remain optional launch evidence.
- [ ] **Resolve issues found by those checks and update the effect pages.** Record tested engine versions, supported behavior, quality limits, measured costs, and known visual differences. Do not describe an effect as measured or visually verified until the result is recorded.

## Publication preparation

- [x] **Prepare release metadata:** `CHANGELOG.md` and `RELEASE_NOTES.md` describe the 0.1.0 candidate and its known limitations. The final release date and Git tag are deferred until release approval.
- [x] **Track the MIT license in the release commit.** `LICENSE` is already tracked in the repository.
- [x] **Add a reproducible CI gate** for the portable Python contracts, include/build steps, and demo staging. Native runtime requirements and checks that remain manual are documented.
- [x] **Prepare a clean download package:** `python tools/package_release.py --version 0.1.0` creates a source archive containing the library, docs, examples, tests, benchmarks, tools, changelog, release notes, and MIT license while excluding generated build/runtime data.
- [ ] **Review the repository diff and leave a clean, tested release commit.** The current checkout contains uncommitted changes and untracked files, so audit which ones belong to the release before tagging.
- [ ] **Confirm the GitHub repository's public visibility and publish the tagged release** with source archive, compatibility matrix, supported engine versions, and links to demos. The `origin` remote is configured; the repository's current public visibility has not been verified here.

## Already in place

- [x] Seven effect modules have engine-specific implementations for all four targets.
- [x] A dedicated English effect page, integration guidance, and a demo adapter exist for each effect/engine family.
- [x] The portable Python suite passes 34 tests; one sandbox-dependent test skips. The latest full regression run passed PICO-8 core/advanced contracts and Picotron native smoke. LÖVE native contracts were skipped because its runtime could not initialize the user filesystem; TIC-80 native launch was skipped because no executable is installed.
- [x] Picotron headless smoke exercises all seven modules, covered variants, all quality profiles, and textured/fallback pseudo-3D paths in an isolated home; the user confirms interactive visual checks are complete.
- [x] The user confirms the PICO-8, Picotron, LÖVE, and TIC-80 visual checks are complete; TIC-80 1.2.0 showcase functionality was previously confirmed.
- [x] The repository already contains an MIT license file and a configured GitHub `origin` remote; both still need to be included or checked as listed above.

## Optional launch polish

- [ ] Add representative screenshots or short captures for the effect pages and release notes.
- [ ] Provide ready-to-open sample carts or a staging script for each fantasy console, especially a Picotron package that copies the `vfx8/` modules automatically.
