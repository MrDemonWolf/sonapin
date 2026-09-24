# SonaPin 1.0 release checklist

SonaPin is a released open-source iOS project with a TestFlight build. Public App Store distribution is a separate gate. This list records verified work as of 2026-09-24.

## Product

- [x] Swift 6 and SwiftUI app targets iOS 18 and later.
- [x] Built-in demo avatar, badge profile, QR code, VRM import, and local settings are implemented.
- [x] Local profile and avatar storage; no account, tracking, analytics, or backend.
- [x] Public website includes product, support, privacy, terms, and acknowledgments pages.
- [x] Source app and website use version 1.0.0 release copy.

## Automated checks

- [x] Xcode 27 Simulator build and lint gate pass.
- [x] Swift suite passes: 34 tests across 6 suites, including local VRM fixture checks.
- [x] iOS end-to-end suite passes: 6 UI tests on iPhone 18 Pro Simulator / iOS 27.
- [x] Website end-to-end suite passes: 4 desktop and mobile Playwright checks.
- [x] GitHub main ruleset requires native and browser checks. Administrator bypass remains available.

## TestFlight gate

- [x] Xcode 27 exported version 1.0.0 build 8 as an App Store Connect IPA; store profile and privacy manifest inspected.
- [x] Confirm App Store Connect app record and bundle ID; version 1.0 is Prepare for Submission.
- [x] Confirm the 4+ age rating and the build 1 assignment to the Private Beta internal group.
- [ ] Revise App Privacy for the Sentry-enabled build, publish the updated privacy policy, complete Content Rights, and add review contact details.
- [ ] Complete every physical-iPhone check in [DEVICE_TEST_CHECKLIST.md](DEVICE_TEST_CHECKLIST.md).
- [x] Deployed support and privacy URLs opened successfully on 2026-09-22.
- [x] Confirm an installed TestFlight build: 1.0.0 build 1 is testing in the Private Beta group.
- [x] Upload five iPhone screenshots and save updated App Store listing copy.
- [x] Upload the 13-inch iPad screenshot.

Simulator results do not clear the physical-device or App Store Connect gates.
