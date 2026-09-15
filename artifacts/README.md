# Local verification artifacts

Verified on 2026-09-14 with Xcode 26.6 and the local ConPaws iPhone Pro Max Simulator running iOS 26.5.

| Artifact | Evidence |
| --- | --- |
| `simulator-build.log` | Simulator build command and `BUILD SUCCEEDED`. |
| `simulator-run.txt` | Runtime, device, build command, installed app path, successful install, launch result, and screenshot path. |
| `simulator-home.png` | Running SonaPin app at onboarding Step 1 of 9. |
| `simulator.log` | Captured process log. No app crash or serious runtime fault was found; two CoreSimulator launch-measurement submission errors are retained. |
| `unit-tests.log` | 29 Swift Testing tests in 5 suites passed. Optional local VRM parsing and rendering paths were not exercised because `LocalAssets/TestAvatar.vrm` is absent. |
| `unit-tests.xcresult` | Unit-test result bundle. |
| `ui-tests.log` | 3 XCTest UI tests passed with 0 failures. |
| `ui-tests.xcresult` | UI-test result bundle. |

The generic `make build` command also passed with code signing disabled. No iOS 18 Simulator runtime is installed on this Mac, so the recorded launch and test evidence is for iOS 26.5, not iOS 18.

Generated evidence stays untracked because it can include local device identifiers and machine paths. Physical-iPhone checks and the owner's real VRM remain pending in `docs/DEVICE_TEST_CHECKLIST.md`.
