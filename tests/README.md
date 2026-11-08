# Regression Tests

Run the complete regression path from the repository root in PowerShell:

```powershell
./tests/run-regression.ps1
```

The runner executes the portable Python contracts, expands the TIC-80 showcase and integration game into temporary build files, stages the LÖVE demo, then discovers and runs native checks supported by the current machine. It detects PICO-8 and Picotron from `PATH`, known local install locations, or the `VFX8_PICO8_EXE`, `VFX8_PICOTRON_EXE`, and `VFX8_LOVE_EXE` environment variables. Executable paths can also be passed as parameters:

```powershell
./tests/run-regression.ps1 -Pico8Exe "C:\Games\pico8.exe" -PicotronExe "C:\Games\picotron.exe" -LoveExe "C:\Games\LOVE\love.exe"
```

Use `-PortableOnly` for the CI-safe checks. Use `-RequireNative` to make the command fail if any requested native check is skipped. Native process output and isolated runtime homes are removed after a successful run and preserved in the printed temporary directory after a failure.

## Coverage

| Target | Automated regression coverage | Current limitation |
| --- | --- | --- |
| PICO-8 | Native headless core, advanced, and weather contracts at low, medium, and high; includes oblique rain motion and snow deposits | The user confirms visual checks and measurements for the original effects; weather visual review and measurements remain open |
| Picotron | Isolated native smoke harness covers all nine modules at low, medium, and high; invalid input checks plus rain angle and snow surface behavior | The harness needs a native run for this release; the user confirms visual checks for the original effects, while weather review remains open |
| LÖVE | Portable source/API contracts, staged demo build, and native API contracts for all nine modules, including a separate rain/snow runtime harness | The user confirms native visual checks for the original effects; rain and snow still need visual review |
| TIC-80 | Portable source/API contracts and generated demo/integration include builds for all nine modules | The user confirms visual checks and performance measurements for the original effects; rain and snow still need native verification |

The GitHub Actions workflow runs `./tests/run-regression.ps1 -PortableOnly` on pushes, pull requests, and manual dispatches. Native console and desktop runtimes are optional local checks because they are not part of the portable CI image.
