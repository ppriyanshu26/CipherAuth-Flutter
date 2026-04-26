# CipherAuth 🔐

CipherAuth is a secure, cross-platform TOTP (Time-based One-Time Password) authenticator application designed for simplicity and security. Built with Flutter, it provides a safe vault for your two-factor authentication tokens across Android and Windows platforms.

> License Model: CipherAuth is source-available software (not open-source). See the [LICENSE](https://github.com/ppriyanshu26/CipherAuth-Flutter/blob/main/LICENSE) file for usage and redistribution terms.
>
> Privacy Policy: See the full policy in [GIST File](GIST.md) or in [GitHub Gist](https://gist.github.com/ppriyanshu26/b9c863813ee032a9ffd9f94ff1f78aee).

## 📦 Releases

- Download the latest version for Android from the [Releases Page](https://github.com/ppriyanshu26/CipherAuth-Flutter/releases).
- Download the latest version for Windows from the [Microsoft Store](https://apps.microsoft.com/detail/9NS2R9NTRF2Z)

## ✨ Features

- **Encrypted Storage:** All your credentials are encrypted with AES-256.
- **Modern UI:** Clean, intuitive interface built with Flutter.
- **Biometric Unlock:** Supports Windows Hello and Biometrics to unlock the app.
- **Cross-Platform:** Runs seamlessly on Android and Windows.
- **Search:** Quickly find your accounts with the built-in search bar.
- **QR Code Support:** View and scan QR codes for easy setup.
- **Export/Import:** Easily backup and restore your credentials.
- **Password Protected:** Secured by a master password to prevent unauthorized access.
- **Sync:** Sync your credentials securely to another device.

## 🛠️ Development & Compilation

CipherAuth is built with Flutter and can be compiled for any platform (iOS, Android, macOS, Linux, Windows) with minimal code changes.
> **Note:** Source visibility is provided for transparency and learning. Reuse, redistribution, and derivative standalone releases require prior written permission.

### Running from Source

1. Clone the repository.
2. Ensure you have Flutter installed. If not, follow the [Flutter installation guide](https://docs.flutter.dev/get-started/install).
3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash
   flutter run
   ```

### Running Android Flavors

Use these commands to run the correct Android variant:

```bash
# Production flavor
flutter run --flavor prod

# Sample/Test flavor
flutter run --flavor sample
```

### Compiling for Mobile

#### Android
```bash
flutter build apk
```
The compiled APK will be available in the `build/app/outputs/apk/` folder.

To build a specific flavor:

```bash
# Production flavor
flutter build apk --flavor prod

# Sample/Test flavor
flutter build apk --flavor sample
```

Flavor APK outputs are generated under `build/app/outputs/flutter-apk/`.

#### Windows
```bash
flutter build windows
```
The compiled Windows executable will be available in the `build/windows/x64/runner/Release/` folder.

To build an MSIX package:
```bash
dart run msix:create
```
The generated MSIX package will be available in the `build/windows/x64/runner/Release/` folder.

For detailed windows release instructions, see the [Flutter documentation](https://docs.flutter.dev/deployment/windows).


## ❓ FAQ

### How do I add a new account?
Click on the **"➕"** button and fill in the account details.

### How do I back up my tokens?
Use the **"📥 Export"** option to create a decrypted CSV backup. On Android and desktop, CipherAuth opens a **Save As** dialog so you can choose the folder (for example, Downloads). Keep this file safe.

### How does the Recycle Bin work?
Deleted credentials are moved to **Recycle Bin** (Settings → Recycle Bin) instead of being removed immediately. You can restore them at any time within **30 days**. After that, they are automatically removed. You can also choose **Delete permanently** from the item menu to remove an entry right away.

> **Note:** CipherAuth has no central server to force-delete data across all your devices. A permanent delete only affects the current device. If you later sync with another device that still has that credential (either in the main list or in its Recycle Bin), it can be added back and treated as a fresh entry.

### Can I use this on different platforms?
Yes! CipherAuth is built with Flutter, which means you can run it on Windows and Android. Just compile for your desired platform. 

### Is my data synced to the cloud?
No. CipherAuth is designed to be fully offline for maximum privacy. Your data stays on your device. However, you can sync your credentials across multiple devices on the same network using the built-in **Sync** feature (🔃). Devices must have the same master password encryption key to synchronize securely.

## ⚠️ Important Note

> **Disclaimer:** CipherAuth uses high-level encryption secured by your Master Password. If you forget your Master Password, **we cannot recover your data**. There are no "backdoors" or password recovery options for your security. Please ensure you keep your password in a safe place.

---
*Developed with ❤️ using Flutter.*
