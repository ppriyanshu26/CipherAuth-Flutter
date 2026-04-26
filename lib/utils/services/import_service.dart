import 'dart:io';
import 'dart:convert';
import '../crypto/totp_store.dart';
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

  static Future<(bool, String, List<Map<String, String>>)>
  importFromEncryptedCsv(File file, String password) async {
    try {
      if (!await file.exists()) {
        return (false, 'File not found', <Map<String, String>>[]);
      }

      if (password.isEmpty) {
        return (false, 'Password is required', <Map<String, String>>[]);
      }

      final encryptedContent = await file.readAsString(encoding: utf8);
      late final String csvContent;
      try {
        csvContent = await CsvCrypto.decryptCsv(encryptedContent, password);
      } catch (_) {
        return (
          false,
          'Failed to decrypt file. Check password or file format.',
          <Map<String, String>>[],
        );
      }

      final rows = parseCsv(csvContent);

      if (rows.isEmpty) {
        return (false, 'CSV file is empty', <Map<String, String>>[]);
      }
      final dataRows = rows.sublist(1);
      if (dataRows.isEmpty) {
        return (false, 'No data rows found in CSV', <Map<String, String>>[]);
      }

      final existingCredentials = await TotpStore.load();
      final existingIds = existingCredentials.map((c) => c['id']).toSet();
      final newCredentials = <Map<String, String>>[];

      for (final row in dataRows) {
        if (row.length < 4) continue;

        final platform = row[1].trim();
        final username = row[2].trim();
        final secret = row[3].trim().toUpperCase();

        if (platform.isEmpty || username.isEmpty || secret.isEmpty) {
          continue;
        }
        final id = TotpStore.generateId(platform, username, secret);
        if (!existingIds.contains(id)) {
          newCredentials.add({
            'id': id,
            'platform': platform,
            'username': username,
            'secretcode': secret,
          });
        }
      }

      if (newCredentials.isEmpty) {
        return (
          true,
          'No new credentials found to import',
          <Map<String, String>>[],
        );
      }

      return (
        true,
        'Found ${newCredentials.length} new credential(s)',
        newCredentials,
      );
    } catch (e) {
      return (false, 'Import failed: ${e.toString()}', <Map<String, String>>[]);
    }
  }

  static Future<(bool, String)> addImportedCredentials(
    List<Map<String, String>> credentials,
  ) async {
    try {
      if (credentials.isEmpty) {
        return (false, 'No credentials to add');
      }

      final importTimestamp = TotpStore.getFormattedTimestamp();
      final stampedCredentials = credentials
          .map(
            (c) => {
              ...c,
              'createdAt': (c['createdAt'] == null || c['createdAt']!.isEmpty)
                  ? importTimestamp
                  : c['createdAt']!,
            },
          )
          .toList();

      final existing = await TotpStore.load();
      final combined = [...existing, ...stampedCredentials];
      combined.sort(
        (a, b) => a['platform']!.toLowerCase().compareTo(
          b['platform']!.toLowerCase(),
        ),
      );

      await TotpStore.saveAll(combined);

      final importedIds = stampedCredentials
          .map((c) => c['id'] ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      await TotpStore.clearTombstones(importedIds);

      return (
        true,
        'Successfully imported ${credentials.length} credential(s)',
      );
    } catch (e) {
      return (false, 'Failed to add credentials: ${e.toString()}');
    }
  }
}
