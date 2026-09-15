# SonaPin implementation checklist

Updated after each verified phase. A checked item means evidence exists in this repository or was produced by the named command.

## Foundation

- [x] Working product name is SonaPin.
- [x] Native app lives in `apps/native`; Pages site lives in `apps/docs`.
- [x] Deployment target is iOS 18.0.
- [x] Swift language mode is 6 with complete strict concurrency.
- [x] Installed Swift and iOS skills were audited and applied.
- [x] Primary-source research and name research are documented.
- [x] `SonaPin.xcodeproj` and the shared `SonaPin` scheme generate with XcodeGen.
- [x] VRMKit is pinned exactly to 0.10.0.
- [x] Apple Icon Composer document uses the 1024 x 1024 transparent wolf foreground over the navy background.
- [ ] Flattened icon renditions and appearance variants are verified in an archive and on a physical iPhone.

## Product

- [ ] Procedural demo avatar renders and responds to tap, drag, pinch, and reset.
- [ ] Nine-step resumable onboarding completes.
- [ ] Profile and QR editing persist.
- [ ] Badge Mode presents an unobstructed avatar, identity, and large QR code.
- [ ] Reduce Motion, haptics, and keep-awake preferences work.
- [ ] Security-scoped VRM import validates before atomic replacement.
- [ ] Failed imports preserve the current avatar.
- [ ] Compatibility reporting covers metadata, bones, expressions, extensions, and warnings.
- [ ] Imported content and profile data remain on-device.

## Verification

- [x] `make build` passes for a generic iOS Simulator destination with Xcode 26.6.
- [x] `make test` passes: 29 tests in 5 suites, with the optional local VRM fixture paths not exercised because `LocalAssets/TestAvatar.vrm` is absent.
- [x] `make ui-test` passes: 3 XCTest UI tests with 0 failures.
- [x] `make lint-check` passes.
- [x] `make docs-build` passes.
- [x] `make sim` builds, installs, and launches the app on the local ConPaws iPhone Pro Max Simulator running iOS 26.5.
- [x] `artifacts/simulator-home.png` captures the running app at onboarding Step 1 of 9.
- [x] `artifacts/simulator-run.txt` records Xcode 26.6, the iOS 26.5 runtime, device, build command, installed app path, launch result, and screenshot path.
- [x] `artifacts/simulator.log` was inspected: no app crash or serious runtime fault was found; two CoreSimulator launch-measurement submission errors remain in the log.
- [ ] Run the automated suite on an iOS 18 Simulator runtime; no iOS 18 runtime is installed on this Mac.

## Release preparation

- [x] Native and Pages GitHub Actions workflows exist.
- [x] Privacy, support, App Store copy, review notes, and open-source notices exist as drafts.
- [x] Signing files, generated evidence, and user VRM files are ignored.
- [ ] Every physical-iPhone item in `DEVICE_TEST_CHECKLIST.md` is completed before release.
