import 'dart:io';
import 'dart:convert';
import '../crypto/totp_store.dart';
import '../crypto/password_store.dart';
import '../crypto/csv_crypto.dart';

class ImportService {
  static List<List<String>> parseCsv(String content) {
    final rows = <List<String>>[];
    var row = <String>[];
    var current = '';
    var inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"') {
        if (inQuotes && i + 1 < content.length && content[i + 1] == '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(current.trim());
        current = '';
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
        if (row.isNotEmpty || current.trim().isNotEmpty) {
          row.add(current.trim());
          rows.add(row);
        }
        row = <String>[];
        current = '';
      } else {
        current += char;
      }
    }
    if (row.isNotEmpty || current.trim().isNotEmpty) {
      row.add(current.trim());
      rows.add(row);
    }
    return rows;
  }

  static Future<(bool, String, List<Map<String, String>>, List<Map<String, String>>)> importFromEncryptedCsv(File file, String password) async {
    try {
      if (!await file.exists()) {
        return (false, 'File not found', <Map<String, String>>[], <Map<String, String>>[]);
      }

      if (password.isEmpty) {
        return (false, 'Password is required', <Map<String, String>>[], <Map<String, String>>[]);
      }

      final encryptedContent = await file.readAsString(encoding: utf8);
      late final String csvContent;
      try {
        csvContent = await CsvCrypto.decryptCsv(encryptedContent, password);
      } catch (_) {
        return (false, 'Failed to decrypt file', <Map<String, String>>[], <Map<String, String>>[]);
      }

      final rows = parseCsv(csvContent);
      if (rows.isEmpty) {
        return (false, 'CSV file is empty', <Map<String, String>>[], <Map<String, String>>[]);
      }
      final expectedColumnCount = rows.first.length;
      final dataRows = rows.sublist(1);
      if (dataRows.isEmpty) {
        return (false, 'No data rows found in CSV', <Map<String, String>>[], <Map<String, String>>[]);
      }

      final headers = rows.first.map((h) => h.trim().toLowerCase()).toList();

      int getIndex(List<String> headers, List<String> aliases, int defaultIndex) {
        for (final alias in aliases) {
          final idx = headers.indexOf(alias);
          if (idx != -1) return idx;
        }
        return defaultIndex;
      }

      final typeIdx = getIndex(headers, ['type'], 0);
      final idIdx = getIndex(headers, ['id'], 1);
      final titleIdx = getIndex(headers, ['title/platform', 'platform', 'title'], 2);
      final usernameIdx = getIndex(headers, ['username', 'user'], 3);
      final secretIdx = getIndex(headers, ['secret/password', 'password', 'secret', 'secretcode'], 4);
      final domainIdx = getIndex(headers, ['url/domain', 'domain', 'url'], 5);
      final notesIdx = getIndex(headers, ['notes', 'note'], 6);
      final createdAtIdx = getIndex(headers, ['created at', 'createdat'], 7);
      final updatedAtIdx = getIndex(headers, ['updated at', 'updatedat'], 8);
      final linkedTotpIdx = getIndex(headers, ['linked totp id', 'linkedtotpid'], 10);

      List<String> padRow(List<String> row) {
        if (row.length >= expectedColumnCount) return row;
        return [...row, ...List<String>.filled(expectedColumnCount - row.length, '')];
      }

      String getValue(List<String> row, int index) {
        if (index >= 0 && index < row.length) {
          return row[index].trim();
        }
        return '';
      }

      final existingTotps = await TotpStore.load();
      final existingTotpIds = existingTotps.map((c) => c['id']).toSet();

      final existingPasswords = await PasswordStore.load();
      final existingPasswordIds = existingPasswords.map((c) => c['id']).toSet();

      final newTotps = <Map<String, String>>[];
      final newPasswords = <Map<String, String>>[];
      for (final row in dataRows) {
        final paddedRow = padRow(row);

        final type = getValue(paddedRow, typeIdx).toLowerCase();
        if (paddedRow.isNotEmpty && (type == 'totp' || type == 'password')) {
          final title = getValue(paddedRow, titleIdx);
          final username = getValue(paddedRow, usernameIdx);
          final secretOrPass = getValue(paddedRow, secretIdx);
          final domain = getValue(paddedRow, domainIdx);
          final notes = getValue(paddedRow, notesIdx);
          final csvId = getValue(paddedRow, idIdx);
          final createdAt = getValue(paddedRow, createdAtIdx);
          final updatedAt = getValue(paddedRow, updatedAtIdx);
          final linkedTotpId = getValue(paddedRow, linkedTotpIdx);

          if (type == 'totp') {
            final secret = secretOrPass.toUpperCase();
            if (title.isEmpty || username.isEmpty || secret.isEmpty) continue;

            final id = TotpStore.generateId(title, username, secret);
            if (!existingTotpIds.contains(id)) {
              newTotps.add({
                'id': id,
                'platform': title,
                'username': username,
                'secretcode': secret,
                'createdAt': createdAt,
              });
            }
          } else if (type == 'password') {
            if (title.isEmpty || username.isEmpty || secretOrPass.isEmpty || domain.isEmpty) continue;

            if (csvId.isNotEmpty && existingPasswordIds.contains(csvId)) continue;

            final createdAtMillis = DateTime.now().millisecondsSinceEpoch+newPasswords.length;
            newPasswords.add({
              'id': csvId.isNotEmpty ? csvId : PasswordStore.generateId(createdAtMillis),
              'name': title,
              'domain': domain,
              'username': username,
              'password': secretOrPass,
              'notes': notes,
              'linkedTotpId': linkedTotpId,
              'createdAt': createdAt,
              'updatedAt': updatedAt,
            });
          }
        } else if (paddedRow.length >= 4) {
          final platform = getValue(paddedRow, 1);
          final username = getValue(paddedRow, 2);
          final secret = getValue(paddedRow, 3).toUpperCase();
          if (platform.isEmpty || username.isEmpty || secret.isEmpty) continue;

          final id = TotpStore.generateId(platform, username, secret);
          if (!existingTotpIds.contains(id)) {
            newTotps.add({
              'id': id,
              'platform': platform,
              'username': username,
              'secretcode': secret,
            });
          }
        }
      }

      if (newTotps.isEmpty && newPasswords.isEmpty) {
        return (
          true,
          'No new credentials found to import',
          <Map<String, String>>[],
          <Map<String, String>>[],
        );
      }

      return (true, 'Found ${newTotps.length} new authenticator(s) and ${newPasswords.length} new password(s)', newTotps, newPasswords);
    } catch (_) {
      return (false, 'Import failed', <Map<String, String>>[], <Map<String, String>>[]);
    }
  }

  static Future<(bool, String)> addImportedCredentials(List<Map<String, String>> totps, List<Map<String, String>> passwords) async {
    try {
      if (totps.isEmpty && passwords.isEmpty) {
        return (false, 'No credentials to add');
      }

      if (totps.isNotEmpty) {
        final importTimestamp = TotpStore.getFormattedTimestamp();
        final stampedTotps = totps.map(
              (c) => {
                ...c,
                'createdAt': (c['createdAt'] == null || c['createdAt']!.isEmpty)
                    ? importTimestamp
                    : c['createdAt']!,
              },
        ).toList();

        final existing = await TotpStore.load();
        final combined = [...existing, ...stampedTotps];
        combined.sort(
          (a, b) => a['platform']!.toLowerCase().compareTo(
            b['platform']!.toLowerCase(),
          ),
        );

        await TotpStore.saveAll(combined);
        final importedIds = stampedTotps
            .map((c) => c['id'] ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        await TotpStore.clearTombstones(importedIds);
      }

      if (passwords.isNotEmpty) {
        final importTimestamp = PasswordStore.getFormattedTimestamp();
        final stampedPasswords = passwords.map(
              (c) {
                final createdAt = (c['createdAt'] ?? '').trim();
                final updatedAt = (c['updatedAt'] ?? '').trim();
                final resolvedCreatedAt = createdAt.isEmpty ? importTimestamp : createdAt;
                return {
                  ...c,
                  'createdAt': resolvedCreatedAt,
                  'updatedAt': updatedAt.isEmpty ? resolvedCreatedAt : updatedAt,
                };
              },
            )
            .toList();
        final importedIds = stampedPasswords
            .map((c) => c['id'] ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        await PasswordStore.removeFromRecycleBinEntries(importedIds);
        await PasswordStore.saveAllAndMerge(stampedPasswords, const []);
      }

      return (true, 'Import successfully completed');
    } catch (_) {
      return (false, 'Failed to add credentials');
    }
  }
}