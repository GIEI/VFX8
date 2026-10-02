param(
  [Parameter(Mandatory = $true)]
  [string]$PicotronExe
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$PicotronExe = (Resolve-Path -LiteralPath $PicotronExe).Path
if (-not (Test-Path -LiteralPath $PicotronExe -PathType Leaf)) {
  throw "Picotron executable not found: $PicotronExe"
}

$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testHome = Join-Path $tempRoot ("vfx8-picotron-smoke-" + [guid]::NewGuid().ToString("N"))
$moduleDir = Join-Path $testHome "drive\desktop\vfx8-picotron-runtime\vfx8"
$smokePath = Join-Path $repoRoot "tests\picotron\runtime_smoke.lua"
$passed = $false

try {
  New-Item -ItemType Directory -Force -Path $moduleDir | Out-Null
  Copy-Item (Join-Path $repoRoot "src\picotron\*.lua") $moduleDir -Force
  Push-Location $repoRoot
  try {
    $output = & $PicotronExe -home $testHome -x $smokePath 2>&1
  }
  finally {
    Pop-Location
  }

  $markerDir = Join-Path $testHome "drive\appdata"
  $markers = @(
    "vfx8_picotron_low_profile_smoke.pod",
    "vfx8_picotron_medium_profile_smoke.pod",
    "vfx8_picotron_high_profile_smoke.pod",
    "vfx8_picotron_runtime_smoke.pod"
  )
  $markersReady = $false
  for ($attempt = 0; $attempt -lt 20; $attempt++) {
    $markersReady = $true
    foreach ($name in $markers) {
      if (-not (Test-Path -LiteralPath (Join-Path $markerDir $name) -PathType Leaf)) {
        $markersReady = $false
        break
      }
    }
    if ($markersReady) { break }
    Start-Sleep -Milliseconds 250
  }
  foreach ($name in $markers) {
    if (-not (Test-Path -LiteralPath (Join-Path $markerDir $name) -PathType Leaf)) {
      throw "Picotron did not write the expected pass marker ($name). Home retained at $testHome"
    }
  }

  $passed = $true
  Write-Output "Picotron native profile smoke passed: low, medium, high; all seven modules and covered variants."
}
finally {
  if ($passed -and (Test-Path -LiteralPath $testHome)) {
    $resolvedHome = [IO.Path]::GetFullPath($testHome)
    if (-not $resolvedHome.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or $resolvedHome -eq $tempRoot) {
      throw "Refusing to remove a Picotron test home outside the system temporary directory: $resolvedHome"
    }
    Remove-Item -LiteralPath $resolvedHome -Recurse -Force
  }
  elseif (Test-Path -LiteralPath $testHome) {
    Write-Warning "Picotron test home retained for diagnosis: $testHome"
  }
}
