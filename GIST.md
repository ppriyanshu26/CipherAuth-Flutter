# Privacy Policy for CipherAuth

Last Updated: March 23, 2026

## Overview
CipherAuth is a security-focused TOTP (Time-based One-Time Password) authenticator for Android and Windows. This Privacy Policy explains how data is handled when you install CipherAuth from GitHub Releases, Microsoft Store, or Google Play.

## Data Collection by CipherAuth
- No account system: CipherAuth does not require account registration or sign-in.
- No personal data collection by the app: CipherAuth does not collect or transmit names, email addresses, phone numbers, contacts, or advertising identifiers.
- No analytics SDKs: CipherAuth does not include third-party analytics, ad SDKs, or tracking SDKs.
- No cloud backend by developer: CipherAuth does not send your vault data to developer-controlled servers.

## Network and Transmission
- Default behavior is local-only.
- Optional local sync feature: If you use Sync, CipherAuth exchanges encrypted vault data only with other CipherAuth devices on your local network (LAN). This is device-to-device communication, not cloud upload.
- No internet sync service is provided by CipherAuth.

## What CipherAuth Stores On Device
- TOTP vault data: Stored locally in encrypted form using AES-256-GCM.
- Master password verifier: A SHA-256 hash is stored locally to verify login.
- Optional biometric unlock data: If you enable biometric unlock, the app stores the required secret in secure OS-backed storage.
- App settings: Theme, biometric toggle, and local sync metadata may be stored locally.

## Storage Locations
- Windows: App data is stored in app-local directories managed by Windows and Flutter runtime.
- Android: App data is stored in the app's private sandbox.
- Exported files: If you use export, files are written to a user-accessible location (Downloads). Those exported files are under your control and should be protected by you.

## Permissions
CipherAuth may request permissions only for features you use:
- Camera: Scan QR codes for adding accounts.
- Storage or file access: Import or export credential files.
- Biometric or device credential: Unlock app via biometrics or device authentication.
- Local network access: Discover and sync with nearby CipherAuth devices on your LAN.

## Distribution Channel Notice
How you install CipherAuth changes what third parties (store or platform providers) may process outside the app itself:

### GitHub Releases (Sideload)
- CipherAuth app behavior is as described in this policy.
- GitHub may process download and request logs according to GitHub policies.

### Microsoft Store
- CipherAuth app behavior is as described in this policy.
- Microsoft may collect store-level telemetry (such as acquisition, install, update, crash, and diagnostics) under Microsoft policies.

### Google Play
- CipherAuth app behavior is as described in this policy.
- Google may collect store-level telemetry and Play Protect or security signals under Google policies.

Important: Store or platform-level processing is controlled by those providers, not by CipherAuth. Please review their privacy policies for full details.

## Data Retention and Deletion
- Your vault remains on your device unless you export or sync locally.
- Deleting app data or uninstalling the app removes locally stored CipherAuth data from that device, subject to OS behavior and backups you created.
- You can manually export, import, or delete credentials at any time.

## Source-Available License Notice
CipherAuth is source-available software, not open-source software. Source visibility is provided for transparency and learning. Redistribution, relicensing, commercial reuse, or publishing modified standalone builds requires prior written permission from the developer.

## Children's Privacy
CipherAuth is not designed to knowingly collect personal data from children. Since no account or profile data is collected by the app, CipherAuth does not knowingly process children's personal information.

## Compliance Intent
CipherAuth is designed with data minimization and local-first processing principles aligned with major privacy expectations, including GDPR-style principles such as purpose limitation and data minimization.

## Contact
For privacy questions, contact the developer through the support channels listed in:
- Microsoft Store listing
- Google Play listing
- GitHub repository or release page
