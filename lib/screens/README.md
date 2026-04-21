# Screens Directory

Small map of each screen file.

- `about_screen.dart`: About page with app info, version, and developer social links.
- `add_account_screen.dart`: Adds new TOTP accounts by camera QR, image QR, or manual entry.
- `create_password_screen.dart`: First-run screen to create and validate the master password.
- `home_screen.dart`: Main vault UI showing TOTP codes, search, copy, add, and delete actions.
- `login_screen.dart`: Login screen with master password and optional biometric unlock.
- `recycle_bin_screen.dart`: Lists recently deleted accounts and allows restore or permanent removal.
- `reset_password_screen.dart`: Changes master password and rekeys encrypted vault data.
- `settings_screen.dart`: Settings hub for theme, biometrics, sync, QR view, import/export, and support/about.
- `startup_screen.dart`: Entry gate that routes to create-password or login based on stored state.
- `support_screen.dart`: Support content, privacy/terms/FAQ, and contact/licensing info.
- `sync_screen.dart`: Device discovery and LAN sync flow with sync connection handling.
- `view_qr_screen.dart`: Re-auth screen that displays stored account QR codes for transfer.
