import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'crypto.dart';

class TotpStore {
  static const storeKey = 'totp_store';
  static const deletionLogKey = 'totp_deletion_log';
  static const recycleBinKey = 'totp_recycle_bin';
  static const recycleBinRetentionMillis = 30 * 24 * 60 * 60 * 1000;

  static String generateId(String platform, String username, String secret) {
    final input = '$platform$username$secret';
    return sha256.convert(input.codeUnits).toString();
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

  static int getCurrentTimestampMillis() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  static int parseTimestampToMillis(String timestamp) {
    try {
      final parts = timestamp.split(' ');
      if (parts.length != 2) return 0;
      final datePart = parts[0];
      final timePart = parts[1];
      if (timePart.length != 6) return 0;
      final day = int.parse(datePart.substring(0, 2));
      final month = int.parse(datePart.substring(2, 4));

      int year;
      if (datePart.length == 8) {
        year = int.parse(datePart.substring(4, 8));
      } else if (datePart.length == 6) {
        year = 2000 + int.parse(datePart.substring(4, 6));
      } else {
        return 0;
      }

      final hour = int.parse(timePart.substring(0, 2));
      final minute = int.parse(timePart.substring(2, 4));
      final second = int.parse(timePart.substring(4, 6));
      final dateTime = DateTime(year, month, day, hour, minute, second);
      return dateTime.millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }

  static Future<Map<String, int>> getDeletionLog() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(deletionLogKey);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      return {};
    }
  }

  static Future<void> trackDeletedIdsWithTimestamp(
    Map<String, int> deletedIds,
  ) async {
    if (deletedIds.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await getDeletionLog();
    for (final entry in deletedIds.entries) {
      final current = existing[entry.key];
      if (current == null || entry.value > current) {
        existing[entry.key] = entry.value;
      }
    }
    await prefs.setString(deletionLogKey, jsonEncode(existing));
  }

  static Future<void> trackDeletedIds(List<String> deletedIds) async {
    if (deletedIds.isEmpty) return;
    final timestamp = getCurrentTimestampMillis();
    final mapped = <String, int>{};
    for (final id in deletedIds) {
      mapped[id] = timestamp;
    }
    await trackDeletedIdsWithTimestamp(mapped);
  }

  static Future<void> removeFromDeletionLog(List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = await getDeletionLog();
    for (final id in ids) {
      existing.remove(id);
    }
    await prefs.setString(deletionLogKey, jsonEncode(existing));
  }

  static Future<void> clearTombstones(Iterable<String> ids) async {
    final list = ids.where((e) => e.isNotEmpty).toList();
    await removeFromDeletionLog(list);
    await removeFromRecycleBinEntries(list);
  }

  static Future<List<String>> getDeletedIds() async {
    final deletionLog = await getDeletionLog();
    return deletionLog.keys.toList();
  }

  static int getDeletedAtMillis(Map<String, String> item) {
    final deletedAt = item['deletedAt'] ?? '';
    final fromInt = int.tryParse(deletedAt);
    if (fromInt != null) return fromInt;
    return parseTimestampToMillis(deletedAt);
  }

  static Map<String, String> normalizeCredential(Map<String, dynamic> e) {
    return {
      'id': (e['id'] ?? '').toString(),
      'platform': (e['platform'] ?? '').toString(),
      'username': (e['username'] ?? '').toString(),
      'secretcode': (e['secretcode'] ?? '').toString(),
      'createdAt': (e['createdAt'] ?? '').toString(),
    };
  }

  static Map<String, String> normalizeRecycleBinEntry(Map<String, dynamic> e) {
    final normalized = normalizeCredential(e);
    final deletedAt = (e['deletedAt'] ?? '').toString();
    var parsedDeletedAt =
        int.tryParse(deletedAt) ?? parseTimestampToMillis(deletedAt);
    if (parsedDeletedAt <= 0) {
      parsedDeletedAt = getCurrentTimestampMillis();
    }
    normalized['deletedAt'] = parsedDeletedAt.toString();
    return normalized;
  }

  static Future<void> saveDeletionLog(Map<String, int> deletionLog) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(deletionLogKey, jsonEncode(deletionLog));
  }

  static Future<void> _saveActiveCredentials(
    List<Map<String, String>> items,
  ) async {
    final encrypted = await Crypto.encryptAes(jsonEncode(items));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }

  static Future<List<Map<String, String>>> _loadRecycleBinRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(recycleBinKey);
    if (encrypted == null || encrypted.isEmpty) return [];

    try {
      final decrypted = await Crypto.decryptAes(encrypted);
      final decoded = jsonDecode(decrypted) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => normalizeRecycleBinEntry(e.cast<String, dynamic>()))
          .where((e) => (e['id'] ?? '').isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveRecycleBinRaw(
    List<Map<String, String>> items,
  ) async {
    final encrypted = await Crypto.encryptAes(jsonEncode(items));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(recycleBinKey, encrypted);
  }

  static List<Map<String, String>> mergeRecycleBins(
    List<Map<String, String>> localBin,
    List<Map<String, String>> remoteBin,
  ) {
    final merged = <String, Map<String, String>>{};

    void putEntry(Map<String, String> entry) {
      final id = entry['id'] ?? '';
      if (id.isEmpty) return;

      final incoming = normalizeRecycleBinEntry(entry);
      final existing = merged[id];
      if (existing == null) {
        merged[id] = incoming;
        return;
      }

      final existingDeletedAt = getDeletedAtMillis(existing);
      final incomingDeletedAt = getDeletedAtMillis(incoming);

      if (incomingDeletedAt > 0 &&
          (existingDeletedAt <= 0 || incomingDeletedAt < existingDeletedAt)) {
        merged[id] = {
          'id': id,
          'platform': incoming['platform']!.isNotEmpty
              ? incoming['platform']!
              : existing['platform']!,
          'username': incoming['username']!.isNotEmpty
              ? incoming['username']!
              : existing['username']!,
          'secretcode': incoming['secretcode']!.isNotEmpty
              ? incoming['secretcode']!
              : existing['secretcode']!,
          'createdAt': incoming['createdAt']!.isNotEmpty
              ? incoming['createdAt']!
              : existing['createdAt']!,
          'deletedAt': incomingDeletedAt.toString(),
        };
      }
    }

    for (final entry in localBin) {
      putEntry(entry);
    }
    for (final entry in remoteBin) {
      putEntry(entry);
    }

    final list = merged.values.toList();
    list.sort((a, b) => getDeletedAtMillis(b).compareTo(getDeletedAtMillis(a)));
    return list;
  }

  static Future<void> removeFromRecycleBinEntries(List<String> ids) async {
    if (ids.isEmpty) return;
    final existing = await _loadRecycleBinRaw();
    final idSet = ids.toSet();
    final updated = existing.where((e) => !idSet.contains(e['id'])).toList();
    await _saveRecycleBinRaw(updated);
  }

  static Future<List<Map<String, String>>> getRecycleBin({
    bool purgeExpired = true,
  }) async {
    final raw = await _loadRecycleBinRaw();
    final deduped = mergeRecycleBins(raw, const <Map<String, String>>[]);

    if (!purgeExpired) {
      return deduped;
    }

    final now = getCurrentTimestampMillis();
    final kept = <Map<String, String>>[];
    final purgedIds = <String>[];

    for (final item in deduped) {
      final deletedAt = getDeletedAtMillis(item);
      if (deletedAt <= 0 || now - deletedAt >= recycleBinRetentionMillis) {
        final id = item['id'] ?? '';
        if (id.isNotEmpty) {
          purgedIds.add(id);
        }
      } else {
        kept.add(item);
      }
    }

    if (purgedIds.isNotEmpty || kept.length != raw.length) {
      await _saveRecycleBinRaw(kept);
      await removeFromDeletionLog(purgedIds);
    }

    return kept;
  }

  static Future<void> addToRecycleBin(
    List<Map<String, String>> items, {
    int? deletedAtMillis,
  }) async {
    if (items.isEmpty) return;

    final now = deletedAtMillis ?? getCurrentTimestampMillis();
    final entries = <Map<String, String>>[];
    final deletionMap = <String, int>{};

    for (final item in items) {
      final normalized = normalizeCredential(item);
      final id = normalized['id'] ?? '';
      if (id.isEmpty) continue;

      final entry = {...normalized, 'deletedAt': now.toString()};
      entries.add(entry);
      deletionMap[id] = now;
    }

    if (entries.isEmpty) return;

    final existing = await getRecycleBin(purgeExpired: true);
    final merged = mergeRecycleBins(existing, entries);
    await _saveRecycleBinRaw(merged);
    await trackDeletedIdsWithTimestamp(deletionMap);
  }

  static Future<void> moveToRecycleBinAndDeleteByIds(List<String> ids) async {
    if (ids.isEmpty) return;

    final idSet = ids.where((e) => e.isNotEmpty).toSet();
    if (idSet.isEmpty) return;

    final current = await load();
    final deletedItems = current
        .where((item) => idSet.contains(item['id']))
        .toList();
    if (deletedItems.isEmpty) return;

    await addToRecycleBin(deletedItems);

    final remaining = current
        .where((item) => !idSet.contains(item['id']))
        .toList();
    await saveAll(remaining);
  }

  static Future<bool> deletePermanentlyFromRecycleBin(String id) async {
    if (id.isEmpty) return false;
    await removeFromRecycleBinEntries([id]);
    await removeFromDeletionLog([id]);

    final active = await load();
    final filtered = active.where((e) => e['id'] != id).toList();
    if (filtered.length != active.length) {
      await _saveActiveCredentials(filtered);
    }
    return true;
  }

  static Future<bool> restoreFromRecycleBin(String id) async {
    if (id.isEmpty) return false;
    final recycleBin = await getRecycleBin(purgeExpired: true);
    Map<String, String>? entry;
    for (final item in recycleBin) {
      if (item['id'] == id) {
        entry = item;
        break;
      }
    }

    if (entry == null) return false;

    final active = await load();
    final restored = {
      'id': entry['id'] ?? '',
      'platform': entry['platform'] ?? '',
      'username': entry['username'] ?? '',
      'secretcode': entry['secretcode'] ?? '',
      'createdAt': getFormattedTimestamp(),
    };

    final updated = active.where((e) => e['id'] != id).toList();
    updated.add(restored);
    updated.sort(
      (a, b) => (a['platform'] ?? '').toLowerCase().compareTo(
        (b['platform'] ?? '').toLowerCase(),
      ),
    );

    await _saveActiveCredentials(updated);
    await removeFromRecycleBinEntries([id]);
    await removeFromDeletionLog([id]);
    return true;
  }

  static Future<List<Map<String, String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(storeKey);

    if (encrypted == null || encrypted.isEmpty) return [];

    final decrypted = await Crypto.decryptAes(encrypted);
    final decoded = jsonDecode(decrypted) as List<dynamic>;
    final credentials = decoded
        .whereType<Map>()
        .map((e) => normalizeCredential(e.cast<String, dynamic>()))
        .where((e) => (e['id'] ?? '').isNotEmpty)
        .toList();

    final recycleBin = await getRecycleBin(purgeExpired: true);
    final recycleBinMap = <String, int>{
      for (final item in recycleBin)
        if ((item['id'] ?? '').isNotEmpty)
          item['id']!: getDeletedAtMillis(item),
    };
    final deletionLog = await getDeletionLog();

    final resurrectedIds = <String>[];
    final filtered = <Map<String, String>>[];
    for (final cred in credentials) {
      final id = cred['id'] ?? '';
      if (id.isEmpty) continue;
      final deletedAt = recycleBinMap[id] ?? deletionLog[id] ?? 0;
      if (deletedAt <= 0) {
        filtered.add(cred);
        continue;
      }

      final createdAt = parseTimestampToMillis(cred['createdAt'] ?? '');
      if (createdAt > deletedAt) {
        resurrectedIds.add(id);
        filtered.add(cred);
      }
    }

    if (resurrectedIds.isNotEmpty) {
      final cleanedBin = recycleBin
          .where((item) => !resurrectedIds.contains(item['id']))
          .toList();
      await _saveRecycleBinRaw(cleanedBin);
      await removeFromDeletionLog(resurrectedIds);
    }

    return filtered;
  }

  static Future<bool> add(String platform, String url) async {
    final list = await load();

    final uri = Uri.parse(url);
    final rawPath = uri.path;
    final label = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;
    final decodedLabel = Uri.decodeComponent(label).trim();

    String username = '';
    if (decodedLabel.contains(':')) {
      final separator = decodedLabel.indexOf(':');
      username = decodedLabel.substring(separator + 1).trim();
    } else {
      // Account-only labels are valid otpauth format.
      username = decodedLabel;
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

    final id = generateId(platform, username, secret);
    final newItem = {
      'id': id,
      'platform': platform,
      'username': username,
      'secretcode': secret,
      'createdAt': getFormattedTimestamp(),
    };

    list.add(newItem);

    list.sort(
      (a, b) =>
          a['platform']!.toLowerCase().compareTo(b['platform']!.toLowerCase()),
    );

    final encrypted = await Crypto.encryptAes(jsonEncode(list));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
    await removeFromDeletionLog([id]);
    await removeFromRecycleBinEntries([id]);

    return true;
  }

  static Future<void> saveAll(List<Map<String, String>> items) async {
    final currentList = await load();
    final currentIds = {
      for (final item in currentList)
        if (item['id'] != null) item['id']!,
    };
    final newIds = {
      for (final item in items)
        if (item['id'] != null) item['id']!,
    };
    final deletedIds = currentIds.difference(newIds).toList();

    if (deletedIds.isNotEmpty) {
      await trackDeletedIds(deletedIds);
    }

    await _saveActiveCredentials(items);
  }

  static Future<void> saveAllAndMerge(
    List<Map<String, String>> items,
    Map<String, int> remoteDeletedIds,
    List<Map<String, String>> remoteRecycleBin,
  ) async {
    final currentList = await load();
    final currentIds = {
      for (final item in currentList)
        if ((item['id'] ?? '').isNotEmpty) item['id']!,
    };
    final incomingIds = {
      for (final item in items)
        if ((item['id'] ?? '').isNotEmpty) item['id']!,
    };
    final locallyDeletedIds = currentIds.difference(incomingIds).toList();

    final mergedDeletionLog = await getDeletionLog();
    final now = getCurrentTimestampMillis();
    for (final id in locallyDeletedIds) {
      mergedDeletionLog[id] = now;
    }
    for (final entry in remoteDeletedIds.entries) {
      final existing = mergedDeletionLog[entry.key];
      if (existing == null || entry.value > existing) {
        mergedDeletionLog[entry.key] = entry.value;
      }
    }

    final localRecycleBin = await getRecycleBin(purgeExpired: true);
    var mergedRecycleBin = mergeRecycleBins(localRecycleBin, remoteRecycleBin);

    for (final entry in mergedRecycleBin) {
      final id = entry['id'] ?? '';
      if (id.isEmpty) continue;
      final deletedAt = getDeletedAtMillis(entry);
      final existing = mergedDeletionLog[id];
      if (existing == null || deletedAt > existing) {
        mergedDeletionLog[id] = deletedAt;
      }
    }

    final mergedById = <String, Map<String, String>>{};
    for (final item in items) {
      final normalized = normalizeCredential(item);
      final id = normalized['id'] ?? '';
      if (id.isEmpty) continue;
      final existing = mergedById[id];
      if (existing == null) {
        mergedById[id] = normalized;
        continue;
      }
      final existingCreatedAt = parseTimestampToMillis(
        existing['createdAt'] ?? '',
      );
      final incomingCreatedAt = parseTimestampToMillis(
        normalized['createdAt'] ?? '',
      );
      if (incomingCreatedAt > existingCreatedAt) {
        mergedById[id] = normalized;
      }
    }

    final recycleDeletedAtById = <String, int>{
      for (final item in mergedRecycleBin)
        if ((item['id'] ?? '').isNotEmpty)
          item['id']!: getDeletedAtMillis(item),
    };

    final resurrectedIds = <String>[];
    final filteredItems = <Map<String, String>>[];
    for (final item in mergedById.values) {
      final id = item['id'] ?? '';
      if (id.isEmpty) continue;
      final deletedAt = recycleDeletedAtById[id] ?? mergedDeletionLog[id] ?? 0;
      if (deletedAt <= 0) {
        filteredItems.add(item);
        continue;
      }
      final createdAt = parseTimestampToMillis(item['createdAt'] ?? '');
      if (createdAt > deletedAt) {
        resurrectedIds.add(id);
        filteredItems.add(item);
      }
    }

    if (resurrectedIds.isNotEmpty) {
      mergedRecycleBin = mergedRecycleBin
          .where((entry) => !resurrectedIds.contains(entry['id']))
          .toList();
      for (final id in resurrectedIds) {
        mergedDeletionLog.remove(id);
      }
    }

    final nowMs = getCurrentTimestampMillis();
    final expiredIds = <String>[];
    mergedRecycleBin = mergedRecycleBin.where((entry) {
      final id = entry['id'] ?? '';
      final deletedAt = getDeletedAtMillis(entry);
      final expired =
          deletedAt <= 0 || nowMs - deletedAt >= recycleBinRetentionMillis;
      if (expired && id.isNotEmpty) {
        expiredIds.add(id);
      }
      return !expired;
    }).toList();

    for (final id in expiredIds) {
      mergedDeletionLog.remove(id);
    }

    filteredItems.sort(
      (a, b) => (a['platform'] ?? '').toLowerCase().compareTo(
        (b['platform'] ?? '').toLowerCase(),
      ),
    );

    await _saveActiveCredentials(filteredItems);
    await saveDeletionLog(mergedDeletionLog);
    await _saveRecycleBinRaw(mergedRecycleBin);
  }
}
