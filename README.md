# SonaPin

**Your sona. Your badge. Alive.**

SonaPin is a released open-source iPhone and iPad app project that turns your device into an interactive fursona badge. Show a 3D avatar, your name and pronouns, and a scannable QR link at conventions and meetups. Your profile and imported avatar stay on your device.

![SonaPin badge mark](assets/brand/sonapin-badge.svg)

## What you can do

- Start with the built-in demo wolf or import a compatible VRM avatar from Files.
- Tap and move the avatar to trigger reactions.
- Add a display name, pronouns, species, tagline, and QR destination.
- Show a high-contrast QR code in badge mode.
- Adjust motion, haptics, contrast, and screen-awake behavior.
- Delete all locally stored profile and avatar data from Settings.

No account, ads, product analytics, tracking, or backend. Newer builds send limited crash and hang diagnostics to Sentry; badge data stays on your device.

## Get SonaPin

The source release is available here, and a 1.0.0 build has already reached TestFlight. A public App Store link is not available yet. See the [release guide](apps/native/RELEASING.md) for the current distribution status.

The [App Store listing copy and screenshots](docs/APP_STORE_LISTING.md) are in this repository.

## Run it locally

Requires macOS, Xcode 26 or newer, XcodeGen, and Bun. The app targets iOS 18 or newer.

```sh
bun install
make project
make sim
```

To build the website locally:

```sh
bun run build:docs
python3 -m http.server 4173 --directory apps/docs/dist
```

## Test

```sh
make lint-check  # Swift checks and Simulator build
make test        # Swift unit tests
make ui-test     # iOS end-to-end UI tests
bun run test:e2e # Website end-to-end browser tests
```

GitHub Actions runs native build, lint, unit and UI tests, plus browser tests on every pull request to `main`. The website deploys from `main` after its build. The [main ruleset](https://github.com/MrDemonWolf/sonapin/rules/23802636) requires both `Xcode 26.6 / macOS 26` and `E2E / Verify` before merging. Repository administrators retain an emergency bypass.

## Release state

| Area | State |
| --- | --- |
| Source app | Released as version 1.0.0 |
| Website | Public landing and support pages in this repository |
| Automated checks | Simulator build, Swift tests, iOS UI tests, browser tests |
| TestFlight | 1.0.0 build 1 is testing in the Private Beta group and installed on an iPhone 14 Pro Max; physical-device sign-off is still open |
| App Store | Version 1.0 is Prepare for Submission; five iPhone screenshots, one iPad screenshot, listing copy, and a 4+ age rating are saved |

See the [device release gate](docs/DEVICE_TEST_CHECKLIST.md) and [App Review notes](docs/APP_REVIEW_NOTES.md). Simulator tests cannot confirm real-world VRM rendering, haptics, QR scanning, battery use, or signing.

## Project layout

| Path | Purpose |
| --- | --- |
| [apps/native](apps/native/) | Swift 6, SwiftUI, RealityKit, VRMKit, and iOS tests |
| [apps/docs](apps/docs/) | Static TypeScript, HTML, and CSS website |
| [tests/e2e](tests/e2e/) | Playwright website tests |
| [docs](docs/) | App Store, privacy, review, and device checklists |
| [.github/workflows](.github/workflows/) | Pull request checks and Pages deployment |

VRMKit is pinned to 0.10.0 and Sentry to 9.29.0. Imported files are checked before the active avatar is replaced. The app is licensed under [GPL-3.0-or-later](LICENSE); dependency notices are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Support

Use the [support page](https://mrdemonwolf.github.io/sonapin/support/) or open a [GitHub issue](https://github.com/MrDemonWolf/sonapin/issues). Built by [MrDemonWolf, Inc.](https://www.mrdemonwolf.com).
