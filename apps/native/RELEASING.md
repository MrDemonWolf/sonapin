# SonaPin iOS release guide

SonaPin 1.0 is released as an open-source app project. TestFlight distribution uses local Xcode archives and Apple's Transporter app, matching the ConPaws release path. Builds use bundle identifier `com.mrdemonwolf.sonapin` and Apple team `HBB7T99U79`.

On 2026-09-22, Xcode 27 exported a 7.1 MB App Store Connect IPA for version 1.0.0, build 8. Its embedded store provisioning profile has `get-task-allow = false`, and the privacy manifest is present. Upload and App Store Connect processing have not been verified.

## One-time App Store Connect setup

- App name: `SonaPin`
- Primary language: `English (U.S.)`
- Bundle ID: `com.mrdemonwolf.sonapin`
- SKU: `sonapin-ios`
- User access: Full Access
- Internal TestFlight group: `SonaPin Internal`
- Feedback email: `hello@mrdemonwolf.com`

Use the listing, beta copy, URLs, and screenshot plan in `../../docs/APP_STORE_LISTING.md`. Use the reviewer walkthrough in `../../docs/APP_REVIEW_NOTES.md`.

## Build and upload

1. Start from a clean commit that passed CI.
2. Confirm `MARKETING_VERSION` in `project.yml`. The Xcode scheme increments `CURRENT_PROJECT_VERSION` in `BuildNumber.xcconfig` before compiling, whether launched from Xcode or the repository commands. Commit the changed build number with the release. Never reuse an uploaded build number.
3. Run `make export` from the repository root.
4. Confirm `artifacts/release/export/SonaPin.ipa` exists.
5. Open Transporter, sign in with an App Store Connect account, add the IPA, and select Deliver.
6. Wait for processing, then confirm the build appears in `SonaPin Internal` in TestFlight.

The first archive may ask Xcode to create or download an Apple Distribution certificate and provisioning profile. Signing credentials stay in the developer account and Keychain; never commit certificates, profiles, API keys, or passwords.

## Before external testing

- Complete the App Privacy questionnaire from the shipped behavior and `SonaPin/Resources/PrivacyInfo.xcprivacy`.
- Complete the age-rating questionnaire from the shipped content.
- Add the beta description, feedback email, and What to Test copy from `../../docs/APP_STORE_LISTING.md`.
- Verify the support and privacy URLs are live.
- Finish the physical-device checklist in `../../docs/DEVICE_TEST_CHECKLIST.md`.
- Submit the first external build for Beta App Review.

Internal testing supports up to 100 App Store Connect users without Beta App Review. External testing supports up to 10,000 testers and may require review for the first build. Builds expire after 90 days.
