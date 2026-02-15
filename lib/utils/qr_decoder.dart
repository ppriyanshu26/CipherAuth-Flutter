import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

class QRDecoder {
  static Future<String> decodeFromFile(String imagePath) async {
    if (imagePath.isEmpty) {
      throw Exception('Image path is empty');
    }
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image file');
    }
    final pixels = image.getBytes(order: img.ChannelOrder.argb);
    final int32Pixels = Int32List.view(pixels.buffer);

    final luminance = RGBLuminanceSource(image.width, image.height, int32Pixels,);
    final bitmap = BinaryBitmap(HybridBinarizer(luminance));
    final reader = QRCodeReader();
    final result = reader.decode(bitmap);

    if (result.text.isEmpty) {
      throw Exception('No QR code found in image');
    }

    return result.text;
  }
}
