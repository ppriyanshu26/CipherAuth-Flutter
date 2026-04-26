import 'crypto.dart';

class CsvCrypto {
  static const header = 'CIPHERAUTH-ENC-V1';

  static Future<String> encryptCsv(String csvContent, String password) async {
    final encrypted = await Crypto.encryptAesWithPassword(csvContent, password);
    return '$header\n$encrypted';
  }

  static Future<String> decryptCsv(String fileContent, String password) async {
    if (!fileContent.startsWith('$header\n')) {
      throw const FormatException('Invalid encrypted export file');
    }

    final encryptedPayload = fileContent
        .substring(header.length + 1)
        .trim();
    if (encryptedPayload.isEmpty) {
      throw const FormatException('Encrypted payload is empty');
    }

    return Crypto.decryptAesWithPassword(encryptedPayload, password);
  }
}
