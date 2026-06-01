import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'crypto.dart';

class PasswordStore {
  static const storeKey = 'password_store';
  static const recycleBinKey = 'password_recycle_bin';
  static const recycleBinRetentionMillis = 30*24*60*60*1000;

  static String generateId(int createdAtMillis) => sha256.convert(utf8.encode(createdAtMillis.toString())).toString();

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
        year = 2000+int.parse(datePart.substring(4, 6));
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

  static int getDeletedAtMillis(Map<String, String> item) => int.tryParse(item['deletedAt'] ?? '') ?? 0;

  static int getFreshnessMillis(Map<String, String> item) {
    final createdAt = parseTimestampToMillis(item['createdAt'] ?? '');
    final updatedAt = parseTimestampToMillis(item['updatedAt'] ?? '');
    return createdAt > updatedAt ? createdAt : updatedAt;
  }

  static int comparePasswordRows(Map<String, String> a, Map<String, String> b) {
    final freshnessA = getFreshnessMillis(a);
    final freshnessB = getFreshnessMillis(b);
    if (freshnessA != freshnessB) return freshnessA.compareTo(freshnessB);

    final updatedA = parseTimestampToMillis(a['updatedAt'] ?? '');
    final updatedB = parseTimestampToMillis(b['updatedAt'] ?? '');
    if (updatedA != updatedB) return updatedA.compareTo(updatedB);

    final createdA = parseTimestampToMillis(a['createdAt'] ?? '');
    final createdB = parseTimestampToMillis(b['createdAt'] ?? '');
    if (createdA != createdB) return createdA.compareTo(createdB);

    final idA = (a['id'] ?? '').toLowerCase();
    final idB = (b['id'] ?? '').toLowerCase();
    if (idA != idB) return idA.compareTo(idB);
    return 0;
  }

  static Map<String, String> selectPreferredPasswordRow(
    List<Map<String, String>> rows,
  ) {
    var preferred = Map<String, String>.from(rows.first);

    for (var i = 1; i < rows.length; i++) {
      final candidate = Map<String, String>.from(rows[i]);
      if (comparePasswordRows(candidate, preferred) >= 0) {
        preferred = candidate;
      }
    }

    return preferred;
  }

  static List<Map<String, String>> dedupePasswordRowsByLogicalKey(
    List<Map<String, String>> rows,
  ) {
    final groupedRows = <String, List<Map<String, String>>>{};

    for (final row in rows) {
      final id = row['id'] ?? '';
      if (id.isEmpty) continue;

      groupedRows
          .putIfAbsent(id, () => <Map<String, String>>[])
          .add(Map<String, String>.from(row));
    }

    final merged = <Map<String, String>>[];
    for (final rowsForKey in groupedRows.values) {
      merged.add(selectPreferredPasswordRow(rowsForKey));
    }
    return merged;
  }

  static Map<String, String> normalizeActiveEntry(Map<String, dynamic> e) {
    return {
      'id': (e['id'] ?? '').toString(),
      'name': (e['name'] ?? '').toString(),
      'domain': (e['domain'] ?? '').toString(),
      'username': (e['username'] ?? '').toString(),
      'password': (e['password'] ?? '').toString(),
      'notes': (e['notes'] ?? '').toString(),
      'createdAt': (e['createdAt'] ?? '').toString(),
      'updatedAt': (e['updatedAt'] ?? '').toString(),
    };
  }

  static Map<String, String> normalizeRecycleBinEntry(Map<String, dynamic> e) {
    final normalized = normalizeActiveEntry(e);
    normalized['deletedAt'] = (e['deletedAt'] ?? '').toString();
    return normalized;
  }

  static List<Map<String, String>> mergeRecycleBins(
    List<Map<String, String>> localBin,
    List<Map<String, String>> remoteBin,
  ) {
    final merged = <String, Map<String, String>>{};

    void putEntry(Map<String, String> entry) {
      final id = entry['id'] ?? '';
      if (id.isEmpty) return;

      final incoming = Map<String, String>.from(entry);
      final existing = merged[id];
      if (existing == null) {
        merged[id] = incoming;
        return;
      }

      final existingDeletedAt = getDeletedAtMillis(existing);
      final incomingDeletedAt = getDeletedAtMillis(incoming);
      if (incomingDeletedAt > existingDeletedAt) {
        merged[id] = incoming;
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

  static List<Map<String, String>> mergePasswordRowsByLogicalKey(List<Map<String, String>> localRows, List<Map<String, String>> remoteRows) {
    return dedupePasswordRowsByLogicalKey([...localRows, ...remoteRows]);
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

  static int getCurrentTimestampMillis() => DateTime.now().millisecondsSinceEpoch;

  static Future<List<Map<String, String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(storeKey);
    if (encrypted == null || encrypted.isEmpty) return [];

    try {
      final decrypted = await Crypto.decryptAes(encrypted);
      final decoded = jsonDecode(decrypted) as List<dynamic>;
      final credentials = dedupePasswordRowsByLogicalKey(decoded
          .whereType<Map>()
          .map((e) => normalizeActiveEntry(e.cast<String, dynamic>()))
          .where((e) => e['id']!.isNotEmpty)
          .toList());

      final recycleBin = await getRecycleBin(purgeExpired: true);
      final recycleBinMap = <String, int>{
        for (final item in recycleBin)
          if ((item['id'] ?? '').isNotEmpty)
            item['id']!: getDeletedAtMillis(item),
      };

      final resurrectedIds = <String>[];
      final filtered = <Map<String, String>>[];

      for (final cred in credentials) {
        final id = cred['id'] ?? '';
        if (id.isEmpty) continue;

        final deletedAt = recycleBinMap[id] ?? 0;
        if (deletedAt <= 0) {
          filtered.add(cred);
          continue;
        }

        final updatedAt = parseTimestampToMillis(
          cred['updatedAt'] ?? cred['createdAt'] ?? '',
        );
        if (updatedAt > deletedAt) {
          resurrectedIds.add(id);
          filtered.add(cred);
        }
      }

      if (resurrectedIds.isNotEmpty) {
        await removeFromRecycleBinEntries(resurrectedIds);
      }

      return filtered;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, String>>> getRecycleBin({bool purgeExpired = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(recycleBinKey);
    if (encrypted == null || encrypted.isEmpty) return [];

    try {
      final decrypted = await Crypto.decryptAes(encrypted);
      final decoded = jsonDecode(decrypted) as List<dynamic>;
      final rawList = decoded
          .whereType<Map>()
          .map((e) => normalizeRecycleBinEntry(e.cast<String, dynamic>()))
          .toList();
      final deduped = mergeRecycleBins(const [], rawList);

      final now = getCurrentTimestampMillis();
      final kept = <Map<String, String>>[];
      var changed = false;

      for (final e in deduped) {
        final deletedAt = getDeletedAtMillis(e) == 0
            ? now
            : getDeletedAtMillis(e);

        if (purgeExpired && (now - deletedAt >= recycleBinRetentionMillis)) {
          changed = true;
          continue;
        }
        kept.add({
          'id': (e['id'] ?? '').toString(),
          'name': (e['name'] ?? '').toString(),
          'domain': (e['domain'] ?? '').toString(),
          'username': (e['username'] ?? '').toString(),
          'password': (e['password'] ?? '').toString(),
          'notes': (e['notes'] ?? '').toString(),
          'createdAt': (e['createdAt'] ?? '').toString(),
          'updatedAt': (e['updatedAt'] ?? '').toString(),
          'deletedAt': deletedAt.toString(),
        });
      }

      if (changed || kept.length != rawList.length) {
        final newEncrypted = await Crypto.encryptAes(jsonEncode(kept));
        await prefs.setString(recycleBinKey, newEncrypted);
      }
      return kept;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRecyclleBin(List<Map<String, String>> items) async {
    final encrypted = await Crypto.encryptAes(jsonEncode(items));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(recycleBinKey, encrypted);
  }

  static Future<void> saveRecycleBin(List<Map<String, String>> items) async {
    await saveRecyclleBin(items);
  }

  static Future<void> removeFromRecycleBinEntries(List<String> ids) async {
    if (ids.isEmpty) return;
    final bin = await getRecycleBin(purgeExpired: false);
    final idSet = ids.toSet();
    final updated = bin.where((e) => !idSet.contains(e['id'])).toList();
    if (updated.length != bin.length) {
      await saveRecyclleBin(updated);
    }
  }

  static Future<void> saveAll(List<Map<String, String>> items) async {
    final encrypted = await Crypto.encryptAes(jsonEncode(items));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storeKey, encrypted);
  }

  static Future<void> saveAllAndMerge(List<Map<String, String>> remoteActive, List<Map<String, String>> remoteRecycleBin) async {
    final localActive = await load();
    final localRecycleBin = await getRecycleBin(purgeExpired: true);
    final mergedRowsByKey = mergePasswordRowsByLogicalKey([...localActive, ...localRecycleBin], [...remoteActive, ...remoteRecycleBin]);

    final finalActive = <Map<String, String>>[];
    final finalRecycleBin = <Map<String, String>>[];

    for (final item in mergedRowsByKey) {
      if ((item['deletedAt'] ?? '').isNotEmpty) {
        finalRecycleBin.add(item);
      } else {
        finalActive.add(item);
      }
    }

    finalActive.sort(
      (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
        (b['name'] ?? '').toLowerCase(),
      ),
    );
    finalRecycleBin.sort((a, b) => getDeletedAtMillis(b).compareTo(getDeletedAtMillis(a)));
    await saveAll(finalActive);
    await saveRecyclleBin(finalRecycleBin);
  }

  static Future<String?> add( String name, String domain, String username, String password, String notes) async {
    final list = await load();
    final createdAtMillis = getCurrentTimestampMillis();
    final id = generateId(createdAtMillis);
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
    await removeFromRecycleBinEntries([id]);
    return id;
  }

  static Future<String?> update( String oldId, String name, String domain, String username, String password, String notes) async {
    final list = await load();
    final index = list.indexWhere((e) => e['id'] == oldId);
    if (index == -1) return null;

    final item = list[index];
    final now = getFormattedTimestamp();

    list[index] = {
      'id': oldId,
      'name': name,
      'domain': domain,
      'username': username,
      'password': password,
      'notes': notes,
      'createdAt': item['createdAt'] ?? getFormattedTimestamp(),
      'updatedAt': now,
    };

    await saveAll(list);
    await removeFromRecycleBinEntries([oldId]);
    return oldId;
  }

  static Future<void> moveToRecycleBinAndDeleteById(String id) async {
    if (id.isEmpty) return;
    final current = await load();
    final index = current.indexWhere((e) => e['id'] == id);
    if (index == -1) return;

    final item = current[index];
    item['deletedAt'] = getCurrentTimestampMillis().toString();

    final bin = await getRecycleBin(purgeExpired: true);
    final merged = mergeRecycleBins(bin, [item]);
    await saveRecyclleBin(merged);

    current.removeAt(index);
    await saveAll(current);
  }

  static Future<bool> restoreFromRecycleBin(String id) async {
    if (id.isEmpty) return false;
    final bin = await getRecycleBin(purgeExpired: true);
    final index = bin.indexWhere((e) => e['id'] == id);
    if (index == -1) return false;

    final item = bin[index];
    final active = await load();
    bin.removeAt(index);
    await saveRecyclleBin(bin);

    item['updatedAt'] = getFormattedTimestamp();
    item.remove('deletedAt');
    final current = active;
    current.removeWhere((e) => e['id'] == id);
    current.add(item);
    await saveAll(current);
    return true;
  }

  static Future<bool> deletePermanentlyFromRecycleBin(String id) async {
    if (id.isEmpty) return false;
    final bin = await getRecycleBin(purgeExpired: true);
    final index = bin.indexWhere((e) => e['id'] == id);
    if (index == -1) return false;

    bin.removeAt(index);
    await saveRecyclleBin(bin);

    final current = await load();
    final filtered = current.where((e) => e['id'] != id).toList();
    if (filtered.length != current.length) {
      await saveAll(filtered);
    }
    return true;
  }
}