# SonaPin - Your Fursona, Ready to Share

SonaPin turns your iPhone into an interactive digital badge for your fursona.
Create a profile, add a compatible VRM avatar, and share your badge in person.
Make every hello a little more memorable.

## Features

- **A badge that feels like you:** Add your name, pronouns, species, tagline,
  and the link behind your QR code.
- **Bring your avatar:** Import compatible `.vrm` files from the Files app, or
  start with the built-in demo wolf.
- **Make it interactive:** Tap and move your avatar to see it react.
- **Share in person:** Show a high-contrast QR code linked to your profile.
- **Make it comfortable:** Adjust motion, haptics, contrast, and screen-awake
  behavior.
- **Keep control of your profile:** Badge and profile data stay on your device;
  delete local data from Settings whenever you want.

## Getting Started

See the [project documentation](docs/) for release, privacy, and support
information.

1. Install Xcode and Bun using the prerequisites below.
2. Clone this repository and run `bun install` from the project root.
3. Run `make project` to generate the Xcode project.
4. Run `make resolve`, then `make sim` to build and launch the iOS app.

## Usage

Create your badge in the app, then show the QR code when you meet someone.
The app stores badge details on your device. Sentry-enabled builds also send
limited crash and performance diagnostics to help maintain the app; see the
[privacy policy](https://mrdemonwolf.github.io/sonapin/privacy/) for details.

SonaPin is released as source and is available to testers through TestFlight.
The public App Store listing is not live yet.

## Tech Stack

| Layer | Technology |
| --- | --- |
| App | Swift 6, SwiftUI, UIKit, RealityKit, Core Image |
| Avatar import | VRMKit, VRMRealityKit |
| Diagnostics | Sentry Cocoa |
| Project generation | XcodeGen |
| Documentation site | TypeScript, Bun, static HTML and CSS |
| End-to-end tests | Playwright |

## Development

### Prerequisites

- macOS with Xcode 26.6 or newer
- Bun 1.4.2 or newer
- XcodeGen

### Setup

```sh
bun install
make project
make resolve
```

### Development Scripts

| Command | Purpose |
| --- | --- |
| `make sim` | Build and launch SonaPin in the default simulator |
| `make build` | Build the iOS app for the simulator |
| `make test` | Run native unit tests |
| `make ui-test` | Run native UI tests |
| `bun run build` | Build the documentation site |
| `bun run test:e2e` | Run documentation end-to-end tests |

See `make help` for the other project, archive, export, lint, and cleanup tasks.

### Code Quality

Pull requests to `main` require the E2E and native iOS workflow checks. The
repository ruleset also requires linear history and resolved review threads.

## Project Structure

```text
apps/
  native/          iOS app, unit tests, and UI tests
  docs/            Product landing page and support pages
assets/            App and documentation assets
docs/              Project, privacy, and release documentation
scripts/           Build and release helpers
tests/e2e/         Playwright end-to-end tests
.github/workflows/ Continuous integration
```

## License

[![License](https://img.shields.io/github/license/mrdemonwolf/sonapin.svg?style=for-the-badge&logo=github)](LICENSE)

SonaPin is licensed under the GNU General Public License v3.0 or later.
Third-party license details are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Contact

- Support: [SonaPin Support](https://mrdemonwolf.github.io/sonapin/support/)
- Bugs and suggestions: [GitHub Issues](https://github.com/MrDemonWolf/sonapin/issues)
- Community: [Join my server](https://mrdwolf.net/discord)

Made with love by [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)
