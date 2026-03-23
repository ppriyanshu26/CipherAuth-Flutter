# CipherAuth App Logic (lib)

This README describes what the app does from the `lib/` layer, how the feature flow is organized, and the minimal platform rules contributors should keep.

## What The App Does

- Stores TOTP accounts locally and generates 6-digit time-based codes.
- Encrypts saved secrets and sensitive app data using the master password flow.
- Supports optional biometric unlock when available on the device/platform.
- Lets users add accounts by:
  - live camera QR scan (mobile only)
  - QR from image file
  - manual entry
- Supports import/export and local-network sync between CipherAuth devices.

## Feature Summary

- Startup routing to create-password or login flow.
- Password-based authentication with optional biometric shortcut.
- Account vault with search, copy, add, delete, and QR viewing.
- Settings for theme, biometrics, sync, import/export, and support links.
- Lifecycle security behavior (re-auth on resume and runtime key handling).

## File Maps

- Screens reference: [screens/README.md](screens/README.md)
- Utils reference: [utils/README.md](utils/README.md)

## Main App Entry

- Entry point: [main.dart](main.dart)
- App lifecycle + navigation lock is wired at startup.
- Theme mode is loaded from persisted storage and can be toggled.

## Platform Behavior (Current Logic)

| Platform | Live Camera QR | QR From Image | Biometrics |
| --- | --- | --- | --- |
| Android | Yes | Yes | Yes |
| iOS | Yes | Yes | Yes |
| Windows | No | Yes | Yes (device dependent) |
| macOS | No (same as desktop logic) | Yes | Yes (device dependent) |
| Linux | No (same as desktop logic) | Yes | Usually unavailable; password fallback |

### Capture Privacy Requirement

- iOS should block screenshots and screen recordings for sensitive app screens.
- iOS should present a blank preview in the app switcher/open-apps view when the app is visible in recents.

## Contributor Notes: Minimal Changes for iOS, macOS, Linux

Use the same business logic everywhere and only make the minimum platform wiring changes.

1. Generate missing platform folders once:

```bash
flutter create --platforms=ios,macos,linux .
```

2. Keep camera policy unchanged:
- Live camera QR scan is mobile-only (`Android` + `iOS`).
- Desktop (`Windows`, `macOS`, `Linux`) should not use live camera scanner UI.
- Desktop should continue using QR-from-image flow.

3. Keep biometric policy unchanged:
- Never force biometrics.
- Always use runtime checks and allow password fallback.
- On Linux, expect many systems to run password-only.

4. iOS required permissions:
- Add `NSCameraUsageDescription` in `ios/Runner/Info.plist`.
- Add `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`.

5. iOS privacy behavior (required):
- Keep screenshot blocking enabled.
- Keep screen-recording blocking enabled.
- Keep app switcher snapshot obfuscation enabled (blank/hidden preview).

6. macOS and Linux expectations:
- No live camera QR flow (same as Windows behavior).
- Biometric support depends on OS/device/plugin support; fallback must remain password.

## Contribution Rule of Thumb

If a platform capability is missing (camera/biometric), do not change the core auth logic.
Gate the feature by platform/capability checks and keep master-password flow as the reliable default.
