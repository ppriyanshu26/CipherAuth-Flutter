import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static const passStore = FlutterSecureStorage();
  static const bioKey = 'biometric_enabled';
  static const passKey = 'biometric_password';

  static final localAuth = LocalAuthentication();

  static String getBiometricError(dynamic error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();

      switch (code) {
        case 'notavailable':
          return 'Biometric authentication is not available on this device';
        case 'notsetup':
          return 'No biometric data (fingerprint/face) is enrolled on this device. Please set up biometrics in your device settings.';
        case 'nodevicecredential':
          return 'Device lock (PIN, pattern, or password) is required to use biometric authentication. Please set up a device lock first.';
        case 'nocredential':
          return 'No device credentials are set. Please set up a device lock first.';
        case 'permanentlylockedout':
          return 'Too many failed biometric attempts. Please try again later.';
        case 'lockedout':
          return 'Biometric is temporarily locked. Please try again later.';
        case 'notavailable_or_notsetup':
          return 'Biometric data is not set up on this device';
        default:
          return error.message ?? 'Biometric authentication failed';
      }
    }
    return error.toString();
  }

  static Future<bool> canUseBiometrics() async {
    try {
      return await localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<(bool authenticated, String? error)>
  authenticateWithError() async {
    try {
      final result = await localAuth.authenticate(
        localizedReason: 'Unlock CipherAuth with your biometric',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      return (result, null);
    } catch (e) {
      return (false, getBiometricError(e));
    }
  }

  static Future<bool> authenticate() async {
    final (result, _) = await authenticateWithError();
    return result;
  }

  static Future<(bool success, String? error)> enableBiometric(
    String masterPassword,
  ) async {
    if (!await canUseBiometrics()) {
      return (
        false,
        'No biometric data enrolled. Please set up a fingerprint or face in your device settings, and ensure your device has a lock screen PIN, pattern, or password.',
      );
    }
    final (authenticated, authError) = await authenticateWithError();
    if (!authenticated) {
      return (false, authError ?? 'Biometric authentication failed');
    }
    try {
      await passStore.write(key: passKey, value: masterPassword);
      await passStore.write(key: bioKey, value: 'true');
      return (true, null);
    } catch (e) {
      return (false, getBiometricError(e));
    }
  }

  static Future<void> disableBiometric() async {
    await passStore.delete(key: bioKey);
    await passStore.delete(key: passKey);
  }

  static Future<void> updateBiometricPassword(String newPassword) async {
    if (await isBiometricEnabled()) {
      await passStore.write(key: passKey, value: newPassword);
    }
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await passStore.read(key: bioKey);
    return value == 'true';
  }

  static Future<String?> getStoredMasterPassword() async {
    return await passStore.read(key: passKey);
  }
}
