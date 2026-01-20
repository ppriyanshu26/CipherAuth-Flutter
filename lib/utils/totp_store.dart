import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto.dart';

class TotpStore {
  static const storeKey = 'totp_store';
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(storeKey);

    if (encrypted == null || encrypted.isEmpty) {
      return [];
    }
    final decryptedJson = await Crypto.decryptAes(encrypted);
    final List<dynamic> decoded = jsonDecode(decryptedJson);
    return decoded.cast<String>();
  }

  static Future<void> add(String totpUrl) async {
    final list = await load();
    list.add(totpUrl);
    list.sort(compareTotpUrls);
    final jsonString = jsonEncode(list);
    final encrypted = await Crypto.encryptAes(jsonString);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }

  static Future<void> remove(String totpUrl) async {
    final list = await load();
    list.remove(totpUrl);

    final jsonString = jsonEncode(list);
    final encrypted = await Crypto.encryptAes(jsonString);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }

  static int compareTotpUrls(String a, String b) {
    final pa = extractPlatformAndUser(a);
    final pb = extractPlatformAndUser(b);

    final platformCompare =
    pa.platform.compareTo(pb.platform);

    if (platformCompare != 0) return platformCompare;
    return pa.username.compareTo(pb.username);
  }

  static TotpMeta extractPlatformAndUser(String url) {
    final uri = Uri.parse(url);

    final label = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : '';

    String platform = '';
    String username = '';

    if (label.contains(':')) {
      final parts = label.split(':');
      platform = parts[0];
      username = parts.sublist(1).join(':');
    } else {
      platform = label;
    }

    final issuer = uri.queryParameters['issuer'];
    if (issuer != null && issuer.isNotEmpty) {
      platform = issuer;
    }

    return TotpMeta(
      platform.toLowerCase(),
      username.toLowerCase(),
    );
  }
}

class TotpMeta {
  final String platform;
  final String username;

  TotpMeta(this.platform, this.username);
}
