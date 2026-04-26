import 'dart:convert';

class SyncMerge {
  static List<Map<String, String>> mergeCredentials(
    List<Map<String, String>> localCreds,
    List<Map<String, String>> remoteCreds,
  ) {
    final merged = <String, Map<String, String>>{};
    for (final cred in localCreds) {
      final id = cred['id'];
      if (id != null) {
        merged[id] = Map.from(cred);
      }
    }
    for (final cred in remoteCreds) {
      final id = cred['id'];
      if (id != null) {
        merged[id] = Map.from(cred);
      }
    }
    final list = merged.values.toList();
    list.sort((a, b) {
      final platformA = (a['platform'] ?? '').toLowerCase();
      final platformB = (b['platform'] ?? '').toLowerCase();
      return platformA.compareTo(platformB);
    });

    return list;
  }

  static String credentialsToJson(List<Map<String, String>> credentials) {
    return jsonEncode(credentials);
  }

  static List<Map<String, String>> jsonToCredentials(String json) {
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map<Map<String, String>>((e) {
        return {
          'id': e['id'] as String? ?? '',
          'platform': e['platform'] as String? ?? '',
          'username': e['username'] as String? ?? '',
          'secretcode': e['secretcode'] as String? ?? '',
          'createdAt': e['createdAt'] as String? ?? '',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
