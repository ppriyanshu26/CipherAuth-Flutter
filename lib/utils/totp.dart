import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';

class Totp {
  static String generate({
    required String secret,
    required int digits,
    required int period,
    required int time,
  }) {
    final key = base32.decode(secret.replaceAll('=', ''));

    final counter = (time ~/ period);
    final data = ByteData(8)..setInt64(0, counter, Endian.big);

    final hmac = Hmac(sha1, key);
    final hash = hmac.convert(data.buffer.asUint8List()).bytes;

    final offset = hash.last & 0x0f;

    final binary = ((hash[offset] & 0x7f) << 24) |
    ((hash[offset + 1] & 0xff) << 16) |
    ((hash[offset + 2] & 0xff) << 8) |
    (hash[offset + 3] & 0xff);

    final otp = binary % (pow10(digits));

    return otp.toString().padLeft(digits, '0');
  }

  static int pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
