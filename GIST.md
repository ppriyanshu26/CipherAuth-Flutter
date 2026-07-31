# Privacy Policy for CipherAuth

Last Updated: August 1, 2026

## Overview
CipherAuth is an offline-first, cross-platform dual vault password manager and TOTP (Time-based One-Time Password) authenticator for Android and Windows. This Privacy Policy explains how data is handled when you install and use CipherAuth, whether obtained from GitHub Releases, Winget, Microsoft Store, or Google Play.

## Data Collection by CipherAuth
- **No account system:** CipherAuth does not require account registration, email sign-in, or user profiles.
- **No personal data collection by the app:** CipherAuth does not collect, log, or transmit names, email addresses, phone numbers, contact lists, device IDs, or advertising identifiers.
- **No analytics or tracking SDKs:** CipherAuth contains zero third-party analytics, telemetries, ad SDKs, or tracking scripts.
- **No cloud backend by developer:** CipherAuth operates entirely offline with no developer-controlled cloud servers or remote databases.

## Network and Transmission
- **Default behavior is local-only:** All operations, including credential storage, TOTP generation, passphrase generation, and vault encryption, occur strictly on your local device.
- **Optional local network sync (LAN):** If you choose to enable local sync, CipherAuth exchanges encrypted vault payloads directly between your own devices over your local area network (LAN). This device-to-device communication uses an end-to-end custom handshake; vault data is decrypted only if both devices share the exact same Master Password. No data ever leaves your local network or passes through any cloud server.
- **No internet sync service:** CipherAuth does not host, provide, or connect to any internet-based sync services.

## What CipherAuth Stores On Device
- **Dual Vault Data (TOTP & Passwords):** All 2FA authenticator tokens, secret keys, password credentials, usernames, and associated URLs are stored locally on your device, encrypted using AES-GCM.
- **Master Password Verifier:** A SHA-256 hash of your Master Password is stored locally to authenticate your login sessions.
- **Biometric Unlock Data:** If you enable biometric authentication (Android Biometrics or Windows Hello), biometric verification is handled strictly by the operating system. Secure authentication tokens are stored in OS-backed secure hardware (Android KeyStore or Windows Data Protection API / Credential Manager).
- **Recycle Bin Data:** Deleted credentials are moved to a local Recycle Bin, remaining encrypted on device for up to 30 days before being automatically purged, unless manually restored or permanently deleted earlier.
- **App Settings:** Local user preferences (such as visual theme, auto-lock timeouts, screenshot protection toggles, and sync device metadata) are stored locally in application preferences.

## Storage Locations
- **Windows:** Application data and settings are stored in app-local sandboxed directories managed by Windows and the Flutter runtime environment.
- **Android:** Application data is stored within the app's isolated private sandbox directory, inaccessible to other applications.
- **Exported Files:** If you explicitly export your vault, CipherAuth generates an **encrypted CSV file** protected by your Master Password via AES-GCM. The file is saved to your  Downloads. You retain full ownership and responsibility for protecting exported files.

## Autofill Service
CipherAuth integrates with platform Autofill APIs (such as Android Autofill Service) to allow seamless filling of saved credentials into web browsers and third-party apps:
- When Autofill is invoked, the operating system provides CipherAuth with the target app package name or website URL.
- CipherAuth checks your local encrypted vault for matching stored credentials and returns only the matching entries directly to the OS UI frame.
- URL and package data provided during autofill requests are processed solely in memory to match records and are never saved, logged, or transmitted anywhere.

## Permissions
CipherAuth requests permissions strictly on an opt-in basis for features you explicitly use:
- **Camera & Media Access:** To scan QR codes when adding 2FA TOTP accounts, or to import QR images from your gallery.
- **Storage / File Access:** To write encrypted CSV export files or select encrypted files for vault import.
- **Biometric / Windows Hello Credentials:** To enable fast biometric unlock (Fingerprint, Face Recognition, or Windows PIN).
- **Local Network Access (`privateNetworkClientServer`):** To discover and communicate with other CipherAuth devices on your local Wi-Fi / LAN for local sync.
- **Autofill Service Permission:** To display autofill popups and fill credentials into apps and websites.

## Security Controls
CipherAuth implements proactive local security mechanisms:
- **In-Memory Key Wiping:** Master password runtime keys (`RuntimeKey`) are actively wiped from memory and the interface auto-locks whenever the app is backgrounded or inactive.
- **Screenshot Protection:** On Android, screenshot and screen recording blocking is applied to prevent visual capture of sensitive credentials by unauthorized background apps or task-switchers.

## Distribution Channel Notice
The installation method determines what store-level or platform-level processing occurs outside of CipherAuth itself:

### GitHub Releases & Winget (Sideload / Direct Install)
- CipherAuth app behavior remains completely offline and privacy-focused as described in this policy.
- GitHub or Winget repository mirrors may process download request logs in accordance with their respective privacy policies.

### Microsoft Store
- CipherAuth app behavior is strictly as described in this policy.
- Microsoft may collect store-level telemetry (such as app downloads, acquisition metrics, OS crash reports, and update installation status) under Microsoft's Privacy Statement.

### Google Play
- CipherAuth app behavior is strictly as described in this policy.
- Google may collect store-level diagnostics, installation metrics, and Google Play Protect security signals under Google's Privacy Policy.

*Note: Store-level and platform-level diagnostics are managed independently by Microsoft and Google, not by CipherAuth.*

## Data Retention and Deletion
- Your encrypted vault remains exclusively on your local device.
- Uninstalling CipherAuth or clearing application data permanently removes all locally stored vault entries, settings, and keys from that device (subject to any manual backups you have saved).
- Items moved to the Recycle Bin are held in local encrypted storage for 30 days before automatic purge, or can be permanently deleted immediately by the user.

## Source-Available License Notice
CipherAuth is **source-available software**, not open-source software. Source visibility is provided for auditability, security verification, and educational transparency. Redistribution, re-licensing, rebranding, commercial distribution, or publishing modified standalone builds requires prior written permission from the copyright holder.

## Children's Privacy
CipherAuth is not directed to children and does not collect or process personal data from any user, including children.

## Compliance Intent
CipherAuth is engineered with data minimization and local-first principles aligning with international privacy frameworks (including GDPR principles of Purpose Limitation, Data Minimization, and Privacy by Design).

## Contact
For privacy inquiries or technical questions, contact the developer via official support channels listed on:
- [CipherAuth Website](https://cipherauth.ppriyanshu26.online)
- Microsoft Store Listing
- Google Play Listing
- GitHub Repository & Releases Page
- Email: cipherauth@ppriyanshu26.online

