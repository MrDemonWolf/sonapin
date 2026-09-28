# SonaPin 1.0 release checklist

SonaPin is a released open-source iOS project with a TestFlight build. Public App Store distribution is a separate gate. This list records verified work as of 2026-09-28.

## Product

- [x] Swift 6 and SwiftUI app targets iOS 18 and later.
- [x] Built-in demo avatar, badge profile, QR code, VRM import, and local settings are implemented.
- [x] Profile and avatar content stay on-device; no account, ads, product analytics, or tracking. Sentry-enabled builds send limited diagnostics for app functionality.
- [x] Public website includes product, support, privacy, terms, and acknowledgments pages.
- [x] Source app and website use version 1.0.0 release copy.

## Automated checks

- [x] Active `Solo Main Protection` ruleset requires `E2E / Verify` and `Xcode 26.6 / macOS 26`; strict status checks are enabled and no bypass actors are configured.
- [x] Checkpoint `f6ebd98`: `E2E / Verify` passed on workflow run `36227806626`.
- [x] Checkpoint `f6ebd98`: Native lint, Simulator build, unit tests, and UI tests passed on workflow run `36227806627`.

## Sentry

- [x] Sentry Cocoa 9.29.0 is integrated with PII, screenshots, view hierarchy, breadcrumbs, session tracking, and network capture disabled.
- [x] A debug simulator smoke event reached the `sonapin` Sentry project. This verifies delivery only.
- [x] Confirmed a fatal “App Hang Fully Blocked” event: the OS watchdog terminated SonaPin Dev after its main thread blocked for at least 2 seconds.
- [ ] Symbolicate Sentry issue `SONAPIN-X` (event `a7be82464de549f9a6f165e8078e7720`) before naming a cause. It is SonaPin Dev 1.0.0 (21), build `26A428`, on an iPhone 18 Pro Max simulator running iOS 27; Sentry requires `SonaPin.debug.dylib` UUID `73C45324-EC04-3EE1-917F-56DA204BEF5B`.
- [x] Debug builds now tag events as `development`; Release builds tag events as `production`.
- [x] Verified a fresh debug smoke event arrived with the `development` environment.
- [ ] Resolve IP-derived location before finalizing App Privacy: the fatal-hang event shows approximate geography, and Sentry IP scrubbing is off.
- [x] Confirmed Sentry's Debug Information Files page currently has no uploaded symbols. The previously built Debug dSYM UUID `5FE2D638-9AC8-3A85-92B7-20A0C50786E2` does not match this event.
- [x] Built and launched a fresh Debug simulator app on 2026-09-28. Its matching dSYM has `SonaPin.debug.dylib` UUID `DB185FF4-1D03-3AD7-9511-9288CCEFD3AF` (app executable UUID `2DFA77F5-93EF-3B00-9E21-D803ABE2E96F`); neither matches the older event.
- [x] Build Release archive 1.0.0 build 21; the app binary and its dSYM match at UUID `560CF100-12DD-3B62-81E3-9B3B60B6272E`.
- [ ] Export a Distribution-signed TestFlight IPA for build 21. Xcode currently has no valid Apple account credentials or Apple Distribution certificate for team `HBB7T99U79`.
- [ ] Upload the exact event's matching dSYM if its original archive can be recovered; otherwise upload the fresh build's symbols before generating a new event and verifying readable app frames. The local `sentry-cli` has no authentication configured.
- [ ] Profile a fresh SonaPin Dev launch in Time Profiler. The fresh simulator displayed the onboarding avatar and a later 3-second process sample showed an idle main run loop; the hang was not reproduced. Synchronous RealityKit `makeRig()` work remains a lead, not a confirmed cause.
- [ ] Sample events from a real TestFlight device before clearing the remaining hang issues.

## TestFlight gate

- [x] Xcode 27 exported version 1.0.0 build 8 as an App Store Connect IPA; store profile and privacy manifest inspected.
- [x] Confirm App Store Connect app record and bundle ID; version 1.0 is Prepare for Submission.
- [x] Confirm the 4+ age rating and the build 1 assignment to the Private Beta internal group.
- [x] Public privacy policy describes Sentry-enabled crash and hang diagnostics.
- [ ] Update the unpublished App Privacy draft for Sentry; keep it unpublished until it matches the final build.
- [ ] Complete Content Rights and App Review contact details.
- [ ] Complete every physical-iPhone check in [DEVICE_TEST_CHECKLIST.md](DEVICE_TEST_CHECKLIST.md).
- [x] Deployed support and privacy URLs opened successfully on 2026-09-22.
- [x] Confirm an installed TestFlight build: 1.0.0 build 1 is testing in the Private Beta group.
- [x] Upload five iPhone screenshots and save updated App Store listing copy.
- [x] Upload the 13-inch iPad screenshot.
- [x] Capture and compose five current iPhone 18 Pro Max App Store screenshots at 1320 × 2868; the first three show the badge, QR scan, and profile customization. Source app screenshots and store artwork are saved under `apps/docs/public/screenshots/`.
- [ ] Upload the five refreshed iPhone screenshots to App Store Connect. The current Chrome session is signed out.

Simulator results do not clear the physical-device or App Store Connect gates.

## Public release monitoring

- [ ] After public release, monitor Apple crash and hang reports, Sentry production issues, and customer feedback; fix release blockers before shipping new features.
