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
- [ ] Icon Composer document and flattened renditions are verified.

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

- [ ] `make build` passes.
- [ ] `make test` passes.
- [ ] `make ui-test` passes.
- [ ] `make lint-check` passes.
- [x] `make docs-build` passes.
- [ ] `make sim` launches the app in a local iPhone Simulator.
- [ ] `artifacts/simulator-home.png` exists.
- [ ] `artifacts/simulator-run.txt` records the exact local run.
- [ ] Simulator logs are inspected for crashes and serious runtime faults.

## Release preparation

- [x] Native and Pages GitHub Actions workflows exist.
- [x] Privacy, support, App Store copy, review notes, and open-source notices exist as drafts.
- [x] Signing files, generated evidence, and user VRM files are ignored.
- [ ] Every physical-iPhone item in `DEVICE_TEST_CHECKLIST.md` is completed before release.
