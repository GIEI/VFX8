# LÖVE Effect Performance

- Runtime: LÖVE 11.5
- Resolution: 320×180; hidden window; VSync disabled
- Repetitions: 5 per row
- Warm-up/sample frames: baseline and typical use 30 / 120; saturated cases use 30 / 600 (recorded per row in the raw CSV)
- CPU metric: median per-frame Lua update/draw time; p95 is reported from frame samples
- Memory metrics: Lua heap deltas in KB and LÖVE texture memory in KB; shader compilation is included in setup where supported
- Host OS: Windows-11-10.0.26200-SP0
- CPU: AMD64 Family 25 Model 33 Stepping 2, AuthenticAMD
- Every measured draw includes the same 320×180 scene; screen effects draw it through the module's scene callback, and per-module baseline rows use an idle effect instance
- Saturated workloads fill each configured helper/pool capacity; particles, flames, and electricity reach those counts through their documented per-update emission caps

The table reports medians across repetition-level means and p95 values. Draw delta compares the effect row with the same profile's baseline draw time. `pixel_deform` and `palette_fx` report helper-call workload counts instead of object pools. This measures Lua submission time, not GPU completion. Texture memory includes runtime and canvas allocations, so use the before/after values to identify additional resources rather than treating the total as shader-only memory.

| Profile | Effect | Workload | Active / limit | Update mean / p95 (ms) | Draw mean / p95 (ms) | Draw Δ vs baseline (ms) | Setup heap Δ (KB) | Sample heap Δ (KB) | Texture before / after (KB) | Mode 7 shader |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| low | baseline | baseline | 0 / 0 | 0.0001 / 0.0001 | 0.0079 / 0.0109 | +0.0000 | +0.25 | +0.89 | 16.00 / 16.00 | no |
| low | baseline | typical | 0 / 0 | 0.0001 / 0.0001 | 0.0072 / 0.0101 | -0.0007 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| low | baseline | saturated | 0 / 0 | 0.0001 / 0.0001 | 0.0074 / 0.0105 | -0.0005 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| low | particles | baseline | 0 / 128 | 0.0002 / 0.0003 | 0.0074 / 0.0107 | -0.0005 | +13.58 | +0.46 | 16.00 / 16.00 | no |
| low | particles | typical | 16 / 128 | 0.0005 / 0.0007 | 0.0096 / 0.0131 | +0.0017 | +13.15 | +0.46 | 16.00 / 16.00 | no |
| low | particles | saturated | 128 / 128 | 0.0010 / 0.0012 | 0.0231 / 0.0336 | +0.0152 | +14.91 | +0.46 | 16.00 / 16.00 | no |
| low | screen_fx | baseline | 0 / 4 | 0.0003 / 0.0004 | 0.0081 / 0.0109 | +0.0002 | +1.30 | +0.46 | 16.00 / 16.00 | no |
| low | screen_fx | typical | 1 / 4 | 0.0004 / 0.0005 | 0.0267 / 0.0340 | +0.0188 | +27.76 | +0.46 | 16.00 / 241.00 | no |
| low | screen_fx | saturated | 4 / 4 | 0.0005 / 0.0006 | 0.0309 / 0.0397 | +0.0230 | +20.59 | +0.46 | 16.00 / 241.00 | no |
| low | pixel_deform | baseline | 0 / 32 | 0.0003 / 0.0004 | 0.0069 / 0.0083 | -0.0010 | +1.17 | +0.46 | 16.00 / 16.00 | no |
| low | pixel_deform | typical | 32 / 32 | 0.0003 / 0.0004 | 0.0084 / 0.0117 | +0.0005 | +1.17 | +0.46 | 16.00 / 16.00 | no |
| low | pixel_deform | saturated | 32 / 32 | 0.0003 / 0.0004 | 0.0082 / 0.0114 | +0.0003 | +1.06 | +0.46 | 16.00 / 16.00 | no |
| low | palette_fx | baseline | 0 / 32 | 0.0004 / 0.0005 | 0.0070 / 0.0099 | -0.0009 | +1.30 | +0.46 | 16.00 / 16.00 | no |
| low | palette_fx | typical | 32 / 32 | 0.0004 / 0.0005 | 0.0075 / 0.0093 | -0.0004 | +2.31 | +0.46 | 16.00 / 16.00 | no |
| low | palette_fx | saturated | 32 / 32 | 0.0004 / 0.0005 | 0.0077 / 0.0112 | -0.0002 | +3.31 | +0.46 | 16.00 / 16.00 | no |
| low | pseudo3d | baseline | 0 / 8 | 0.0004 / 0.0005 | 0.0070 / 0.0089 | -0.0009 | +3.83 | +0.46 | 16.00 / 16.00 | no |
| low | pseudo3d | typical | 1 / 8 | 0.0008 / 0.0010 | 0.0232 / 0.0308 | +0.0153 | +9.82 | +38.27 | 16.00 / 16.00 | yes |
| low | pseudo3d | saturated | 8 / 8 | 0.0008 / 0.0011 | 0.0250 / 0.0332 | +0.0171 | +10.39 | +188.27 | 16.00 / 16.00 | yes |
| low | flames | baseline | 0 / 128 | 0.0004 / 0.0005 | 0.0073 / 0.0091 | -0.0006 | +11.92 | +0.46 | 16.00 / 16.00 | no |
| low | flames | typical | 8 / 128 | 0.0006 / 0.0007 | 0.0086 / 0.0111 | +0.0007 | +12.08 | +0.46 | 16.00 / 16.00 | no |
| low | flames | saturated | 128 / 128 | 0.0011 / 0.0015 | 0.0230 / 0.0349 | +0.0151 | +14.07 | +0.46 | 16.00 / 16.00 | no |
| low | electricity | baseline | 0 / 96 | 0.0004 / 0.0005 | 0.0078 / 0.0116 | -0.0001 | +9.35 | +0.46 | 16.00 / 16.00 | no |
| low | electricity | typical | 12 / 96 | 0.0006 / 0.0007 | 0.0205 / 0.0299 | +0.0126 | +9.46 | +0.46 | 16.00 / 16.00 | no |
| low | electricity | saturated | 96 / 96 | 0.0007 / 0.0008 | 0.0929 / 0.1167 | +0.0850 | +15.14 | +0.46 | 16.00 / 16.00 | no |
| medium | baseline | baseline | 0 / 0 | 0.0001 / 0.0002 | 0.0069 / 0.0103 | +0.0000 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| medium | baseline | typical | 0 / 0 | 0.0001 / 0.0001 | 0.0072 / 0.0106 | +0.0003 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| medium | baseline | saturated | 0 / 0 | 0.0001 / 0.0001 | 0.0069 / 0.0098 | +0.0000 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| medium | particles | baseline | 0 / 320 | 0.0002 / 0.0003 | 0.0072 / 0.0096 | +0.0003 | +45.99 | +0.46 | 16.00 / 16.00 | no |
| medium | particles | typical | 16 / 320 | 0.0005 / 0.0006 | 0.0096 / 0.0129 | +0.0026 | +46.15 | +0.46 | 16.00 / 16.00 | no |
| medium | particles | saturated | 320 / 320 | 0.0019 / 0.0022 | 0.0451 / 0.0595 | +0.0382 | +46.30 | +0.46 | 16.00 / 16.00 | no |
| medium | screen_fx | baseline | 0 / 8 | 0.0003 / 0.0004 | 0.0077 / 0.0106 | +0.0008 | +1.30 | +0.46 | 16.00 / 16.00 | no |
| medium | screen_fx | typical | 1 / 8 | 0.0004 / 0.0005 | 0.0271 / 0.0351 | +0.0202 | +27.76 | +0.46 | 16.00 / 241.00 | no |
| medium | screen_fx | saturated | 8 / 8 | 0.0005 / 0.0006 | 0.0351 / 0.0439 | +0.0282 | +21.62 | +0.46 | 16.00 / 241.00 | no |
| medium | pixel_deform | baseline | 0 / 128 | 0.0003 / 0.0004 | 0.0068 / 0.0087 | -0.0001 | +1.17 | +0.73 | 16.00 / 16.00 | no |
| medium | pixel_deform | typical | 128 / 128 | 0.0003 / 0.0004 | 0.0107 / 0.0154 | +0.0038 | +1.17 | +0.46 | 16.00 / 16.00 | no |
| medium | pixel_deform | saturated | 128 / 128 | 0.0003 / 0.0004 | 0.0110 / 0.0154 | +0.0041 | +1.06 | +0.46 | 16.00 / 16.00 | no |
| medium | palette_fx | baseline | 0 / 128 | 0.0003 / 0.0004 | 0.0071 / 0.0085 | +0.0002 | +1.19 | +0.46 | 16.00 / 16.00 | no |
| medium | palette_fx | typical | 128 / 128 | 0.0003 / 0.0005 | 0.0084 / 0.0115 | +0.0014 | +2.85 | +0.46 | 16.00 / 16.00 | no |
| medium | palette_fx | saturated | 128 / 128 | 0.0004 / 0.0005 | 0.0088 / 0.0132 | +0.0018 | +2.31 | +0.46 | 16.00 / 16.00 | no |
| medium | pseudo3d | baseline | 0 / 16 | 0.0004 / 0.0005 | 0.0069 / 0.0095 | +0.0000 | +5.75 | +0.46 | 16.00 / 16.00 | no |
| medium | pseudo3d | typical | 1 / 16 | 0.0008 / 0.0010 | 0.0254 / 0.0335 | +0.0185 | +14.37 | +38.27 | 16.00 / 16.00 | yes |
| medium | pseudo3d | saturated | 16 / 16 | 0.0009 / 0.0011 | 0.0297 / 0.0395 | +0.0228 | +17.24 | +188.27 | 16.00 / 16.00 | yes |
| medium | flames | baseline | 0 / 256 | 0.0004 / 0.0005 | 0.0075 / 0.0099 | +0.0006 | +21.92 | +0.46 | 16.00 / 16.00 | no |
| medium | flames | typical | 8 / 256 | 0.0006 / 0.0007 | 0.0086 / 0.0107 | +0.0017 | +22.08 | +0.46 | 16.00 / 16.00 | no |
| medium | flames | saturated | 256 / 256 | 0.0017 / 0.0019 | 0.0381 / 0.0522 | +0.0312 | +22.55 | +0.46 | 16.00 / 16.00 | no |
| medium | electricity | baseline | 0 / 192 | 0.0004 / 0.0005 | 0.0075 / 0.0108 | +0.0006 | +16.35 | +0.46 | 16.00 / 16.00 | no |
| medium | electricity | typical | 15 / 192 | 0.0006 / 0.0007 | 0.0224 / 0.0287 | +0.0155 | +16.46 | +0.46 | 16.00 / 16.00 | no |
| medium | electricity | saturated | 192 / 192 | 0.0008 / 0.0009 | 0.1767 / 0.1990 | +0.1697 | +17.60 | +0.46 | 16.00 / 16.00 | no |
| high | baseline | baseline | 0 / 0 | 0.0001 / 0.0001 | 0.0068 / 0.0097 | +0.0000 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| high | baseline | typical | 0 / 0 | 0.0001 / 0.0001 | 0.0069 / 0.0092 | +0.0000 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| high | baseline | saturated | 0 / 0 | 0.0001 / 0.0001 | 0.0070 / 0.0087 | +0.0001 | +0.25 | +0.46 | 16.00 / 16.00 | no |
| high | particles | baseline | 0 / 640 | 0.0002 / 0.0003 | 0.0070 / 0.0084 | +0.0001 | +89.99 | +0.91 | 16.00 / 16.00 | no |
| high | particles | typical | 16 / 640 | 0.0005 / 0.0006 | 0.0097 / 0.0135 | +0.0029 | +90.15 | +0.46 | 16.00 / 16.00 | no |
| high | particles | saturated | 640 / 640 | 0.0035 / 0.0040 | 0.0802 / 0.0912 | +0.0734 | +90.50 | +0.46 | 16.00 / 16.00 | no |
| high | screen_fx | baseline | 0 / 16 | 0.0003 / 0.0004 | 0.0076 / 0.0092 | +0.0007 | +1.30 | +0.91 | 16.00 / 16.00 | no |
| high | screen_fx | typical | 1 / 16 | 0.0004 / 0.0005 | 0.0264 / 0.0315 | +0.0195 | +27.76 | +0.91 | 16.00 / 241.00 | no |
| high | screen_fx | saturated | 16 / 16 | 0.0006 / 0.0007 | 0.0425 / 0.0508 | +0.0356 | +24.20 | +0.46 | 16.00 / 241.00 | no |
| high | pixel_deform | baseline | 0 / 512 | 0.0003 / 0.0004 | 0.0068 / 0.0092 | -0.0001 | +1.17 | +0.46 | 16.00 / 16.00 | no |
| high | pixel_deform | typical | 512 / 512 | 0.0003 / 0.0004 | 0.0218 / 0.0274 | +0.0149 | +1.17 | +0.46 | 16.00 / 16.00 | no |
| high | pixel_deform | saturated | 512 / 512 | 0.0003 / 0.0004 | 0.0218 / 0.0290 | +0.0149 | +1.06 | +0.91 | 16.00 / 16.00 | no |
| high | palette_fx | baseline | 0 / 512 | 0.0003 / 0.0004 | 0.0067 / 0.0081 | -0.0002 | +1.19 | +0.91 | 16.00 / 16.00 | no |
| high | palette_fx | typical | 512 / 512 | 0.0004 / 0.0004 | 0.0125 / 0.0167 | +0.0056 | +2.20 | +0.91 | 16.00 / 16.00 | no |
| high | palette_fx | saturated | 512 / 512 | 0.0004 / 0.0005 | 0.0124 / 0.0168 | +0.0055 | +2.20 | +0.91 | 16.00 / 16.00 | no |
| high | pseudo3d | baseline | 0 / 32 | 0.0004 / 0.0005 | 0.0070 / 0.0095 | +0.0001 | +7.73 | +0.91 | 16.00 / 16.00 | no |
| high | pseudo3d | typical | 1 / 32 | 0.0010 / 0.0012 | 0.0285 / 0.0360 | +0.0217 | +24.57 | +38.72 | 16.00 / 16.00 | yes |
| high | pseudo3d | saturated | 32 / 32 | 0.0012 / 0.0014 | 0.0391 / 0.0507 | +0.0322 | +28.93 | +188.72 | 16.00 / 16.00 | yes |
| high | flames | baseline | 0 / 512 | 0.0004 / 0.0004 | 0.0073 / 0.0088 | +0.0004 | +41.92 | +0.91 | 16.00 / 16.00 | no |
| high | flames | typical | 8 / 512 | 0.0006 / 0.0007 | 0.0086 / 0.0112 | +0.0018 | +42.08 | +0.46 | 16.00 / 16.00 | no |
| high | flames | saturated | 512 / 512 | 0.0029 / 0.0034 | 0.0665 / 0.0805 | +0.0596 | +43.50 | +0.46 | 16.00 / 16.00 | no |
| high | electricity | baseline | 0 / 320 | 0.0004 / 0.0005 | 0.0073 / 0.0085 | +0.0005 | +30.35 | +0.91 | 16.00 / 16.00 | no |
| high | electricity | typical | 20 / 320 | 0.0006 / 0.0007 | 0.0273 / 0.0344 | +0.0205 | +32.48 | +0.46 | 16.00 / 16.00 | no |
| high | electricity | saturated | 320 / 320 | 0.0010 / 0.0011 | 0.2866 / 0.3199 | +0.2797 | +32.54 | +0.46 | 16.00 / 16.00 | no |
