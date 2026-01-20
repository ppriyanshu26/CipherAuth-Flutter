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

  static Future<void> add(String platform, String url) async {
    final list = await load();
    list.add({'platform': platform, 'url': url});

    list.sort((a, b) {
      final p = a['platform']!.toLowerCase().compareTo(
        b['platform']!.toLowerCase(),
      );
      if (p != 0) return p;
      return a['url']!.compareTo(b['url']!);
    });

    final encrypted = await Crypto.encryptAes(jsonEncode(list));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }

  static Future<void> remove(String platform, String url) async {
    final list = await load();
    list.removeWhere(
          (e) => e['platform'] == platform && e['url'] == url,
    );

    final encrypted = await Crypto.encryptAes(jsonEncode(list));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }
}
