# CipherAuth 🔐

CipherAuth is a secure, cross-platform TOTP (Time-based One-Time Password) authenticator application designed for simplicity and security. Built with Flutter, it provides a safe vault for your two-factor authentication tokens across iOS and Android platforms.

## 📦 Releases

Download the latest version for Android from our [releases page](https://github.com/ppriyanshu26/CipherAuth-Flutter/releases).

## ✨ Features

- **Encrypted Storage:** All your credentials are encrypted with AES-256.
- **Modern UI:** Clean, intuitive interface built with Flutter.
- **Cross-Platform:** Runs seamlessly on iOS and Android.
- **Search:** Quickly find your accounts with the built-in search bar.
- **QR Code Support:** View and scan QR codes for easy setup.
- **Export/Import:** Easily backup and restore your credentials.
- **Password Protected:** Secured by a master password to prevent unauthorized access.
- **Sync:** Sync your credentials securely to another device.

## 🛠️ Development & Compilation

CipherAuth is built with Flutter and can be compiled for any platform (iOS, Android, Web, macOS, Linux, Windows) without any additional code changes.

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

### Compiling for Mobile

#### Android
```bash
flutter build apk
```
The compiled APK will be available in the `build/app/outputs/apk/` folder.

#### iOS
```bash
flutter build ios
```
For detailed iOS release instructions, see the [Flutter documentation](https://docs.flutter.dev/deployment/ios).


## ❓ FAQ

### How do I add a new account?
Click on the **"➕"** button and fill in the account details.

### How do I back up my tokens?
Use the **"📥 Export"** option to download a decrypted version of your credentials. Keep this file safe!

### Can I use this on different platforms?
Yes! CipherAuth is built with Flutter, which means you can run it on iOS and Android. Just compile for your desired platform. For desktop platforms like Linux distros, macOS and Windows, [CipherAuth-Python](https://github.com/ppriyanshu26/CipherAuth-Python)

### Is my data synced to the cloud?
No. CipherAuth is designed to be fully offline for maximum privacy. Your data stays on your device. However, you can sync your credentials across multiple devices on the same network using the built-in **Sync** feature (🔃). Devices must have the same master password encryption key to synchronize securely.

## ⚠️ Important Note

> **Disclaimer:** CipherAuth uses high-level encryption secured by your Master Password. If you forget your Master Password, **we cannot recover your data**. There are no "backdoors" or password recovery options for your security. Please ensure you keep your password in a safe place.

---
*Developed with ❤️ using Flutter.*
