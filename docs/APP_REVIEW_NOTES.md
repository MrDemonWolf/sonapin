# SonaPin 1.0 App Review notes

## Review summary

SonaPin is an interactive, local digital fursona badge. The built-in procedural demo avatar makes the complete core experience reviewable without an account, network connection, or imported file.

Version 1 has no login, tracking, advertising, analytics, payments, model uploads, public gallery, social feed, comments, or public user-generated-content system. Imported models, profile details, and QR settings remain on the device.

## Suggested review path

1. Launch SonaPin and complete the short onboarding flow.
2. Continue with the built-in demo avatar; no external file is required.
3. In Badge Mode, drag, pinch, and rotate the avatar. Tap supported interaction areas to trigger available reactions.
4. Open Settings to edit the badge profile and interaction preferences.
5. Open the QR editor, enter a test URL such as `https://example.com`, choose an error-correction level, and open the enlarged preview.
6. Open the compatibility report to see the fields SonaPin provides for imported models.
7. Optional: choose Replace Avatar and select a rights-cleared `.vrm` file from Files. Canceling or a failed validation leaves the current avatar unchanged.
8. Use Delete All Local Data in Settings to remove locally stored profile, QR, avatar, report, and preference data.

Before submission, compare these labels with the final binary and update any wording that differs.

## Imported files and rights

Users may import VRM models they already possess. The import flow tells users to import only content they own or have permission to use and display. SonaPin reads available VRM license and permission metadata for its compatibility report; it does not interpret absent metadata as permission and does not upload models.

Review does not require an imported model. If an optional sample VRM is supplied to App Review, document its source and license in the submission notes and confirm that redistribution and review use are allowed.

## Compatibility disclosure

SonaPin does not claim to support every VRM. Compatibility depends on the VRM version, extensions, mesh features, materials, expressions, and secondary-motion features used by a model. Unsupported or approximated features are disclosed in the compatibility report, and a failed replacement preserves the last working avatar.

## Minimum functionality

The app is more than a static model viewer. It includes a built-in interactive avatar, profile badge, deterministic QR creation and enlarged preview, touch interactions, model import and compatibility reporting, accessible controls, themes, and persistent local settings. These features are usable offline without import.

## Contact and URLs

- Support: `https://mrdemonwolf.github.io/sonapin/support/`
- Privacy: `https://mrdemonwolf.github.io/sonapin/privacy/`
- Terms: `https://mrdemonwolf.github.io/sonapin/terms/`

Verify all deployed pages and provide current review contact information in App Store Connect before submission.
