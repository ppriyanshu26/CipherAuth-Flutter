import 'dart:io';
import 'dart:convert';
import '../crypto/totp_store.dart';
import '../crypto/password_store.dart';
import '../crypto/csv_crypto.dart';

class ImportService {
  static List<List<String>> parseCsv(String content) {
    final lines = content.split('\n');
    final rows = <List<String>>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final row = <String>[];
      var current = '';
      var inQuotes = false;
      for (var i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
            current += '"';
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          row.add(current.trim());
          current = '';
        } else {
          current += char;
        }
      }
      if (current.isNotEmpty || line.endsWith(',')) {
        row.add(current.trim());
      }

      if (row.isNotEmpty) {
        rows.add(row);
      }
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
        return (false, 'Failed to decrypt file. Check password or file format.', <Map<String, String>>[], <Map<String, String>>[]);
      }

      final rows = parseCsv(csvContent);
      if (rows.isEmpty) {
        return (false, 'CSV file is empty', <Map<String, String>>[], <Map<String, String>>[]);
      }
      final dataRows = rows.sublist(1);
      if (dataRows.isEmpty) {
        return (false, 'No data rows found in CSV', <Map<String, String>>[], <Map<String, String>>[]);
      }

      final existingTotps = await TotpStore.load();
      final existingTotpIds = existingTotps.map((c) => c['id']).toSet();

      final existingPasswords = await PasswordStore.load();
      final existingPasswordKeys = existingPasswords.map((c) {
        final domain = (c['domain'] ?? '').trim().toLowerCase();
        final username = (c['username'] ?? '').trim().toLowerCase();
        return '$domain|$username';
      }).toSet();

      final newTotps = <Map<String, String>>[];
      final newPasswords = <Map<String, String>>[];
      for (final row in dataRows) {
        if (row.isNotEmpty && (row[0].toLowerCase() == 'totp' || row[0].toLowerCase() == 'password')) {
          final type = row[0].toLowerCase();
          final title = row.length > 2 ? row[2].trim() : '';
          final username = row.length > 3 ? row[3].trim() : '';
          final secretOrPass = row.length > 4 ? row[4].trim() : '';
          final domain = row.length > 5 ? row[5].trim() : '';
          final notes = row.length > 6 ? row[6].trim() : '';

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
              });
            }
          } else if (type == 'password') {
            if (title.isEmpty || username.isEmpty || secretOrPass.isEmpty || domain.isEmpty) continue;

            final passwordKey =
                '${domain.trim().toLowerCase()}|${username.trim().toLowerCase()}';
            if (!existingPasswordKeys.contains(passwordKey)) {
              final createdAtMillis =
                  DateTime.now().millisecondsSinceEpoch + newPasswords.length;
              newPasswords.add({
                'id': PasswordStore.generateId(createdAtMillis),
                'name': title,
                'domain': domain,
                'username': username,
                'password': secretOrPass,
                'notes': notes,
              });
            }
          }
        } else if (row.length >= 4) {
          final platform = row[1].trim();
          final username = row[2].trim();
          final secret = row[3].trim().toUpperCase();
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
    } catch (e) {
      return (false, 'Import failed: ${e.toString()}', <Map<String, String>>[], <Map<String, String>>[]);
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
              (c) => {
                ...c,
                'createdAt': (c['createdAt'] == null || c['createdAt']!.isEmpty)
                    ? importTimestamp
                    : c['createdAt']!,
                'updatedAt': importTimestamp,
              },
        ).toList();

        final existing = await PasswordStore.load();
        final combined = [...existing, ...stampedPasswords];
        combined.sort(
          (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
            (b['name'] ?? '').toLowerCase(),
          ),
        );

        await PasswordStore.saveAll(combined);
        final importedIds = stampedPasswords
            .map((c) => c['id'] ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        await PasswordStore.removeFromRecycleBinEntries(importedIds);
      }

      return (true, 'Import successfully completed.');
    } catch (e) {
      return (false, 'Failed to add credentials: ${e.toString()}');
    }
  }
}