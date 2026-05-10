import 'package:shared_preferences/shared_preferences.dart';
import '../crypto/crypto.dart';
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
      final encryptedStore = prefs.getString(TotpStore.storeKey);
      String decryptedStore = '[]';
      if (encryptedStore != null && encryptedStore.isNotEmpty) {
        decryptedStore = await Crypto.decryptAesWithPassword(
          encryptedStore,
          oldPassword,
        );
      }
      final reEncryptedStore = await Crypto.encryptAesWithPassword(
        decryptedStore,
        newPassword,
      );
      await prefs.setString(TotpStore.storeKey, reEncryptedStore);

      final encryptedRecycle = prefs.getString(TotpStore.recycleBinKey);
      if (encryptedRecycle != null && encryptedRecycle.isNotEmpty) {
        final decryptedRecycle = await Crypto.decryptAesWithPassword(
          encryptedRecycle,
          oldPassword,
        );
        final reEncryptedRecycle = await Crypto.encryptAesWithPassword(
          decryptedRecycle,
          newPassword,
        );
        await prefs.setString(TotpStore.recycleBinKey, reEncryptedRecycle);
      }
    } catch (e) {
      rethrow;
    }
  }
}