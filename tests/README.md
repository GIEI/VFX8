# Regression Tests

Run the complete regression path from the repository root in PowerShell:

```powershell
./tests/run-regression.ps1
```

The runner executes the portable Python contracts, expands the TIC-80 showcase into a temporary build file, stages the LÖVE demo, then discovers and runs the native checks supported by the current machine. It detects PICO-8 and Picotron from `PATH`, known local install locations, or the `VFX8_PICO8_EXE`, `VFX8_PICOTRON_EXE`, and `VFX8_LOVE_EXE` environment variables. Executable paths can also be passed as parameters:

```powershell
./tests/run-regression.ps1 -Pico8Exe "C:\Games\pico8.exe" -PicotronExe "C:\Games\picotron.exe" -LoveExe "C:\Games\LOVE\love.exe"
```

Use `-PortableOnly` for the CI-safe checks. Use `-RequireNative` to make the command fail if any requested native check is skipped. Native process output and isolated runtime homes are removed after a successful run and preserved in the printed temporary directory after a failure.

## Coverage

| Target | Automated regression coverage | Current limitation |
| --- | --- | --- |
| PICO-8 | Native headless core and advanced contracts at low, medium, and high; invalid preset/filter/texture/vector inputs | The user confirms visual checks and performance measurements are complete; detailed records are maintained separately |
| Picotron | Isolated native headless smoke for all seven modules at low, medium, and high; invalid preset/filter/texture/vector inputs | The user confirms native visual checks are complete; frame-time measurements are reported separately |
| LÖVE | Portable source/API contracts, staged demo build, and a native API contract harness | The user confirms native visual checks are complete. The harness is skipped when LÖVE cannot initialize its user filesystem |
| TIC-80 | Portable source contracts and generated include build | The user confirms visual checks and performance measurements are complete; native executable automation is not available on every workstation |

The GitHub Actions workflow runs `./tests/run-regression.ps1 -PortableOnly` on pushes, pull requests, and manual dispatches. Native console and desktop runtimes are optional local checks because they are not part of the portable CI image.
