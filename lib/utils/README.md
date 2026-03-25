# Utils Directory

Small map of each utility file.

- `app_lifecycle_manager.dart`: Handles app foreground/background lifecycle, screenshot protection, and runtime key clearing.
- `biometric_service.dart`: Biometric availability checks, auth flow, and secure storage of biometric unlock secret.
- `crypto.dart`: AES-256-GCM encrypt/decrypt helpers using master-password-derived keys.
- `export_service.dart`: Exports credentials to CSV using platform Save As flow (Android, Windows) with a storage-path fallback for unsupported platforms.
- `import_service.dart`: Parses CSV, filters duplicates, and imports new credentials into the vault.
- `qr_decoder.dart`: Decodes QR text from image files (desktop/non-MLKit path).
- `runtime_key.dart`: In-memory holder for current raw master password during app session.
- `storage.dart`: Shared preferences helpers for password hash, theme, and password reset re-encryption.
- `support_helpers.dart`: Reusable UI helpers for support screen sections, link copy, and link open.
- `sync_connection.dart`: TCP sync handshake, encrypted data exchange, and merged credential persistence.
- `sync_merge.dart`: Credential merge and JSON conversion helpers (legacy/simple merge utilities).
- `sync_service.dart`: UDP broadcaster/discovery services for finding nearby CipherAuth devices on LAN.
- `totp.dart`: RFC-style TOTP generation from Base32 secret and time counter.
- `totp_store.dart`: Encrypted credential store CRUD plus deletion-log/tombstone merge support.
