# Picotron Runtime Smoke Test

`runtime_smoke.lua` loads all seven Picotron modules, exercises their public update and rendering paths, and writes a pass marker into the isolated Picotron home. It does not modify the user's default Picotron drive.

Run it from the repository root in PowerShell:

```powershell
$picotron = "<path-to-picotron.exe>"
$testHome = Join-Path $env:TEMP "vfx8-picotron-runtime-test\home"
$moduleDir = Join-Path $testHome "drive\desktop\vfx8-picotron-runtime\vfx8"
New-Item -ItemType Directory -Force -Path $moduleDir | Out-Null
Copy-Item "src\picotron\*.lua" $moduleDir -Force
$startedAt = Get-Date
& $picotron -home $testHome -x (Resolve-Path "tests\picotron\runtime_smoke.lua")
if ($LASTEXITCODE -ne 0) { throw "Picotron runtime smoke failed with exit code $LASTEXITCODE" }
$marker = Join-Path $testHome "drive\appdata\vfx8_picotron_runtime_smoke.pod"
if (-not (Test-Path $marker) -or (Get-Item $marker).LastWriteTime -lt $startedAt) {
  throw "Picotron did not write a fresh smoke-test pass marker"
}
```

The final command must return `True`. The smoke test uses Picotron's headless mode, so it verifies runtime/API compatibility and drawing calls without assessing the interactive showcase's visual composition or measuring performance.
