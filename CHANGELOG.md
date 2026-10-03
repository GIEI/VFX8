# Changelog

All notable changes to VFX8 are documented here. This project follows Semantic Versioning.

## [0.1.0] - Unreleased

### Added

- Seven composable effects: particles, screen shake and distortion, pixel deformation, palette mapping, pseudo-3D rendering, flames, and electric arcs.
- Engine-specific implementations for PICO-8, Picotron, LÖVE, and TIC-80.
- `low`, `medium`, and `high` quality profiles with bounded pools and explicit work limits where applicable.
- Per-effect English integration and API documentation, four demo environments, and minimal integration games.
- Portable Python contracts, fantasy-console include/build checks, native-runtime smoke harnesses, and benchmark procedures.
- Five-run all-effect performance reports for Picotron and LÖVE; historical PICO-8 measurements and showcase token budgets.

### Verification

- The user confirms native visual checks are complete on all four engines.
- The user confirms performance measurements are complete on PICO-8 and TIC-80; detailed raw values have not yet been added to this repository.
- The portable regression gate passes 34 tests with one sandbox-dependent test skipped.

### Known release work

- Transcribe the user-run PICO-8 and TIC-80 measurements into reproducible reports.
- Record PICO-8 per-module token costs and the additional platform-specific resource measurements listed in `docs/release-checklist.md`.
- Add representative screenshots, release-machine metadata, and publish the tagged release after final review.
