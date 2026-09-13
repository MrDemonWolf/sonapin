# SonaPin — Native iOS Master Build Brief

> **Purpose:** This file is the single source of truth for researching, designing, implementing, testing, running, and preparing the first public iOS release of SonaPin.
>
> **Execution instruction:** Work through this document from top to bottom. Do not stop after scaffolding. Continue until the app builds, unit and UI tests pass, the app launches in an iOS Simulator, and the required evidence and documentation are committed. When something cannot be validated in Simulator, finish everything else and create an exact physical-device test checklist instead of pretending it was verified.

---

## 1. Product identity

Use these working identifiers unless an existing project already has production identifiers that must be preserved:

- **Product name:** SonaPin
- **App Store display name:** `SonaPin`
- **App Store subtitle:** `Interactive Fursona Badge`
- **Tagline:** `Your sona. Your badge. Alive.`
- **Repository:** `sonapin-ios`
- **Xcode project:** `SonaPin.xcodeproj`
- **Primary scheme:** `SonaPin`
- **Bundle identifier:** `com.mrdemonwolf.sonapin`
- **Organization:** MrDemonWolf
- **Distribution goal:** Public App Store app
- **Privacy model:** Local-first; no account, backend, analytics, advertising, or tracking in version 1

The name is a working product name, not a legal clearance result. Do not block engineering on formal trademark work, but create `docs/NAME_RESEARCH.md` containing a preliminary exact-name search across the App Store, general web results, GitHub, domain availability, and the United States trademark database. Clearly state that this is not legal advice.

If the repository still contains the old working name `BoopBadge`, migrate it cleanly to `SonaPin` and remove stale product names, bundle identifiers, schemes, asset names, documentation, and tests. Preserve useful code and Git history.

---

## 2. Truth-first engineering decision

This app should be native iOS because most of its product experience is naturally served by SwiftUI, RealityKit, Core Image, the document picker, native haptics, accessibility APIs, and App Store distribution.

Do **not** assume that native automatically means faster than Unity. The largest technical risk is VRM compatibility through a third-party renderer, not SwiftUI itself. Treat VRM rendering as a measurable technical spike and keep the dependency behind a narrow boundary so it can be replaced without rewriting the app.

The current market already includes at least one furry social-network app that advertises a profile, QR code, and digital convention badge. SonaPin must not imitate that product or become another social feed. Its clear differentiation is: **native interactive 3D VRM avatars, touch reactions, local-only data, no account, no network, and a purpose-built badge experience**. Verify the current competitor landscape during the research phase and record the distinction in the product documentation.

The native direction passes when:

1. A real `.vrm` file imports safely.
2. The model renders with acceptable materials.
3. Expressions can be triggered.
4. Spring bones update correctly when present.
5. Basic animation works.
6. Look-at behavior works when supported.
7. Model loading failures are recoverable.
8. The user can always return to the built-in demo avatar.
9. The app remains responsive while loading and interacting.
10. Physical-device profiling shows acceptable memory, thermal, and frame behavior.

Simulator success is required for app-level smoke testing, but it is not proof of GPU performance or thermal behavior.

---

## 3. Non-negotiable platform requirements

- **Minimum deployment target:** iOS 18.0
- Build with the current stable iOS SDK installed on the Mac.
- iOS 18 is the release immediately preceding Apple’s iOS 26 naming generation; do not set a fictional iOS 25 deployment target.
- The app must run on iOS 18 without relying on iOS 26-only behavior.
- iOS 26-or-newer APIs are allowed only behind `#available(iOS 26, *)` with a real iOS 18 fallback.
- Do not adopt Liquid Glass unless the product owner explicitly requests it later.
- Target iPhone first in portrait orientation. Keep layouts adaptable enough not to break on iPad, but do not add a separate iPad-specific product scope during the first build.
- Use Swift 6 language mode and complete strict-concurrency checking.
- Do not weaken concurrency settings to silence diagnostics.
- Do not use `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency`, or detached tasks unless a documented safety invariant proves they are necessary. Prefer not to use them at all.

---

## 4. Required installed skills

Before editing code, discover the installed skills and read every Swift or iOS skill whose description applies.

At minimum, use:

1. `swiftui-expert/swiftui-expert-skill`
   - Read `skill.md`.
   - Read `references/latest-apis.md` first.
   - Also consult state management, view structure, performance, accessibility, layout, navigation, animation, previews, localization, and trace recording/analysis references when applicable.

2. `swift-concurrency/swift-concurrency`
   - Read `skill.md`.
   - Inspect the generated `.pbxproj` or `project.yml` before giving concurrency-sensitive guidance.
   - Consult actors, Sendable, observation, tasks, testing, performance, and memory-management references when applicable.

3. Any installed iOS, Xcode, simulator, build/run/debug, testing, RealityKit, or profiling skill that applies.

Do not blindly apply macOS-only AppKit or window-management advice to this iOS project. Reuse only genuinely cross-platform shell/build practices.

Record the skills actually used in `docs/ENGINEERING_DECISIONS.md`.

---

## 5. Research gate

Research current primary sources before choosing APIs or dependency versions. Prefer official Apple documentation, official Swift documentation, package source repositories, package release notes, and the VRM specification. Avoid blog posts when a primary source exists.

Research and record:

- Installed macOS and Xcode versions.
- Installed iOS Simulator runtimes and available iPhone devices.
- Current Xcode deployment-target support for iOS 18.
- Current SwiftUI APIs for iOS 18.
- `RealityView` and current RealityKit interaction APIs.
- Current file-import and security-scoped resource requirements.
- Current Core Image QR-code generation behavior.
- Current Swift Testing and XCUITest recommendations.
- Current privacy-manifest requirements.
- Current App Store Review requirements relevant to imported user models and minimum functionality.
- The latest stable VRMKit release, its exact tag, license, supported platforms, RealityKit limitations, open issues relevant to iOS, and whether the RealityKit renderer is still marked experimental.
- The VRM 0.x and VRM 1.0 metadata and license fields needed for an import report.

Run and save the output of:

```bash
sw_vers
xcodebuild -version
xcode-select -p
swift --version
xcrun simctl list runtimes
xcrun simctl list devices available
```

Summarize findings in `docs/RESEARCH.md` with source names and retrieval dates. Do not copy large copyrighted passages.

---

## 6. Dependency policy

Production dependencies should be minimal.

Expected production dependency:

- `VRMKit`, including its RealityKit product, through Swift Package Manager.

Rules:

- Verify the latest stable release first.
- Pin an exact stable tag or exact version after validation.
- Never track `main`, `master`, or an unpinned branch in production.
- Commit `Package.resolved`.
- Record the package license in `THIRD_PARTY_NOTICES.md`.
- Keep every direct VRMKit reference inside the Avatar feature/infrastructure boundary.
- Do not introduce another rendering engine during the initial native spike.
- Do not add networking, analytics, crash-reporting, authentication, cloud storage, or UI-framework dependencies.

Development tooling may use XcodeGen if the repository starts without a viable Xcode project. If used:

- Install with Homebrew only when absent.
- Keep a human-readable `project.yml` as the source of truth.
- Generate a shared scheme.
- Never hand-edit generated project content unless unavoidable.
- Add a `make project` target.

If an existing healthy Xcode project is present, do not replace it merely to use XcodeGen.

---

## 7. Project configuration

Configure and then verify the actual generated settings:

- Product name: `SonaPin`
- Bundle ID: `com.mrdemonwolf.sonapin`
- Deployment target: `18.0`
- Swift language mode: Swift 6
- Strict concurrency: complete
- Automatic signing enabled for local device builds
- Unit-test target
- UI-test target
- Shared `SonaPin` scheme
- Debug and Release configurations
- No unnecessary entitlements
- No background modes unless a real feature requires them
- Privacy manifest included
- Localized string catalog included from the beginning

Do not claim concurrency settings are active until they are confirmed from `xcodebuild -showBuildSettings` or the generated project.

Create these developer commands:

```bash
make project
make resolve
make build
make test
make ui-test
make sim
make clean
make lint-check
```

`make lint-check` must not require adding SwiftLint unless the project already uses it. It may validate formatting-sensitive files, search for forbidden unsafe concurrency escapes, and run compiler warnings-as-errors for the project’s own source.

---

## 8. Source organization

Use feature-oriented organization without excessive abstraction:

```text
SonaPin/
  App/
  Core/
    Diagnostics/
    Models/
    Persistence/
    Utilities/
  Features/
    Avatar/
      Domain/
      Infrastructure/
      UI/
    Badge/
    Onboarding/
    QRCode/
    Settings/
  Resources/
SonaPinTests/
SonaPinUITests/
scripts/
docs/
artifacts/                # gitignored except a README if useful
```

Keep files focused. Extract complex SwiftUI bodies early, but do not create protocols or layers with only ceremonial value.

---

## 9. State and concurrency design

Use modern Observation and explicit isolation:

- `@Observable` for new observable state.
- `@State` for view-owned observable instances.
- `@Bindable` where a child needs bindings into an injected observable model.
- Keep all `@State` and `@FocusState` properties private.
- Use `@MainActor` for UI state and RealityKit scene/entity orchestration when the underlying APIs require it.
- Use an `actor` for avatar-file copying, replacement, deletion, checksums, and persistence I/O.
- Pass immutable `Sendable` value snapshots across isolation boundaries.
- Do not pass RealityKit entities, VRMKit parser objects, or other non-Sendable reference graphs between actors.
- Prefer structured concurrency.
- Support cancellation during long model imports and loading.
- Never use semaphores to bridge async code.

Create a small concurrency design note in `docs/ENGINEERING_DECISIONS.md` that states:

- Swift language mode
- strict-concurrency setting
- default actor-isolation setting
- UI actor boundary
- file-storage actor boundary
- how cancellation works
- what values cross those boundaries

---

## 10. Version 1 product scope

The first public MVP must include all of the following.

### 10.1 Built-in demo avatar

Create an original procedural demo avatar using RealityKit primitives. It should suggest a friendly stylized animal character without using third-party artwork or model assets.

It exists so that:

- The app is useful before importing a VRM.
- App Review can test the experience immediately.
- UI tests and Simulator smoke tests do not depend on a licensed external model.
- Users can recover from a failed or deleted model.

The demo avatar must support at least:

- idle motion
- tap/boop reaction
- happy reaction
- drag rotation
- pinch zoom
- reset camera
- haptic feedback

Do not use SF Symbols as the shipped app icon artwork.

### 10.2 Onboarding

Build a polished, resumable onboarding flow:

1. Welcome and product explanation.
2. Choose the built-in demo or import a `.vrm`.
3. Review import compatibility and model license metadata.
4. Enter badge identity:
   - display name
   - pronouns
   - species/character type
   - optional short tagline
5. Configure QR content:
   - website URL
   - social/profile URL
   - contact URL
   - custom text
6. Preview and validate the QR code.
7. Choose a badge theme.
8. Preview the complete badge.
9. Finish and enter Badge Mode.

The flow must permit going back without data loss and must recover after app termination.

### 10.3 Badge Mode

Create the primary full-screen experience:

- interactive avatar stage
- display name
- pronouns
- species/character type
- optional tagline
- large, high-contrast QR code with a proper quiet zone
- tap QR to enlarge
- edit/settings affordance that cannot be triggered accidentally
- keep-screen-awake option
- accidental-edit lock
- restore previous idle-timer/brightness state when leaving Badge Mode or when the app backgrounds

Do not allow moving visual content behind the QR code in a way that harms scanning.

### 10.4 Avatar interactions

Version 1 interactions:

- Tap avatar: friendly reaction.
- Tap/boop head or nose when hit targets are available: happy or surprised expression.
- Drag horizontally: rotate avatar.
- Pinch: zoom within safe limits.
- Double-tap: reset view.
- Pointer/touch position may drive look-at behavior when supported.
- Native haptic response, respecting user settings and Reduce Motion.

Use explicit collision/input targets. For imported VRMs, prefer small proxy hit targets attached to known humanoid bones over generating one expensive collision mesh for the full model.

Not every model exposes the same bones or expressions. Use a documented fallback chain and never crash because an optional expression or bone is missing.

### 10.5 Settings

Include:

- profile editor
- QR editor and preview
- avatar import/replace/remove
- compatibility report
- default pose/expression where supported
- interaction sensitivity
- haptics toggle
- Reduce Motion behavior
- high-contrast QR option
- keep-screen-awake toggle
- badge theme
- reset camera
- reset onboarding
- delete all local app data
- About, privacy summary, acknowledgments, and app version

---

## 11. VRM import and compatibility

Define a `Sendable`, `Codable`, testable `AvatarCompatibilityReport` containing at least:

- file name
- file size
- checksum
- detected VRM version
- model title/name
- authors
- contact/reference information when present
- model usage/license metadata
- commercial-use and redistribution information when expressible
- available expressions
- presence of required humanoid bones
- presence of head, neck, eyes, hands, and optional tail-related nodes when discoverable
- spring-bone presence
- look-at mode/support
- animation clips or VRMA support when relevant
- required glTF/VRM extensions
- unsupported required extensions
- parser warnings
- renderer warnings
- overall result: supported, supported-with-warnings, or unsupported

Import rules:

1. Accept `.vrm` through the system file importer.
2. Use security-scoped access correctly.
3. Copy the selected file into the app’s Application Support directory.
4. Validate and parse the candidate before replacing the current avatar.
5. Use atomic replacement.
6. Preserve the working avatar if validation, copying, parsing, or rendering fails.
7. Show actionable errors, not raw parser dumps.
8. Allow canceling an import.
9. Store no model outside the app container after import.
10. Do not upload or transmit the model.
11. Show a user acknowledgment that they are responsible for permission to use the model.
12. Never bundle or commit a third-party VRM without verified redistribution rights and recorded attribution.

For local developer testing, support an optional gitignored path:

```text
LocalAssets/TestAvatar.vrm
```

The app must still build and run when that file is absent.

---

## 12. Renderer boundary

Create a narrow app-owned abstraction around rendering. The exact API may evolve after researching VRMKit, but it should express operations similar to:

```swift
@MainActor
protocol AvatarRendering: AnyObject {
    var capabilities: AvatarCapabilities { get }
    func load(_ source: AvatarSource) async throws
    func unload()
    func setExpression(_ expression: AvatarExpression, weight: Float)
    func play(_ animation: AvatarAnimation, looping: Bool) throws
    func look(at target: SIMD3<Float>?)
    func resetPose()
    func resetCamera()
}
```

Provide:

- `ProceduralDemoAvatarRenderer`
- `VRMKitAvatarRenderer`

Do not expose VRMKit types to Badge, Onboarding, QR, Settings, or persistence features.

RealityKit/VRMKit scene work should honor the actual actor annotations in the package source. Do not fight library isolation with unsafe annotations.

---

## 13. Persistence

Use a small versioned local persistence format suitable for one primary badge profile in version 1.

Preferred model:

- Codable, Sendable value types.
- JSON stored atomically in Application Support.
- An actor-owned persistence service.
- Explicit schema version and migration hook.
- `UserDefaults` only for lightweight flags such as onboarding completion or UI preferences.

Persist:

- badge profile
- QR configuration
- selected theme
- accessibility/interaction preferences
- current avatar record and compatibility snapshot
- onboarding progress

Tests must prove:

- round-trip persistence
- corrupted-file recovery
- atomic replacement
- migration entry point
- preserving a current avatar after a failed import
- complete deletion of user data

---

## 14. QR-code requirements

Generate QR codes locally with Core Image or another Apple framework. Do not add a QR dependency.

Requirements:

- deterministic output
- selectable correction level after research and scan testing
- nearest-neighbor scaling with crisp modules
- sufficient quiet zone
- high contrast
- accessible text describing what the code contains
- URL validation without requiring a network request
- a visible warning for malformed or unsupported payloads
- test coverage for supported payload types
- large preview for scan testing

QR scanning must be tested using another physical device before release. Simulator screenshots are not enough.

---

## 15. Accessibility and inclusive behavior

- VoiceOver labels and hints for every control.
- Meaningful accessibility grouping on the badge.
- Dynamic Type for text outside the fixed presentation constraints of the QR itself.
- Sufficient contrast.
- Reduce Motion mode that replaces continuous/large animation with subtle or static feedback.
- Haptics can be disabled.
- Avatar interactions must also have accessible buttons/actions; touch-only discovery is insufficient.
- Do not rely on color alone.
- Support landscape gracefully if rotation occurs, even if portrait is the preferred badge presentation.
- Localize through a String Catalog from the beginning; English may be the only initial translation.

---

## 16. Privacy and safety

Version 1 must be local-only:

- no account
- no login
- no analytics
- no advertising
- no tracking
- no model upload
- no public gallery
- no social feed
- no comments
- no background networking

Add a privacy manifest matching actual behavior.

Create an in-app privacy summary stating that imported models, badge fields, and QR settings remain on the device unless the user explicitly shares something through a system share sheet added in a future version.

Never log user-entered QR payloads or local model paths in production logs. Use privacy-aware `Logger` interpolation.

---

## 17. Diagnostics and performance

Use `os.Logger` categories for:

- app lifecycle
- avatar import
- avatar validation
- avatar load
- rendering
- persistence
- QR generation

Add signposts or measurable intervals for:

- import-copy duration
- parse duration
- entity-load duration
- first rendered frame
- interaction response

Do not spam logs every frame.

Use Instruments on a physical device before claiming performance. Record a checklist for:

- SwiftUI updates/hitches
- Time Profiler
- Allocations/leaks
- Metal/GPU behavior where supported
- thermal and energy impact
- repeated import/load/unload cycles
- background/foreground cycles

The Simulator run is a functional smoke test, not a GPU benchmark.

---

## 18. Tests

### Unit tests

At minimum:

- profile validation
- QR payload validation
- QR image dimensions/quiet-zone logic
- persistence round trips
- persistence corruption recovery
- schema migration entry point
- model-file atomic replacement
- current-avatar preservation after failure
- compatibility-result rules
- expression fallback selection
- capability fallback behavior
- deletion of all local data

### Integration tests

- procedural demo renderer loads
- VRMKit package resolves and compiles
- optional local VRM fixture can parse when present
- missing local fixture skips with an explicit test message instead of failing the entire suite
- imported file remains available after security-scoped access ends because it was copied into the app container

### UI tests

Use deterministic launch arguments and isolated state:

- `--ui-testing`
- `--reset-app-state`
- `--use-demo-avatar`

Cover:

1. Fresh launch.
2. Complete onboarding with demo avatar.
3. Enter a profile.
4. Configure a QR payload.
5. Reach Badge Mode.
6. Trigger an accessible avatar reaction.
7. Enlarge the QR.
8. Open Settings and edit the profile.
9. Return to Badge Mode.
10. Reset local data.

Assign stable accessibility identifiers only where UI tests need them.

---

## 19. Simulator automation

Create `scripts/run-simulator.sh` and a `make sim` target. The script must perform a real end-to-end launch, not merely compile.

Behavior:

1. Verify `xcodebuild` and `xcrun` are available.
2. Generate the Xcode project when required.
3. Resolve package dependencies.
4. Discover available iPhone simulators from local `simctl` JSON.
5. Prefer an already-created modern iPhone simulator with the newest installed stable iOS runtime.
6. Accept optional environment overrides for device name or UDID.
7. If no suitable simulator exists, create one only when an installed iOS runtime and device type make that safe; otherwise print the exact missing component and fail clearly.
8. Boot the selected simulator and wait for boot completion.
9. Build Debug for that exact simulator with a deterministic Derived Data path.
10. Install `SonaPin.app` with `simctl`.
11. Launch bundle ID `com.mrdemonwolf.sonapin` using UI-test/demo launch arguments.
12. Capture launch output.
13. Wait for the app to settle.
14. Save a screenshot to `artifacts/simulator-home.png`.
15. Save metadata to `artifacts/simulator-run.txt`, including Xcode version, runtime, device, UDID, build command, app path, and launch result.
16. Leave the app running so the developer can inspect it.

Use local command help to verify current syntax:

```bash
xcrun simctl help
xcodebuild -help
```

Do not hardcode a simulator device that might not exist.

A representative build shape is:

```bash
xcodebuild \
  -project SonaPin.xcodeproj \
  -scheme SonaPin \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath .build/DerivedData \
  build
```

Derive the final `.app` path from build settings or the deterministic Derived Data location. Do not guess when Xcode reports a different path.

Also create:

- `scripts/test-simulator.sh` for unit/UI tests
- `make test`
- `make ui-test`

At completion, actually run:

```bash
make project
make resolve
make build
make test
make ui-test
make sim
```

Save command logs under `artifacts/` and summarize pass/fail truthfully.

---

## 20. Physical-device gate

Simulator completion is not release completion. Create `docs/DEVICE_TEST_CHECKLIST.md` and clearly mark these as pending until actually performed on an iPhone:

- Import the owner’s real fursona VRM.
- Verify MToon/material appearance.
- Verify expressions.
- Verify spring bones, including ears/tail/hair when present.
- Verify look-at behavior.
- Verify touch hit targets.
- Verify haptics.
- Verify QR scanning from another phone at realistic distances and brightness.
- Verify memory after ten load/unload cycles.
- Verify foreground/background restoration.
- Verify screen-awake and brightness restoration.
- Verify sustained thermal/frame behavior.
- Record an Instruments trace.

Never claim these passed based only on Simulator.

---

## 21. CI

Create a GitHub Actions workflow that:

- uses a currently supported macOS runner after researching the present GitHub runner/Xcode matrix
- prints Xcode and Swift versions
- resolves Swift packages
- generates the project when XcodeGen is used
- builds for an available iOS Simulator
- runs unit tests
- runs UI tests when runner stability permits
- uploads test result bundles and relevant logs on failure
- does not require signing secrets for Simulator builds

Pin third-party GitHub Actions to a stable major version or immutable commit according to the repository’s security policy. Keep the workflow understandable.

---

## 22. App Store readiness

Prepare, but do not submit automatically.

Create:

- privacy policy draft
- support-page draft
- App Store description draft
- keyword draft
- screenshot shot list
- App Review notes
- age-rating notes
- imported-content rights acknowledgment
- open-source acknowledgments

App Review notes should explain:

- The app is an interactive local digital badge.
- The procedural demo avatar allows complete review without importing a file.
- Users may import their own VRM models.
- Imported models and profile information remain on-device.
- No login is required.
- No tracking, ads, analytics, payments, or public user-generated-content system exists in version 1.
- How to trigger avatar interactions.
- How to configure and enlarge a QR code.

Do not use claims such as “supports every VRM.” Document the tested compatibility envelope.

---

## 23. Visual direction

Use a restrained technical/furry identity based on:

- midnight navy `#091533`
- cerulean `#00ACED`
- cornflower `#6B8BF5`
- amber-gold as a small eye/interaction accent

Requirements:

- Native, readable SwiftUI hierarchy.
- No fake glass effects or gratuitous gradients.
- No Liquid Glass requirement.
- QR code remains black/dark on a clean light background or another verified high-contrast combination.
- The avatar is the hero, but identity and QR information remain legible.
- Use an original temporary geometric app icon created for this project, not copied art and not an SF Symbol pasted into the icon.
- Keep branding assets replaceable.

---

## 24. Git workflow

- Work on a feature branch such as `feat/native-mvp` unless the repository policy says otherwise.
- Make small, coherent commits after green builds.
- Never commit signing certificates, provisioning profiles, user VRMs, personal QR destinations, Derived Data, or simulator containers.
- Add `LocalAssets/` and `artifacts/` outputs to `.gitignore` as appropriate.
- Preserve useful existing history.
- Do not force-push protected branches.

Suggested commit sequence:

1. `chore: scaffold native SonaPin project`
2. `feat: add local profile and onboarding flow`
3. `feat: add procedural interactive demo avatar`
4. `feat: add QR configuration and badge mode`
5. `feat: add VRM import and compatibility reporting`
6. `test: add unit and UI coverage`
7. `chore: automate simulator build and launch`
8. `docs: add research and release readiness notes`

Do not create commits when tests are knowingly red unless the commit is explicitly marked as a diagnostic checkpoint and is not pushed to the main branch.

---

## 25. Definition of done

The task is complete only when all applicable items below are true:

- [ ] Working name migrated to SonaPin.
- [ ] Deployment target is exactly iOS 18.0.
- [ ] Current SDK is used for builds.
- [ ] Swift 6 and complete strict concurrency are verified.
- [ ] Relevant installed Swift/iOS skills were read and applied.
- [ ] Research notes exist.
- [ ] Xcode project/scheme is valid.
- [ ] VRMKit is pinned to an exact stable version.
- [ ] Procedural demo avatar works.
- [ ] Onboarding works.
- [ ] Profile editing works.
- [ ] QR generation and enlargement work.
- [ ] Badge Mode works.
- [ ] Haptics and Reduce Motion settings work.
- [ ] File import is security-scoped and copied locally.
- [ ] Candidate VRM is validated before replacement.
- [ ] Compatibility report works.
- [ ] Failed imports preserve the current avatar.
- [ ] No imported content leaves the device.
- [ ] Unit tests pass.
- [ ] UI tests pass.
- [ ] GitHub Actions workflow exists.
- [ ] `make build` passes.
- [ ] `make test` passes.
- [ ] `make ui-test` passes or has a precisely documented infrastructure limitation.
- [ ] `make sim` launches the app in a real local iOS Simulator.
- [ ] Simulator screenshot and run metadata exist.
- [ ] Physical-device-only checks are explicitly separated from Simulator results.
- [ ] No unsafe concurrency escape was added without a documented invariant.
- [ ] No signing secret or user VRM is committed.
- [ ] App Store preparation drafts exist.

---

## 26. Execution behavior

Follow these rules while working:

1. Inspect before editing.
2. Research uncertain/current facts from primary sources.
3. Show meaningful progress after major milestones, not every command.
4. Fix the smallest real problem revealed by compiler/test output.
5. Do not weaken warnings or concurrency checks just to make the build green.
6. Do not redesign unrelated areas while fixing a localized issue.
7. Do not ask the user for a VRM merely to continue; use the procedural demo and optional local fixture path.
8. If signing is unavailable, complete all Simulator work and document the exact physical-device signing step.
9. If a third-party package fails, capture the exact diagnostic, inspect package source/release notes/issues, and preserve the renderer boundary.
10. Do not claim work was run when it was only described.

---

## 27. Required final report

At the end, return a concise but complete report with:

### Result

- overall status
- app name and bundle ID
- deployment target
- Xcode/Swift versions used
- selected simulator and runtime

### Verification

- exact commands run
- build result
- unit-test result
- UI-test result
- simulator-install result
- simulator-launch result
- screenshot path

### Implementation

- major features completed
- architecture summary
- dependency version and pin
- concurrency boundaries
- privacy behavior

### Honest limitations

- anything not completed
- VRMKit/RealityKit limitations observed
- physical-device checks still pending
- App Store tasks requiring owner credentials or final content

### Files and commits

- key files created/changed
- commit hashes and messages
- branch name

Do not end with only “done” or a generic status statement.

---

## 28. Start now

Begin by:

1. Reading this entire file.
2. Inspecting the repository.
3. Discovering and reading the installed Swift/iOS skills.
4. Running the environment/research commands.
5. Creating `docs/RESEARCH.md` and an implementation checklist.
6. Building the smallest SonaPin shell.
7. Proceeding phase by phase until the Definition of Done is met.

Do not stop after writing a plan. Execute the plan, build the app, run tests, and launch it in the iOS Simulator.
