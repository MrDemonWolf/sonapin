# SonaPin

SonaPin is a local-first native iOS badge for sharing a fursona, profile, and QR code at conventions.

## Repository

- `apps/native` — Swift 6, SwiftUI, RealityKit, and VRMKit iOS app
- `apps/docs` — dependency-light TypeScript static site for GitHub Pages
- `docs` — research, privacy, review, and device-test notes
- `assets/brand` — source brand artwork and Icon Composer layers

## Requirements

- macOS 26.4 or later
- Xcode 26.6
- XcodeGen 2.46 or later
- Bun 1.4 or later
- SwiftLint is optional

Xcode 26 is required because the app icon uses Apple’s Icon Composer format.

## Commands

```sh
make project
make build
make test
make ui-test
make sim
make docs-build
```

`make sim` discovers a suitable installed iPhone Simulator, builds and launches SonaPin, then writes local evidence under `artifacts/`.

## Privacy

Version 1 has no account, tracking, ads, analytics, payments, or backend. Profile data and imported VRM files stay inside the app container.

VRM rendering uses VRMKit 0.10.0. RealityKit support is experimental, so compatibility is reported per imported model rather than claimed universally.

