import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'crypto.dart';

class PasswordStore {
  static const storeKey = 'password_store';

  static String generateId(String name, String domain, String username, String password) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final input = '$name$domain$username$password$timestamp';
    return sha256.convert(utf8.encode(input)).toString();
  }

  static String getFormattedTimestamp() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString().padLeft(4, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$day$month$year $hour$minute$second';
  }

  static Future<List<Map<String, String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(storeKey);
    if (encrypted == null || encrypted.isEmpty) return [];

    try {
      final decrypted = await Crypto.decryptAes(encrypted);
      final decoded = jsonDecode(decrypted) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => {
                'id': (e['id'] ?? '').toString(),
                'name': (e['name'] ?? '').toString(),
                'domain': (e['domain'] ?? '').toString(),
                'username': (e['username'] ?? '').toString(),
                'password': (e['password'] ?? '').toString(),
                'notes': (e['notes'] ?? '').toString(),
                'createdAt': (e['createdAt'] ?? '').toString(),
                'updatedAt': (e['updatedAt'] ?? '').toString(),
              })
          .where((e) => e['id']!.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<Map<String, String>> items) async {
    final encrypted = await Crypto.encryptAes(jsonEncode(items));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }

  static Future<bool> add(
    String name,
    String domain,
    String username,
    String password,
    String notes,
  ) async {
    final list = await load();
    final id = generateId(name, domain, username, password);
    final now = getFormattedTimestamp();
    list.add({
      'id': id,
      'name': name,
      'domain': domain,
      'username': username,
      'password': password,
      'notes': notes,
      'createdAt': now,
      'updatedAt': now,
    });
    await saveAll(list);
    return true;
  }

  static Future<bool> update(
    String id,
    String name,
    String domain,
    String username,
    String password,
    String notes,
  ) async {
    final list = await load();
    final index = list.indexWhere((e) => e['id'] == id);
    if (index == -1) return false;

    final createdAt = list[index]['createdAt'] ?? getFormattedTimestamp();
    
    list[index] = {
      'id': id,
      'name': name,
      'domain': domain,
      'username': username,
      'password': password,
      'notes': notes,
      'createdAt': createdAt.isEmpty ? getFormattedTimestamp() : createdAt,
      'updatedAt': getFormattedTimestamp(),
    };

    await saveAll(list);
    return true;
  }

  static Future<void> deleteById(String id) async {
    final list = await load();
    final updated = list.where((e) => e['id'] != id).toList();
    await saveAll(updated);
  }
}