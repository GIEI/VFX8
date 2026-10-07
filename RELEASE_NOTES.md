# VFX8 0.1.0-rc.1 — First Public Release Candidate

VFX8 is a modular visual effects library for PICO-8, Picotron, LÖVE, and TIC-80. Each effect can be integrated into an existing game's callbacks without replacing its main loop.

## Included effects

- Adaptive particles: explosions, sparks, trails, smoke, and landing dust, with point, line, and area emission.
- Screen feedback: trauma and directional shake, flash, and engine-appropriate shockwave rendering.
- Pixel deformation: coordinate waves, squash and stretch helpers, and ordered dissolve masks.
- Palette effects: color cycling, filters, glow pulses, and negative flashes.
- Pseudo-3D: Mode 7 ground, starfields, and depth-projected objects.
- Flames: campfire plumes and directional flamethrower jets.
- Electricity: irregular lightning arcs with optional branches.

## Compatibility and verification

All seven effects have engine-specific implementations, examples, and dedicated documentation. The [integration game](examples/integration_game/README.md) keeps its own input, update, and draw callbacks. Each effect guide contains a PICO-8 screenshot generated from the corresponding native module.

| Engine | Version exercised | Verification in this candidate |
| --- | --- | --- |
| PICO-8 | Version not recorded | Native profile contracts and screenshot carts pass. Previous user visual checks cover the effects; new optional parameters still need a complete manual pass. |
| Picotron | 0.3.0d | Native profile smoke passes for all seven modules and covered variants; previous user visual checks cover the integration game. |
| LÖVE | 11.5.0 | Portable contracts and staging pass. Native contracts could not initialize the user filesystem here; previous user visual checks cover the prior implementation. |
| TIC-80 | 1.2.0 | Include build and portable contracts pass; no native executable is available here. Previous user visual checks cover the prior implementation. |

The portable suite passes 44 tests with one environment-dependent LÖVE test skipped. PICO-8 native contracts and Picotron native smoke pass. TIC-80 include generation succeeds. Detailed user-run PICO-8/TIC-80 performance numbers have not been recorded in the repository. Picotron and LÖVE reports are available under `benchmarks/results/`; they predate the newly added optional effect parameters and should be treated as baseline measurements, not measurements of every new setting.

This is a pre-release because resource evidence and full parameter retesting remain incomplete. See `docs/release-checklist.md` and `benchmarks/performance-checklist.md` for the remaining work.

Run portable checks from the repository root with:

```powershell
./tests/run-regression.ps1 -PortableOnly
```

See `README.md`, `docs/integration.md`, and `examples/README.md` for setup and usage. See `docs/release-checklist.md` for outstanding measurements and release evidence.
