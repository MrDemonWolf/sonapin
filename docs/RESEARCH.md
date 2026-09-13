# SonaPin research

Research checked on 2026-09-12. This document records the evidence behind the native iOS implementation. It is not a claim that every device or model has been tested.

## Platform APIs

### RealityKit and SwiftUI

- `RealityView` is available on iOS 18.0 and later. Apple also demonstrates `RealityView` on iOS, iPadOS, and macOS in its cross-platform RealityKit session. Sources: [RealityView](https://developer.apple.com/documentation/realitykit/realityview), [Build a spatial drawing app with RealityKit](https://developer.apple.com/videos/play/wwdc2024/10103/).
- SwiftUI's entity-targeted gestures are available on iOS 18.0 and later. A target entity needs both collision geometry and an input target before it can receive gestures. Apple's sample combines drag, magnify, and rotation gestures with `simultaneousGesture`. Sources: [targetedToAnyEntity](https://developer.apple.com/documentation/swiftui/gesture/targetedtoanyentity%28%29), [Transforming RealityKit entities with gestures](https://developer.apple.com/documentation/realitykit/transforming-realitykit-entities-with-gestures).
- Gesture values are measured from the start of the current gesture. Store the starting transform and apply each delta against that baseline instead of repeatedly accumulating the full delta.

### File import

- SwiftUI's `fileImporter` returns security-scoped URLs. Access must begin with `startAccessingSecurityScopedResource()` and be balanced with `stopAccessingSecurityScopedResource()`, normally through `defer`. Source: [fileImporter](https://developer.apple.com/documentation/swiftui/view/fileimporter%28ispresented%3Aallowedcontenttypes%3Aoncompletion%3A%29).
- SonaPin should validate and copy an accepted VRM into Application Support while security-scoped access is active. A security-scoped bookmark is unnecessary when the app immediately creates its own local copy.
- Replacing an avatar should be transactional: validate the candidate first, then atomically replace the managed copy. A failed import must leave the last working avatar intact.

### QR generation

- Core Image provides `CIQRCodeGenerator` with a `Data` message and error-correction levels L, M, Q, and H. Apple documents M as the default. Sources: [CIQRCodeGenerator](https://developer.apple.com/documentation/coreimage/ciqrcodegenerator), [QR code generator filter](https://developer.apple.com/documentation/coreimage/cifilter-swift.class/qrcodegenerator%28%29), [Core Image Filter Reference](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/).
- DENSO states that a QR code needs a four-module quiet zone. M is a practical default; stronger correction increases symbol size. Scale modules by an integer with nearest-neighbor filtering and preserve high contrast. Sources: [QR code capacity](https://www.qrcode.com/en/howto/code.html), [Error correction](https://www.qrcode.com/en/about/error_correction.html).
- Simulator rendering is not proof that a code scans. Scanning from a second physical phone remains a release gate.

### Testing

- Apple recommends Swift Testing for new unit and integration tests in Xcode 16 and XCTest/XCUIAutomation for UI tests. Swift Testing tests use `@Test`, `#expect`, and `#require`, and may run in parallel. Sources: [Adding tests to your Xcode project](https://developer.apple.com/documentation/xcode/adding-tests-to-your-xcode-project), [Swift Testing](https://developer.apple.com/documentation/testing), [XCUIAutomation](https://developer.apple.com/documentation/xcuiautomation).
- Swift Testing and XCTest can coexist in one test target, but one test should not mix the two APIs.

## VRM support

### Dependency selection

- The selected dependency is [VRMKit 0.10.0](https://github.com/tattn/VRMKit/releases/tag/0.10.0), released 2026-08-28 and pinned exactly for reproducible builds.
- Its package declares Swift tools 6.0 and supports iOS 15, macOS 12, watchOS 8, and visionOS 2. It publishes `VRMKit` and `VRMRealityKit`. Source: [Package.swift at 0.10.0](https://github.com/tattn/VRMKit/blob/0.10.0/Package.swift).
- VRMKit is MIT licensed. The required notice is reproduced in `THIRD_PARTY_NOTICES.md`. Source: [VRMKit license](https://github.com/tattn/VRMKit/blob/0.10.0/LICENSE).
- The project calls RealityKit rendering experimental. The app therefore keeps parsing and rendering behind an adapter and always retains a procedural demo avatar. Source: [VRMKit README](https://github.com/tattn/VRMKit/tree/0.10.0).

### Known renderer envelope

VRMKit 0.10.0 documents these limits:

- Only triangle primitives render; point and line primitives are skipped.
- `COLOR_0` is ignored.
- One UV set and one `KHR_texture_transform` per material are supported.
- Generated tangents are not MikkTSpace.
- Morph targets support `POSITION`, not `NORMAL` or `TANGENT`.
- Skinning supports `JOINTS_0` and `WEIGHTS_0`, with at most four influences.
- MToon `renderQueueOffsetNumber` is ignored, and some outline behavior is approximated.

These are compatibility boundaries, not permission to accept corrupt or unsupported models. The app should report warnings and keep the prior working avatar.

### Metadata and permissions

- VRM 0.x metadata contains creator, reference, usage, redistribution, and license fields, including the schema's historical `violentUssageName`, `sexualUssageName`, and `commercialUssageName` spellings. Source: [VRM 0.x metadata schema](https://github.com/vrm-c/vrm-specification/blob/master/specification/0.0/schema/vrm.meta.schema.json).
- VRM 1.0 requires `name`, `authors`, and `licenseUrl` and defines avatar permission, commercial use, violence, sexual use, political or religious use, hate use, credit, redistribution, and modification settings. Source: [VRM 1.0 metadata](https://github.com/vrm-c/vrm-specification/blob/master/specification/VRMC_vrm-1.0/meta.md).
- Missing permission metadata must remain unspecified. SonaPin must never turn absence into permission. Display raw values and a normalized explanation where possible.

## Privacy and review

- A privacy manifest is named `PrivacyInfo.xcprivacy` and declares tracking, tracking domains, collected data, and required-reason API use. Source: [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).
- Apple defines collected data as data transmitted off-device and retained beyond servicing a real-time request. SonaPin version 1 is local-only, so its imported models, profile, and QR settings are not collected by the developer. Source: [App privacy details](https://developer.apple.com/app-store/app-privacy-details/).
- Required-reason APIs must be declared when used. For example, CA92.1 covers app-only `UserDefaults`; file timestamp reasons depend on whether the file is in the app container or was explicitly granted by the user. Sources: [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), [NSPrivacyAccessedAPIType](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
- App Store Connect requires a public privacy-policy URL for iOS apps. Source: [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy).
- App Review guideline 4.2 requires lasting entertainment value or adequate utility. The procedural demo, editable badge, interactive avatar, offline QR, settings, and compatibility report together provide the reviewable product; merely displaying a model would be weak. Guideline 5.2 requires rights to imported content, and 5.1.1 requires privacy disclosures. Source: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (updated 2026-06-08).

## CI environment

- GitHub's macOS 15 Arm64 image currently includes Xcode 16.4 at `/Applications/Xcode_16.4.app`, with the iOS 18.5 SDK and iOS simulator runtimes. Source: [macOS 15 Arm64 image](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md).
- GitHub's macOS 26 Arm64 image currently includes Xcode 26.6 at `/Applications/Xcode_26.6.app`. Source: [macOS 26 Arm64 image](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md).
- `macos-latest` can move to a newer image. The native workflow uses the explicit `macos-26` label and prints tool versions. Xcode 26.6 is required because the final app icon is an Icon Composer `.icon` document; Xcode 16.4 is retained here only as compatibility research, not as a supported build lane. Source: [GitHub Actions runner images](https://github.com/actions/runner-images).

## Repository and Pages layout

- Better-T Stack's documented shape uses `apps/*` for runnable applications and `packages/*` for shared code. SonaPin follows that convention with the native product in `apps/native` and the public site in `apps/docs`. Source: [Better-T Stack project structure](https://www.better-t-stack.dev/docs/project-structure).
- GitHub Pages' branch publishing supports only the repository root or `/docs`. Publishing a built site from `apps/docs` therefore needs a custom Actions workflow that uploads the build artifact. Sources: [Configure a Pages publishing source](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site), [Custom GitHub Pages workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).

## Open questions before release

- Test the owner's real VRM on a physical iPhone and record the exact compatibility envelope.
- Generate an archive privacy report and reconcile it with the app and every dependency.
- Recheck GitHub runner image inventories when upgrading Xcode or the deployment target.
- Recheck App Review rules immediately before submission.
