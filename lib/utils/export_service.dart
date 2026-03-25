import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'totp_store.dart';

class ExportService {
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

      final filename = 'CipherAuth.csv';
      final csvBytes = Uint8List.fromList(utf8.encode(csvContent));

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

        return (true, 'File saved: $savedLocation');
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
        return (true, 'File saved: ${file.path}');
      }

      Directory? directory;
      String locationName = 'app storage';
      try {
        if (Platform.isAndroid) {
          directory =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
          locationName = 'app storage';
        } else {
          directory = await getDownloadsDirectory();
          if (directory != null) {
            locationName = 'Downloads';
          } else {
            directory = await getApplicationDocumentsDirectory();
            locationName = 'Documents';
          }
        }
      } catch (e) {
        try {
          directory = await getApplicationDocumentsDirectory();
          locationName = 'Documents';
        } catch (e) {
          directory = await getTemporaryDirectory();
          locationName = 'temp';
        }
      }
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filepath = File('${directory.path}/$filename');
      await filepath.writeAsString(csvContent, encoding: utf8);

      return (true, 'File saved to $locationName: ${filepath.path}');
    } catch (e) {
      return (false, 'Export failed: ${e.toString()}');
    }
  }
}
