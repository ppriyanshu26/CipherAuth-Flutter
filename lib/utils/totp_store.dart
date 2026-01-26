import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'crypto.dart';

class TotpStore {
  static const storeKey = 'totp_store';

  static String _generateId(String platform, String secret) {
    final salt = (DateTime.now().millisecondsSinceEpoch / 1000).toString();
    final input = '$platform$secret$salt';
    return sha256.convert(input.codeUnits).toString();
  }

  static Future<List<Map<String, String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(storeKey);

    if (encrypted == null || encrypted.isEmpty) return [];

    final decrypted = await Crypto.decryptAes(encrypted);
    final List<dynamic> decoded = jsonDecode(decrypted);

    return decoded.map<Map<String, String>>((e) {
      return {
        'id': e['id'] as String,
        'platform': e['platform'] as String,
        'username': e['username'] as String,
        'secretcode': e['secretcode'] as String,
      };
    }).toList();
  }

  static Future<bool> add(String platform, String url) async {
    final list = await load();

    final uri = Uri.parse(url);
    final label = uri.pathSegments.last;

    String username = '';
    if (label.contains(':')) {
      username = label.split(':').sublist(1).join(':');
    }

    final secret = (uri.queryParameters['secret'] ?? '').toUpperCase();

    final p = platform.trim().toLowerCase();
    final u = username.trim().toLowerCase();

    for (final item in list) {
      final itemSecret = item['secretcode'] ?? '';

      if (item['platform']!.trim().toLowerCase() == p &&
          item['username']!.trim().toLowerCase() == u &&
          itemSecret == secret) {
        return false;
      }
    }

    final newItem = {
      'id': _generateId(platform, secret),
      'platform': platform,
      'username': username,
      'secretcode': secret,
    };

    list.add(newItem);

    list.sort(
      (a, b) =>
          a['platform']!.toLowerCase().compareTo(b['platform']!.toLowerCase()),
    );

    final encrypted = await Crypto.encryptAes(jsonEncode(list));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
    return true;
  }

  static Future<void> saveAll(List<Map<String, String>> items) async {
    final encrypted = await Crypto.encryptAes(jsonEncode(items));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }
}
