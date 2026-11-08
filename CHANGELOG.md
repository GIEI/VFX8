# Changelog

All notable changes to VFX8 are documented here. This project follows Semantic Versioning.

## [1.1.0] - 2026-11-08

### Added

- Bounded rain and snow effects for PICO-8, Picotron, LÖVE, and TIC-80, with adjustable intensity and weather-specific controls.
- Snow collection on registered horizontal surfaces with short-lived deposits, plus standalone demos and external-game integration examples.
- English API guides and portable/native runtime contracts for both weather effects.
- Full integration-game catalogs and demo selectors now expose all nine effect modules on every target, including separate PICO-8 weather cartridges to stay within its token budget.
- Corrected the PICO-8 rain angle convention so oblique drops move in the intended direction; added a runtime motion assertion and removed the oversized gray backing from the weather integration player.

### Verification

- All 50 portable tests pass, including LÖVE runtime contracts for all nine modules and source/build checks for both TIC-80 demos.
- PICO-8 core, advanced, and weather native profile contracts pass; weather showcase and integration cartridges boot without errors. TIC-80 demo and integration include builds and LÖVE demo staging pass.
- Rain and snow still need native visual review and performance measurements on all engines. Picotron and TIC-80 native weather runs were unavailable in the release environment; existing benchmark reports cover the original seven modules.

## [0.1.0-rc.1] - 2026-10-07

### Added

- Seven composable effects: particles, screen shake and distortion, pixel deformation, palette mapping, pseudo-3D rendering, flames, and electric arcs.
- Engine-specific implementations for PICO-8, Picotron, LÖVE, and TIC-80.
- `low`, `medium`, and `high` quality profiles with bounded pools and explicit work limits where applicable.
- Per-effect English integration and API documentation, four demo environments, and minimal integration games.
- Portable Python contracts, fantasy-console include/build checks, native-runtime smoke harnesses, and benchmark procedures.
- Five-run all-effect performance reports for Picotron and LÖVE; historical PICO-8 measurements and showcase token budgets.

### Verification

- The portable regression gate passes 44 tests with one LÖVE runtime test skipped because the runtime could not initialize its user filesystem.
- PICO-8 profile contracts and screenshot captures pass; Picotron profile smoke passes across all seven effects and quality profiles.
- TIC-80 include generation and demo staging pass; no TIC-80 executable is installed for native automation in this environment.
- The user confirms visual checks were completed on all four engines before the new optional parameters were added. New parameter behavior has source/API contract coverage; complete native parameter retesting remains follow-up work.
- Seven PICO-8 captures are included in the effect pages under `docs/effects/images/`.

### Known limitations and follow-up

- Detailed user-run PICO-8 and TIC-80 performance measurements have not yet been transcribed into reports.
- PICO-8 standalone per-module token costs, Picotron full-program memory, LÖVE additional-resolution/GPU measurements, and release-machine metadata remain open; see `docs/release-checklist.md`.
- The latest LÖVE runtime contract could not run in this environment because LÖVE failed to initialize its user filesystem.
- TIC-80 native launch automation was unavailable because no executable is installed or on `PATH`.
