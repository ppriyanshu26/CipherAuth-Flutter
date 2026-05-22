import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../crypto/totp_store.dart';
import '../crypto/password_store.dart';
import '../crypto/runtime_key.dart';
import '../crypto/csv_crypto.dart';

class ExportService {
  static String defaultExportFilename() => buildDefaultFilename();

  static String defaultExportBaseName() => buildDefaultFilename().replaceFirst(RegExp(r'\.csv$'), '');

  static Future<bool> hasExportableCredentials() async {
    final totpCredentials = await TotpStore.load();
    final passwordCredentials = await PasswordStore.load();
    return totpCredentials.isNotEmpty || passwordCredentials.isNotEmpty;
  }

  static String buildDefaultFilename() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return 'CipherAuth_${now.year}$month$day$hour$minute$second.csv';
  }

  static String? normalizeFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    
    final safeName = trimmed.endsWith('.csv') ? trimmed : '$trimmed.csv';
    if (safeName.contains(RegExp(r'[<>:"/\\|?*]'))) {
      return null;
    }
    return safeName;
  }

  static Future<(bool, String)> exportToCsv({String? fileName}) async {
    try {
      final totpCredentials = await TotpStore.load();
      final passwordCredentials = await PasswordStore.load();

      if (totpCredentials.isEmpty && passwordCredentials.isEmpty) {
        return (false, 'No credentials to export');
      }
      final csvRows = <List<String>>[];
      csvRows.add(['Type', 'ID', 'Title/Platform', 'Username', 'Secret/Password', 'URL/Domain', 'Notes', 'TOTP URL']);
      for (final cred in totpCredentials) {
        csvRows.add([
          'totp',
          cred['id'] ?? '',
          cred['platform'] ?? '',
          cred['username'] ?? '',
          cred['secretcode'] ?? '',
          '',
          '',
          'otpauth://totp/${cred['platform']}:${cred['username']}?secret=${cred['secretcode']}',
        ]);
      }
      for (final pass in passwordCredentials) {
        csvRows.add([
          'password',
          pass['id'] ?? '',
          pass['name'] ?? '',
          pass['username'] ?? '',
          pass['password'] ?? '',
          pass['domain'] ?? '',
          pass['notes'] ?? '',
          '',
        ]);
      }

      final csvContent = csvRows.map(
            (row) => row
                .map((field) => '"${field.replaceAll('"', '""')}"')
                .join(','),
          )
          .join('\n');

      final password = RuntimeKey.rawPassword;
      if (password == null || password.isEmpty) {
        return (false, 'Session password unavailable. Please sign in again.');
      }

      final encryptedContent = await CsvCrypto.encryptCsv(csvContent, password);
      final csvBytes = Uint8List.fromList(utf8.encode(encryptedContent));

      if (!Platform.isWindows && !Platform.isAndroid) {
        final normalizedName = normalizeFileName(
          fileName ?? buildDefaultFilename(),
        );
        if (normalizedName == null) {
          return (false, 'Invalid file name');
        }

        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV Export',
          fileName: normalizedName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: csvBytes,
        );

        if (savePath == null || savePath.isEmpty) {
          return (false, 'Export cancelled');
        }
        return (true, 'File saved successfully');
      }

      final normalizedName = normalizeFileName(
        fileName ?? buildDefaultFilename(),
      );
      if (normalizedName == null) {
        return (false, 'Invalid file name');
      }

      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory == null) {
        return (false, 'Downloads directory unavailable');
      }

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      final file = File(
        '${downloadsDirectory.path}${Platform.pathSeparator}$normalizedName',
      );
      if (await file.exists()) {
        return (false, 'A file with this name already exists.');
      }
      await file.writeAsBytes(csvBytes, flush: true);
      return (true, 'File saved successfully');
    } catch (_) {
      return (false, 'Export failed');
    }
  }
}
