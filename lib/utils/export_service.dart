import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'totp_store.dart';

class ExportService {
  static Future<(bool, String)> exportToCsv() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (status.isDenied) {
            return (
              false,
              'Storage permission denied. Please allow access in settings.',
            );
          } else if (status.isPermanentlyDenied) {
            return (
              false,
              'Storage permission permanently denied. Please enable in app settings.',
            );
          }
          return (false, 'Storage permission required to export.');
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted && !status.isDenied) {
          return (false, 'Permission required to export files.');
        }
      }

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

      Directory? directory;
      String locationName = 'Downloads';
      try {
        if (Platform.isAndroid) {
          final extStorage = await getExternalStorageDirectory();
          if (extStorage != null) {
            final publicDownloads = Directory('/storage/emulated/0/Download');
            if (await publicDownloads.exists()) {
              directory = publicDownloads;
              locationName = 'Downloads';
            } else {
              directory = await getApplicationDocumentsDirectory();
              locationName = 'Documents';
            }
          }
        } else {
          directory = await getDownloadsDirectory();
          if (directory != null) {
            locationName = 'Downloads';
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
      if (!await directory!.exists()) {
        await directory.create(recursive: true);
      }

      final filename =
          'CipherAuth.csv';
      final filepath = File('${directory.path}/$filename');
      await filepath.writeAsString(csvContent, encoding: utf8);

      return (true, 'File saved to $locationName folder');
    } catch (e) {
      return (false, 'Export failed: ${e.toString()}');
    }
  }
}
