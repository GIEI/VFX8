# Picotron Runtime Smoke Test

`runtime_smoke.lua` loads all seven Picotron modules at `low`, `medium`, and `high`. It exercises every particle preset and emission shape, palette filters and maps, shake directions, flame and lightning variants, pixel deformation helpers, invalid preset/filter/texture/vector inputs, and textured/fallback pseudo-3D drawing. It writes a pass marker into an isolated Picotron home and does not modify the user's default Picotron drive.

Run the wrapper from the repository root in PowerShell, providing the installed executable. The complete regression runner discovers this runtime automatically; see [`../README.md`](../README.md).

```powershell
./tests/picotron/run-smoke.ps1 -PicotronExe "K:\Games\picotron\picotron.exe"
```

The wrapper checks the native runtime's pass messages for every profile and removes its temporary home after success. It preserves the home and log when a check fails. Headless drawing-call coverage does not replace reviewing the interactive demo's visual composition or measuring performance.
