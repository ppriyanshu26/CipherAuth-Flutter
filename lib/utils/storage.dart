import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class Storage {
  static const _masterPasswordHashKey = 'master_password_hash';
  static const _darkModeKey = 'dark_mode';

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> hasMasterPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_masterPasswordHashKey);
  }

  static Future<void> saveMasterPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = hashPassword(password);
    await prefs.setString(_masterPasswordHashKey, hash);
  }

  static Future<bool> verifyMasterPassword(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_masterPasswordHashKey);
    if (storedHash == null) return false;

    final inputHash = hashPassword(input);
    return inputHash == storedHash;
  }

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }
}
