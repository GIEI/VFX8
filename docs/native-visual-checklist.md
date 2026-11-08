# Native Visual Verification Checklist

Automated contracts confirm APIs and drawing paths; they do not replace visual review in each engine. The user has confirmed visual checks for the original seven modules on all four targets. Rain and snow were added later and are tracked separately below.

## Verification status

| Engine | Runtime known | Automated checks | Visual review |
| --- | --- | --- | --- |
| PICO-8 | Version not exposed by the bridge | Core, advanced, and weather profile contracts pass. Weather demo and integration carts boot; the weather contract checks oblique movement. | Original seven modules were user-confirmed. Rain/snow still need a visual pass. |
| Picotron | 0.3.0d, build 260527-061316 | The nine-module isolated smoke harness covers rain angle and snow surfaces at all three profiles; a native run of this harness remains outstanding. | Original seven modules were user-confirmed. Rain/snow still need a visual pass. |
| LÖVE | 11.5.0 | Runtime API contracts pass for all nine modules, including rain and snow. Demo staging succeeds. | Original seven modules were user-confirmed. Rain/snow still need a visual pass; no weather screenshots are recorded. |
| TIC-80 | 1.2.0 | Demo and integration include builds pass. The current environment does not launch native TIC-80. | Original seven modules were user-confirmed. Rain/snow still need native visual review. |

## Previously confirmed integration behavior

On 2026-10-03, the user confirmed the minimal game, with its own input, update, and draw callbacks, works on PICO-8, Picotron, LÖVE, and TIC-80. The original seven effects were visually checked on all four engines. Run-by-run captures and per-profile notes were not supplied.

The user also confirmed completing visual checks and performance measurements for the original effects in PICO-8 and TIC-80, plus visual checks in Picotron and LÖVE. Those confirmations do not cover the later rain and snow modules.

## Manual review checklist

### Original seven modules

- [x] PICO-8: core effects, pseudo-3D, flames, and electricity; controls, profile changes, and scene coverage. User-confirmed.
- [x] Picotron: all original effect variants at low/medium/high; clipping and graphics-state restoration. User-confirmed.
- [x] LÖVE: all original effect variants at low/medium/high; shockwave, Mode 7, resizing, and graphics-state restoration. User-confirmed.
- [x] TIC-80: all original effect variants at low/medium/high; clipping, controls, and state restoration. User-confirmed.

### Rain and snow — pending visual review

- [ ] PICO-8: cycle vertical and oblique rain at light/heavy/storm density; confirm the slant direction, screen-edge wrapping, snow sway, and snow deposits on registered surfaces.
- [ ] Picotron: repeat the same rain/snow variants and run `tests/picotron/run-smoke.ps1` to exercise all quality profiles.
- [ ] LÖVE: cycle rain angles and density, resize the window, and confirm flakes/deposits restore graphics color state.
- [ ] TIC-80: import the expanded demo and integration source; cycle rain and snow variants and inspect bounds and draw order.

## Capture template

For a reproducible result, record engine/version, cart or staged directory, profile, effect/variant, controls, draw-order and state-restoration result, and screenshot path.

| Engine / version | Quality | Effect and variant | Controls / state result | Capture path |
| --- | --- | --- | --- | --- |
|  | low |  |  |  |
|  | medium |  |  |  |
|  | high |  |  |  |
