# SonaPin Native

Native iOS 18 app built with Swift 6, SwiftUI, RealityKit, Core Image, Swift Testing, and VRMKit 0.10.0.

## Generate and verify

Run from the repository root:

```sh
make project
make build
make test
make ui-test
make sim
```

The generated project is `apps/native/SonaPin.xcodeproj`; the shared scheme is `SonaPin`; the bundle identifier is `com.mrdemonwolf.sonapin`.

## Test launch arguments

- `--ui-testing` enables deterministic automation behavior.
- `--reset-app-state` removes persisted test state.
- `--use-demo-avatar` selects the built-in procedural avatar.

## Local data

Profile and onboarding state are stored as a versioned JSON snapshot. Imported models are validated and copied into Application Support before replacing the active avatar. No imported content is uploaded.

Simulator evidence covers build, launch, UI automation, and screenshots. Real VRM appearance, haptics, camera QR scanning, thermal behavior, and Instruments runs remain physical-iPhone checks; see `docs/DEVICE_TEST_CHECKLIST.md`.
