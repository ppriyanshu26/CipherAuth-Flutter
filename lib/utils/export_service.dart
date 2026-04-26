import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'totp_store.dart';
import 'runtime_key.dart';
import 'csv_crypto.dart';

class ExportService {
  static String _buildDefaultFilename() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return 'CipherAuth_${now.year}$month$day$hour$minute$second.csv';
  }

  static Future<(bool, String)> exportToCsv() async {
    try {
      final credentials = await TotpStore.load();
      if (credentials.isEmpty) {
        return (false, 'No credentials to export');
      }
      final csvRows = <List<String>>[];
      csvRows.add(['ID', 'Platform', 'Username', 'Secret', 'TOTP URL']);

      for (final cred in credentials) {
        csvRows.add([
          cred['id'] ?? '',
          cred['platform'] ?? '',
          cred['username'] ?? '',
          cred['secretcode'] ?? '',
          'otpauth://totp/${cred['platform']}:${cred['username']}?secret=${cred['secretcode']}',
        ]);
      }
      final csvContent = csvRows
          .map(
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
      final filename = Platform.isAndroid || Platform.isWindows
          ? _buildDefaultFilename()
          : 'CipherAuth.csv';
      final csvBytes = Uint8List.fromList(utf8.encode(encryptedContent));

      if (Platform.isAndroid || Platform.isIOS) {
        final savedLocation = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV Export',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: csvBytes,
        );

        if (savedLocation == null || savedLocation.isEmpty) {
          return (false, 'Export cancelled');
        }

        return (true, 'File saved successfully');
      }

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV Export',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (savePath == null || savePath.isEmpty) {
          return (false, 'Export cancelled');
        }

        final file = File(savePath);
        await file.writeAsBytes(csvBytes, flush: true);
        return (true, 'File saved successfully');
      }

      Directory? directory;
      try {
        if (Platform.isAndroid) {
          directory =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        } else {
          directory = await getDownloadsDirectory();
          if (directory != null) {
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        }
      } catch (e) {
        try {
          directory = await getApplicationDocumentsDirectory();
        } catch (e) {
          directory = await getTemporaryDirectory();
        }
      }
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filepath = File('${directory.path}/$filename');
      await filepath.writeAsString(encryptedContent, encoding: utf8);

      return (true, 'File saved successfully');
    } catch (e) {
      return (false, 'Export failed: ${e.toString()}');
    }
  }
}
