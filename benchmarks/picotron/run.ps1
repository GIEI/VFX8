param(
  [Parameter(Mandatory = $true)]
  [string]$PicotronExe,
  [string]$Python = "python",
  [string]$Output = (Join-Path $PSScriptRoot "../results/picotron-effects.csv"),
  [ValidateRange(1, 600)]
  [int]$WarmupFrames = 30,
  [ValidateRange(1, 600)]
  [int]$SampleFrames = 120,
  [ValidateRange(1, 20)]
  [int]$Repetitions = 5,
  [ValidateRange(10, 3600)]
  [int]$TimeoutSeconds = 1800
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$PicotronExe = (Resolve-Path -LiteralPath $PicotronExe).Path
if (-not (Test-Path -LiteralPath $PicotronExe -PathType Leaf)) { throw "Picotron executable not found: $PicotronExe" }

$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
$runRoot = Join-Path $tempRoot ("vfx8-picotron-benchmark-" + [guid]::NewGuid().ToString("N"))
$testHome = Join-Path $runRoot "home"
$moduleDir = Join-Path $testHome "drive\desktop\vfx8-picotron-runtime\vfx8"
$stdout = Join-Path $runRoot "stdout.log"
$stderr = Join-Path $runRoot "stderr.log"
$outputPath = [IO.Path]::GetFullPath($Output)
$passed = $false

try {
  New-Item -ItemType Directory -Force -Path $moduleDir | Out-Null
  Copy-Item (Join-Path $repoRoot "src\picotron\*.lua") $moduleDir -Force
  $source = Get-Content -LiteralPath (Join-Path $PSScriptRoot "benchmark.lua") -Raw
  $source = $source -replace '(?m)^local warmup_frames=\d+$', "local warmup_frames=$WarmupFrames"
  $source = $source -replace '(?m)^local sample_frames=\d+$', "local sample_frames=$SampleFrames"
  $source = $source -replace '(?m)^local repetitions=\d+$', "local repetitions=$Repetitions"
  $benchmarkPath = Join-Path $runRoot "benchmark.lua"
  [IO.File]::WriteAllText($benchmarkPath, $source, [Text.UTF8Encoding]::new($false))

  $process = Start-Process -FilePath $PicotronExe -ArgumentList ('"-home" "' + $testHome + '" "-x" "' + $benchmarkPath + '"') `
    -WorkingDirectory $repoRoot -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    try { $process.Kill() } catch { }
    $process.WaitForExit()
    throw "Picotron benchmark exceeded the $TimeoutSeconds second timeout."
  }

  $runtimeOutput = ""
  if (Test-Path -LiteralPath $stdout) { $runtimeOutput += Get-Content -LiteralPath $stdout -Raw }
  if (Test-Path -LiteralPath $stderr) { $runtimeOutput += Get-Content -LiteralPath $stderr -Raw }
  if ($process.ExitCode -ne 0) { throw "Picotron benchmark exited with code $($process.ExitCode):`n$runtimeOutput" }

  $lines = @($runtimeOutput -split "`r?`n" | Where-Object { $_ -match 'VFX8_PICOTRON_BENCH,' } | ForEach-Object {
    $markerIndex = $_.IndexOf("VFX8_PICOTRON_BENCH,", [StringComparison]::Ordinal)
    $_.Substring($markerIndex)
  })
  $recordLines = @($lines | Where-Object { $_ -notmatch '^VFX8_PICOTRON_BENCH,(PASS|engine_version),' })
  $expected = 3 * (1 + 7 * 2) * $Repetitions
  $passLine = $lines | Where-Object { $_ -match '^VFX8_PICOTRON_BENCH,PASS,' } | Select-Object -Last 1
  if ($recordLines.Count -ne $expected -or -not $passLine -or $passLine -notmatch ",$expected$") {
    throw "Picotron benchmark emitted $($recordLines.Count) records; expected $expected. Runtime output retained for diagnosis."
  }

  $csvLines = @($lines | Where-Object { $_ -notmatch '^VFX8_PICOTRON_BENCH,PASS,' } | ForEach-Object { $_ -replace '^VFX8_PICOTRON_BENCH,', '' })
  if ($csvLines.Count -ne ($expected + 1)) { throw "Picotron benchmark output is missing its CSV header or data rows." }
  $runtimeLog = Get-Content -LiteralPath (Join-Path $testHome "log.txt") -Raw
  $versionMatch = [regex]::Match($runtimeLog, 'booting picotron ([^\r\n]+)')
  $runtimeVersion = if ($versionMatch.Success) { $versionMatch.Groups[1].Value.Trim() } else { "unavailable" }
  for ($i = 1; $i -lt $csvLines.Count; $i++) { $csvLines[$i] = $csvLines[$i] -replace '^0x[0-9a-fA-F]+,', "$runtimeVersion," }
  $parent = Split-Path -Parent $outputPath
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  [IO.File]::WriteAllLines($outputPath, $csvLines, [Text.UTF8Encoding]::new($false))
  $summaryPath = [IO.Path]::ChangeExtension($outputPath, ".md")
  $hostOs = [Environment]::OSVersion.VersionString
  try { $cpuModel = (Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -Name ProcessorNameString -ErrorAction Stop).ProcessorNameString }
  catch { $cpuModel = "unavailable" }
  Push-Location $repoRoot
  try {
    & $Python benchmarks/picotron/summarize.py --input $outputPath --output $summaryPath --host-os $hostOs --cpu $cpuModel
    if ($LASTEXITCODE -ne 0) { throw "Picotron benchmark summarizer failed with exit code $LASTEXITCODE." }
  }
  finally { Pop-Location }
  $passed = $true
  Write-Output "Picotron benchmark passed: $expected records across seven effects, three profiles, and $Repetitions repetitions."
  Write-Output "Raw results: $outputPath"
}
finally {
  if (Test-Path -LiteralPath $runRoot) {
    $resolved = (Resolve-Path -LiteralPath $runRoot).Path
    if (-not $resolved.StartsWith($tempRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove Picotron benchmark data outside the system temporary directory: $resolved"
    }
    if ($passed) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    else { Write-Warning "Picotron benchmark home and logs retained at $resolved" }
  }
}
