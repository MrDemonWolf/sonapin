# SonaPin iOS release guide

SonaPin 1.0 is released as an open-source app project. TestFlight distribution uses local Xcode archives and Apple's Transporter app, matching the ConPaws release path. Builds use bundle identifier `com.mrdemonwolf.sonapin` and Apple team `HBB7T99U79`.

Debug builds install as **SonaPin Dev** with bundle ID `com.mrdemonwolf.sonapin.dev` and an IconWolf-generated DEV icon. Release archives keep the original SonaPin icon and `com.mrdemonwolf.sonapin` bundle ID. TestFlight and the public App Store app therefore share one installation, while the development app can sit beside them.

On 2026-09-22, Xcode 27 exported a 7.1 MB App Store Connect IPA for version 1.0.0, build 8. Its embedded store provisioning profile has `get-task-allow = false`, and the privacy manifest is present. App Store Connect shows version 1.0.0 build 1 testing in the Private Beta group, installed on an iPhone 14 Pro Max on 2026-09-22.

## One-time App Store Connect setup

- App name: `SonaPin`
- Primary language: `English (U.S.)`
- Bundle ID: `com.mrdemonwolf.sonapin`
- SKU: `MDW-SonaPin`
- User access: Full Access
- Internal TestFlight group observed: `PB Private Beta`
- Feedback email: Not set as of 2026-09-24

Use the listing, beta copy, URLs, and screenshot plan in `../../docs/APP_STORE_LISTING.md`. Use the reviewer walkthrough in `../../docs/APP_REVIEW_NOTES.md`.

## Build and upload

1. Start from a clean commit that passed CI.
2. Confirm `MARKETING_VERSION` in `project.yml`. The Xcode scheme increments `CURRENT_PROJECT_VERSION` in `BuildNumber.xcconfig` before compiling, whether launched from Xcode or the repository commands. Commit the changed build number with the release. Never reuse an uploaded build number.
3. Run `make export` from the repository root.
4. Confirm `artifacts/release/export/SonaPin.ipa` exists.
5. Open Transporter, sign in with an App Store Connect account, add the IPA, and select Deliver.
6. Wait for processing, then confirm the build appears in `PB Private Beta` in TestFlight. Use a unique build number higher than the last uploaded build, 1.

The first archive may ask Xcode to create or download an Apple Distribution certificate and provisioning profile. Signing credentials stay in the developer account and Keychain; never commit certificates, profiles, API keys, or passwords.

## Before external testing

- Complete the App Privacy questionnaire from the shipped behavior and `SonaPin/Resources/PrivacyInfo.xcprivacy`.
- Recheck the saved 4+ age rating if shipped content changes.
- Add the beta description, feedback email, and What to Test copy from `../../docs/APP_STORE_LISTING.md`.
- Verify the support and privacy URLs are live.
- Finish the physical-device checklist in `../../docs/DEVICE_TEST_CHECKLIST.md`.
- Submit the first external build for Beta App Review.

Internal testing supports up to 100 App Store Connect users without Beta App Review. External testing supports up to 10,000 testers and may require review for the first build. Builds expire after 90 days.

## Crash reports

The Private Beta group has tester feedback enabled. TestFlight testers automatically share crash reports with the developer; check **TestFlight → Feedback → Crashes** and **Xcode → Organizer → Crashes**. On 2026-09-24, App Store Connect showed no crash feedback for the installed build. Apple App Analytics can show production crash rates, while detailed App Store crash reports depend on users sharing diagnostics. Keep the matching Xcode archive and symbols for each distributed build.

The already-distributed TestFlight build 1 uses Apple's reports only. The next build adds Sentry 9.29.0 for crash and hang diagnostics. Sentry is configured without screenshots, session replay, automatic breadcrumbs, session tracking, metrics, or default personal identifiers. On 2026-09-26, a debug simulator launch with `-SonaPinSentrySmokeTest` produced a “SonaPin Sentry smoke test” event in the `sonapin` project. This confirms event delivery, not crash symbolication. A recent 165-second App Hang event came from SonaPin Dev build 21 on an iPhone 17 Pro simulator running on a GitHub Actions runner. Sentry reported that the matching `SonaPin.debug.dylib` debug information file was missing, so its app frames could not be symbolicated. The feed groups several app-hang durations across builds and simulator versions; sample real TestFlight device events before treating the group as a production blocker or dismissing it as test noise. Debug builds now use Sentry's `development` environment, while release builds use `production`, so new simulator traffic is separated from production events.

The pinned Sentry 9.29.0 privacy manifest lists Crash Data, Performance Data, and Other Diagnostic Data. It marks each for App Functionality, not linked to the user, and not used for tracking. Confirm those declarations against the final archive's privacy report and event payload. Before distributing a Sentry-enabled build, replace the draft “Data Not Collected” App Privacy response with the matching disclosures and keep the published privacy policy aligned. Create a fresh archive after CI passes, upload that archive's matching dSYM files in Sentry's project settings, and verify a crash event resolves to readable app source lines. Do not rely on the older archives: they predate the Sentry integration.
