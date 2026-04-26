import 'package:crypto/crypto.dart';

class Totp {
  static String generate({
    required String secret,
    required int digits,
    required int period,
    required int time,
  }) {
    final key = _base32Decode(secret);
    var counter = time ~/ period;

    final data = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      data[i] = counter & 0xff;
      counter = counter >> 8;
    }

    final hmac = Hmac(sha1, key);
    final hash = hmac.convert(data).bytes;

    final offset = hash.last & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
    ((hash[offset + 1] & 0xff) << 16) |
    ((hash[offset + 2] & 0xff) << 8) |
    (hash[offset + 3] & 0xff);

    final otp = binary % pow10(digits);
    return otp.toString().padLeft(digits, '0');
  }

  static int pow10(int n) {
    var result = 1;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  static List<int> _base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    var bits = 0;
    var value = 0;
    final output = <int>[];

    final normalized = input
        .replaceAll(' ', '')
        .replaceAll('=', '')
        .toUpperCase();

    for (final char in normalized.split('')) {
      final index = alphabet.indexOf(char);
      if (index < 0) continue;

      value = (value << 5) | index;
      bits += 5;

      if (bits >= 8) {
        output.add((value >> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }

    return output;
  }
}
