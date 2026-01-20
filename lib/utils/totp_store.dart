import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto.dart';

class TotpStore {
  static const storeKey = 'totp_store';

  static Future<List<Map<String, String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(storeKey);

    if (encrypted == null || encrypted.isEmpty) {
      return [];
    }

    final decrypted = await Crypto.decryptAes(encrypted);
    final List<dynamic> decoded = jsonDecode(decrypted);

    return decoded.map<Map<String, String>>((e) {
      return {
        'platform': e['platform'] as String,
        'url': e['url'] as String,
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
      final existingUri = Uri.parse(item['url']!);
      final existingLabel = existingUri.pathSegments.last;

      String existingUser = '';
      if (existingLabel.contains(':')) {
        existingUser =
            existingLabel.split(':').sublist(1).join(':');
      }

      final existingSecret =
      (existingUri.queryParameters['secret'] ?? '').toUpperCase();

      if (item['platform']!.trim().toLowerCase() == p &&
          existingUser.trim().toLowerCase() == u &&
          existingSecret == secret) {
        return false;
      }
    }

    list.add({'platform': platform, 'url': url});

    list.sort((a, b) =>
        a['platform']!.toLowerCase().compareTo(
          b['platform']!.toLowerCase(),
        ));

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
