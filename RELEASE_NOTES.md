# VFX8 0.1.0 — Release Candidate Notes

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

All seven effects have engine-specific implementations, examples, and dedicated documentation. The user confirms native visual checks are complete on all four engines and native performance measurements are complete on PICO-8 and TIC-80. Detailed PICO-8/TIC-80 measurement values are not included in this candidate; Picotron and LÖVE all-effect benchmark reports are included under `benchmarks/results/`.

Run portable checks from the repository root with:

```powershell
./tests/run-regression.ps1 -PortableOnly
```

See `README.md`, `docs/integration.md`, and `examples/README.md` for setup and usage. See `docs/release-checklist.md` for outstanding measurements and release evidence.
