import 'package:flutter/services.dart';

enum AppFlavor { prod, sample }

class AppFlavorConfig {
  static const MethodChannel _channel = MethodChannel('cipherauth/flavor');

  static AppFlavor appType = AppFlavor.prod;
  static bool isInitialized = false;

  static Future<void> initialize() async {
    if (isInitialized) return;

    try {
      final flavor = await _channel.invokeMethod<String>('getFlavor');
      if ((flavor ?? '').toLowerCase() == 'sample') {
        appType = AppFlavor.sample;
      }
    } catch (_) {
      appType = AppFlavor.prod;
    }

    isInitialized = true;
  }

  static AppFlavor get current => appType;

  static bool get isSample => appType == AppFlavor.sample;

  static String get aboutTitle => isSample ? 'CipherAuth Test' : 'CipherAuth';
}
