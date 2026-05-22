import 'package:shared_preferences/shared_preferences.dart';
import '../crypto/crypto.dart';
import '../crypto/password_store.dart';
import '../crypto/totp_store.dart';

class Storage {
  static const darkKey = 'dark_mode';

  static Future<void> saveMasterPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = await Crypto.encryptAesWithPassword('[]', password);
    await prefs.setString(TotpStore.storeKey, encrypted);
  }

  static Future<bool> verifyMasterPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(TotpStore.storeKey);
    if (stored == null || stored.isEmpty) return false;
    try {
      await Crypto.decryptAesWithPassword(stored, password);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasMasterPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(TotpStore.storeKey);
    return stored != null && stored.isNotEmpty;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkKey, value);
  }

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(darkKey) ?? false;
  }

  static Future<void> resetMasterPassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Future<void> reEncryptKey(
        String key, {
        String fallbackPlaintext = '[]',
      }) async {
        final encryptedValue = prefs.getString(key);
        String decryptedValue = fallbackPlaintext;

        if (encryptedValue != null && encryptedValue.isNotEmpty) {
          decryptedValue = await Crypto.decryptAesWithPassword(
            encryptedValue,
            oldPassword,
          );
        }

        final reEncryptedValue = await Crypto.encryptAesWithPassword(
          decryptedValue,
          newPassword,
        );
        await prefs.setString(key, reEncryptedValue);
      }

      await reEncryptKey(TotpStore.storeKey);
      await reEncryptKey(TotpStore.recycleBinKey);
      await reEncryptKey(PasswordStore.storeKey);
      await reEncryptKey(PasswordStore.recycleBinKey);
    } catch (e) {
      rethrow;
    }
  }
}
