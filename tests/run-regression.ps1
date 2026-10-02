param(
  [string]$Python = "python",
  [string]$Pico8Exe,
  [string]$PicotronExe,
  [string]$LoveExe,
  [switch]$PortableOnly,
  [switch]$RequireNative
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-EnginePath([string]$Provided, [string]$EnvironmentName, [string[]]$Candidates, [string]$CommandName) {
  if ($Provided) { return (Resolve-Path -LiteralPath $Provided).Path }
  $fromEnvironment = [Environment]::GetEnvironmentVariable($EnvironmentName)
  if ($fromEnvironment -and (Test-Path -LiteralPath $fromEnvironment -PathType Leaf)) {
    return (Resolve-Path -LiteralPath $fromEnvironment).Path
  }
  $onPath = Get-Command $CommandName -ErrorAction SilentlyContinue
  if ($onPath) { return $onPath.Source }
  foreach ($candidate in $Candidates) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
  }
  return $null
}

function Invoke-OwnedProcess([string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory, [int]$TimeoutSeconds, [string]$Label, [switch]$StopAfterTimeout) {
  $stdout = Join-Path $script:runRoot (([guid]::NewGuid().ToString("N")) + ".out")
  $stderr = Join-Path $script:runRoot (([guid]::NewGuid().ToString("N")) + ".err")
  $quotedArguments = @($Arguments | ForEach-Object {
    '"' + ($_ -replace '"', '\"') + '"'
  }) -join " "
  $process = Start-Process -FilePath $FilePath -ArgumentList $quotedArguments -WorkingDirectory $WorkingDirectory `
    -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
  $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
  if ($timedOut) {
    try { $process.Kill() } catch { }
    $process.WaitForExit()
    if (-not $StopAfterTimeout) {
      throw "$Label exceeded the $TimeoutSeconds second timeout (owned process $($process.Id) was stopped)."
    }
  }
  $output = ""
  if (Test-Path -LiteralPath $stdout) { $output += Get-Content -LiteralPath $stdout -Raw }
  if (Test-Path -LiteralPath $stderr) { $output += Get-Content -LiteralPath $stderr -Raw }
  return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $output; TimedOut = $timedOut }
}

$script:runRoot = Join-Path ([IO.Path]::GetTempPath()) ("vfx8-regression-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $script:runRoot | Out-Null
$nativeAvailable = 0
$nativePassed = 0
$nativeSkipped = 0
$failed = $false

try {
  Push-Location $repoRoot
  try {
    Write-Output "[portable] Python contract suite"
    & $Python -m unittest discover -s tests -p "test_*.py"
    if ($LASTEXITCODE -ne 0) { throw "Python contract suite failed with exit code $LASTEXITCODE." }

    Write-Output "[portable] TIC-80 include build"
    $ticOutput = Join-Path $script:runRoot "tic80-demo.lua"
    & $Python tools/tic80_include.py examples/tic80/demo.lua -o $ticOutput
    if ($LASTEXITCODE -ne 0) { throw "TIC-80 include build failed with exit code $LASTEXITCODE." }

    Write-Output "[portable] LÖVE demo staging"
    & $Python examples/love2d/stage_demo.py --stage-only
    if ($LASTEXITCODE -ne 0) { throw "LÖVE demo staging failed with exit code $LASTEXITCODE." }
  }
  finally {
    Pop-Location
  }

  if (-not $PortableOnly) {
    $pico = Resolve-EnginePath $Pico8Exe "VFX8_PICO8_EXE" @("K:\Games\pico-8\pico8.exe") "pico8"
    if ($pico) {
      $nativeAvailable++
      foreach ($cart in @("profile_contract.p8", "profile_contract_advanced.p8")) {
        $cartPath = Join-Path $repoRoot ("tests\pico8\" + $cart)
        $testHome = Join-Path $script:runRoot ("pico8-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $testHome | Out-Null
        Write-Output "[native] PICO-8 $cart"
        $result = Invoke-OwnedProcess $pico @("-home", $testHome, "-x", $cartPath) $repoRoot 5 "PICO-8 $cart" -StopAfterTimeout
        if ($result.Output -match "ERROR:" -or $result.Output -notmatch "VFX8_(CORE|ADVANCED)_PROFILE_CONTRACT,PASS") {
          throw "PICO-8 $cart failed. Runtime output:`n$($result.Output)"
        }
        $nativePassed++
      }
    }
    else { $nativeSkipped++; Write-Warning "PICO-8 native contracts skipped; set VFX8_PICO8_EXE or pass -Pico8Exe." }

    $picotron = Resolve-EnginePath $PicotronExe "VFX8_PICOTRON_EXE" @("K:\Games\picotron\picotron.exe") "picotron"
    if ($picotron) {
      $nativeAvailable++
      Write-Output "[native] Picotron profile smoke"
      & (Join-Path $PSScriptRoot "picotron\run-smoke.ps1") -PicotronExe $picotron
      if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Picotron profile smoke failed with exit code $LASTEXITCODE." }
      $nativePassed++
    }
    else { $nativeSkipped++; Write-Warning "Picotron native smoke skipped; set VFX8_PICOTRON_EXE or pass -PicotronExe." }

    $love = Resolve-EnginePath $LoveExe "VFX8_LOVE_EXE" @("I:\Program Files\LOVE\love.exe", "C:\Program Files\LOVE\love.exe") "love"
    if ($love) {
      $nativeAvailable++
      Write-Output "[native] LÖVE API contracts"
      $resultFile = Join-Path $script:runRoot "love-result.txt"
      $env:VFX8_TEST_ROOT = $repoRoot.Replace("\", "/")
      $env:VFX8_TEST_RESULT = $resultFile
      try {
        $result = Invoke-OwnedProcess $love @((Join-Path $repoRoot "tests\love2d")) $repoRoot 30 "LÖVE API contracts"
      }
      finally {
        Remove-Item Env:\VFX8_TEST_ROOT -ErrorAction SilentlyContinue
        Remove-Item Env:\VFX8_TEST_RESULT -ErrorAction SilentlyContinue
      }
      $testResult = if (Test-Path -LiteralPath $resultFile) { Get-Content -LiteralPath $resultFile -Raw } else { "" }
      if ($result.Output -match "Failed to initialize filesystem") {
        $nativeSkipped++
        Write-Warning "LÖVE runtime test unavailable: the runtime could not initialize its user filesystem."
      }
      elseif ($result.ExitCode -ne 0 -or $testResult.Trim() -ne "passed") {
        throw "LÖVE API contracts failed. Runtime output:`n$($result.Output)`nContract result: $testResult"
      }
      else { $nativePassed++ }
    }
    else { $nativeSkipped++; Write-Warning "LÖVE native contracts skipped; set VFX8_LOVE_EXE or pass -LoveExe." }

    $tic = Resolve-EnginePath "" "VFX8_TIC80_EXE" @() "tic80"
    if (-not $tic) { $nativeSkipped++; Write-Warning "TIC-80 native launch skipped; no TIC-80 executable is installed or available on PATH. The include build passed." }
    else { $nativeSkipped++; Write-Warning "TIC-80 executable found at $tic, but native cartridge automation is not configured; the include build passed." }
  }

  if ($RequireNative -and $nativeSkipped -gt 0) {
    throw "$nativeSkipped native runtime check(s) were skipped while -RequireNative was set."
  }
  Write-Output "Regression checks passed. Native executables detected: $nativeAvailable; native checks passed: $nativePassed; native checks skipped: $nativeSkipped."
}
catch {
  $failed = $true
  throw
}
finally {
  if (-not $failed -and (Test-Path -LiteralPath $script:runRoot)) {
    $resolvedRunRoot = (Resolve-Path -LiteralPath $script:runRoot).Path
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (-not $resolvedRunRoot.StartsWith($tempRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove regression output outside the system temporary directory: $resolvedRunRoot"
    }
    Remove-Item -LiteralPath $resolvedRunRoot -Recurse -Force
  }
  elseif (Test-Path -LiteralPath $script:runRoot) {
    Write-Warning "Regression logs and isolated runtime homes retained at $script:runRoot"
  }
}
