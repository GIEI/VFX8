# VFX8 1.1.0 Release Checklist

This checklist records what is included in release 1.1.0 and separates verified behavior from work that still needs additional runtime access or measurements.

## Included and tested

- [x] Nine engine-specific modules, with a separate English guide for every effect.
- [x] Demo adapters for PICO-8, Picotron, LÖVE, and TIC-80; integration-game examples retain their own callbacks and input.
- [x] Rain and snow modules, demos, and external-project integration examples for all four engines.
- [x] PICO-8 oblique-rain direction fix and a native contract that checks horizontal and vertical movement.
- [x] Portable regression suite: 50 tests pass.
- [x] LÖVE 11.5.0 native API/runtime contracts pass for all nine modules, including rain and snow.
- [x] PICO-8 core, advanced, and weather profile contracts pass through the native bridge; weather demo and integration carts boot.
- [x] TIC-80 demo and integration include builds pass; LÖVE demo staging passes.
- [x] MIT license, reproducible source packager, compatibility matrix, release notes, and changelog are included.

## Known verification and measurement gaps

- [ ] Visually review rain and snow in native demos on PICO-8, Picotron, LÖVE, and TIC-80, including the oblique direction and snow settling.
- [ ] Run the expanded Picotron native smoke harness for rain and snow at low, medium, and high quality. The smoke test is available at [`tests/picotron/run-smoke.ps1`](../tests/picotron/run-smoke.ps1).
- [ ] Run the rain and snow demos in native TIC-80. The current automated check expands the include files but does not launch TIC-80.
- [ ] Record repeatable weather performance measurements for each engine and profile. Existing Picotron and LÖVE reports cover only the original seven modules.
- [ ] Add raw user-measured PICO-8 and TIC-80 timing/resource values. Prior user confirmations cover the original seven effects but did not include data for this report.
- [ ] Measure PICO-8 per-module token costs, Picotron total program memory, and LÖVE shockwave costs at additional resolutions where supported.
- [ ] Record the tested PICO-8 version, complete per-profile visual evidence, and release-machine details.

These gaps are disclosed rather than treated as completed evidence. See [`native-visual-checklist.md`](native-visual-checklist.md) and [`../benchmarks/performance-checklist.md`](../benchmarks/performance-checklist.md) for the corresponding run procedures.

## Publication

- [x] Version metadata and the source archive target are set to `1.1.0`.
- [x] The source package includes source, docs, examples, tests, benchmark reports, tools, release notes, changelog, and MIT license; generated builds and local runtime data are excluded.
- [x] Commit the verified release contents, tag `v1.1.0`, and publish the GitHub release. GitHub provides source ZIP and tar archives from the tag.

The custom source ZIP was generated locally but was not uploaded as a separate release asset. The published source archives are available from the [VFX8 1.1.0 release](https://github.com/GIEI/VFX8/releases/tag/v1.1.0). The previous `v0.1.0-rc.1` release remains available in the repository's [GitHub releases](https://github.com/GIEI/VFX8/releases).
