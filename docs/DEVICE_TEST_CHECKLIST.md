# Physical iPhone release gate

Status: **pending**. Nothing below can be marked passed from Simulator evidence.

Record device model, iOS version, app commit, VRM checksum, tester, date, and evidence path for every run.

## Avatar and rendering

- [ ] Import the owner's real fursona VRM through Files.
- [ ] Confirm the import report identifies version, metadata, required bones, extensions, and warnings accurately.
- [ ] Compare MToon and other material appearance with a known-good viewer.
- [ ] Verify supported facial expressions and the default expression.
- [ ] Verify spring bones, including ears, tail, and hair when present.
- [ ] Verify look-at behavior.
- [ ] Verify scale, framing, clipping, rotation, and reset-camera behavior in portrait and landscape.

## Interaction and accessibility

- [ ] Verify tap, drag, pinch, and rotation hit targets on the avatar.
- [ ] Verify interaction sensitivity at minimum, default, and maximum settings.
- [ ] Verify haptics when enabled and silence when disabled.
- [ ] Verify VoiceOver order, labels, values, hints, and adjustable controls.
- [ ] Verify Dynamic Type through accessibility sizes without clipped controls.
- [ ] Verify Reduce Motion behavior and the in-app override.
- [ ] Verify Increase Contrast, Differentiate Without Color, and high-contrast QR mode.

## QR reliability

- [ ] Scan the enlarged QR from a second physical phone.
- [ ] Test short text, a URL, and the maximum supported payload.
- [ ] Test correction levels L, M, Q, and H.
- [ ] Test realistic badge distances, viewing angles, screen brightness levels, and ambient light.
- [ ] Confirm the quiet zone stays clear and no UI overlays cover modules.
- [ ] Confirm malformed URL-like payloads produce a warning without blocking intentional plain text.

## Lifecycle, resources, and restoration

- [ ] Perform ten avatar load/remove or replace cycles and record peak and settled memory.
- [ ] Background and foreground the app with the demo avatar and an imported avatar.
- [ ] Terminate and relaunch; verify profile, QR, theme, avatar selection, and settings restore.
- [ ] Verify keep-screen-awake returns to the system default after disabling it and after app exit.
- [ ] Verify any app-controlled brightness change restores the prior brightness on exit, interruption, and crash recovery path.
- [ ] Run a sustained badge session and record thermal state, frame behavior, and battery impact.
- [ ] Capture an Instruments trace covering launch, import, interactions, backgrounding, and repeated load/unload.

## Data and failure handling

- [ ] Cancel Files import and confirm no state changes.
- [ ] Import malformed, oversized, and unsupported files; confirm actionable errors and preservation of the last working avatar.
- [ ] Revoke or move the source document after import; confirm the managed copy still works.
- [ ] Delete all local app data; confirm the profile, QR, imported model, cached reports, and preferences are removed.
- [ ] Confirm production logs contain no QR payloads, profile values, or local file paths.

## Sign-off

- [ ] All failures have an issue link and retest evidence.
- [ ] Compatibility claims match the models and devices actually tested.
- [ ] The archive privacy report matches `PrivacyInfo.xcprivacy` and App Store Connect disclosures.
- [ ] Product owner approves physical-device evidence for release.

