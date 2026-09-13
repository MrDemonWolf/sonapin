# Engineering decisions

## 1. Product layout

Decision: keep runnable products under `apps/`: `apps/native` for iOS and `apps/docs` for the public GitHub Pages site. Keep internal engineering records in root `docs/`.

Reason: this follows the Better-T Stack monorepo convention while keeping public copy separate from build and research records.

## 2. Native platform

Decision: build with Swift 6, SwiftUI, Observation, and RealityKit, with iOS 18.0 as the minimum.

Reason: iOS 18 is the first iOS release for `RealityView` and entity-targeted SwiftUI gestures. Native frameworks provide accessibility, lifecycle integration, document import, QR rendering, and Simulator automation without a cross-platform bridge.

## 3. Local-first data boundary

Decision: version 1 has no account, backend, analytics, ads, tracking, uploads, public gallery, feed, comments, or background networking.

Reason: a convention badge must work offline and imported avatars may carry sensitive identity and licensing metadata. Local storage narrows both failure and privacy exposure.

## 4. VRM adapter boundary

Decision: pin VRMKit to exact version 0.10.0 and isolate it behind SonaPin-owned import, compatibility-report, and renderer interfaces.

Reason: the library calls RealityKit rendering experimental and documents a finite renderer envelope. The adapter prevents dependency types from leaking throughout the UI and keeps replacement possible.

Fallback: the procedural demo avatar remains fully usable without VRMKit or an imported file. SonaPin does not claim support for every VRM.

## 5. Safe file import

Decision: use SwiftUI `fileImporter`, balance security-scoped access, validate the candidate, copy it into Application Support, and replace the managed avatar only after validation succeeds.

Reason: imported URLs are security scoped and may become unavailable. Transactional replacement prevents a bad file from destroying the last working avatar.

## 6. State and concurrency

Decision: keep view-facing mutable state on `@MainActor`; perform file I/O, hashing, parsing, and report construction in structured asynchronous work with explicit cancellation.

Reason: this protects UI isolation without blocking the main actor. Unstructured detached tasks are unnecessary for the current scope.

## 7. Deterministic QR output

Decision: use Core Image's QR generator, default to correction level M, add a four-module quiet zone, and scale by whole-number nearest-neighbor multiples.

Reason: deterministic modules and a real quiet zone improve scanner reliability. A large accessible preview and high-contrast mode make the badge useful in varied environments.

## 8. Persistence

Decision: persist small settings and profile values locally and keep imported model bytes in Application Support. Never log user QR payloads or local paths in production.

Reason: this matches the local-only privacy promise and separates structured preferences from large user files.

## 9. Test split

Decision: use Swift Testing for unit and integration coverage and XCTest/XCUIAutomation for UI flows. Keep physical-device-only checks in a separate release checklist.

Reason: Simulator tests are repeatable in CI, but cannot establish camera scanning, haptics, material fidelity, thermals, or real-device memory behavior.

## 10. CI compatibility range

Decision: test the shared `SonaPin` scheme on GitHub's pinned `macos-26` image with Xcode 26.6.

Reason: the final app icon is an Xcode 26 Icon Composer `.icon` document with a Liquid Glass treatment. Xcode 16.4 predates that asset format and is not an honest supported build lane. Pinning the current runner avoids the moving `macos-latest` alias. Simulator builds disable signing and require no secrets.

## 11. Public documentation publishing

Decision: build `apps/docs` and deploy its artifact with GitHub Actions.

Reason: GitHub Pages branch publishing cannot select `apps/docs`; it only supports the repository root or `/docs`.
