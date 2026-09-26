# SonaPin 1.0 release checklist

SonaPin is a released open-source iOS project with a TestFlight build. Public App Store distribution is a separate gate. This list records verified work as of 2026-09-26.

## Product

- [x] Swift 6 and SwiftUI app targets iOS 18 and later.
- [x] Built-in demo avatar, badge profile, QR code, VRM import, and local settings are implemented.
- [x] Profile and avatar content stay on-device; no account, ads, product analytics, or tracking. Sentry-enabled builds send limited diagnostics for app functionality.
- [x] Public website includes product, support, privacy, terms, and acknowledgments pages.
- [x] Source app and website use version 1.0.0 release copy.

## Automated checks

- [x] Active `Solo Main Protection` ruleset requires `E2E / Verify` and `Xcode 26.6 / macOS 26`; strict status checks are enabled and no bypass actors are configured.
- [x] PR head `9dd628c`: `E2E / Verify` passed on workflow run `36223471233`.
- [x] PR head `9dd628c`: Native lint, Simulator build, unit tests, and UI tests passed on workflow run `36223471259`.

## Sentry

- [x] Sentry Cocoa 9.29.0 is integrated with PII, screenshots, view hierarchy, breadcrumbs, session tracking, and network capture disabled.
- [x] A debug simulator smoke event reached the `sonapin` Sentry project. This verifies delivery only.
- [x] A recent long hang was traced to SonaPin Dev on a GitHub Actions simulator; Sentry reports its `SonaPin.debug.dylib` symbols are missing.
- [x] Debug builds now tag events as `development`; Release builds tag events as `production`.
- [x] Verified a fresh debug smoke event arrived with the `development` environment.
- [x] Built a matching Debug simulator dSYM for `SonaPin.debug.dylib` (UUID `5FE2D638-9AC8-3A85-92B7-20A0C50786E2`); uploading it to Sentry remains open.
- [ ] Build a fresh release archive, upload its matching dSYM, and verify readable app frames.
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

Simulator results do not clear the physical-device or App Store Connect gates.

## Public release monitoring

- [ ] After public release, monitor Apple crash and hang reports, Sentry production issues, and customer feedback; fix release blockers before shipping new features.
