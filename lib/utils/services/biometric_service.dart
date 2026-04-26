import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static const passStore = FlutterSecureStorage();
  static const bioKey = 'biometric_enabled';
  static const passKey = 'biometric_password';

  static final localAuth = LocalAuthentication();
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
      return (false, e.toString());
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
      return (false, 'No biometric authentication available on this device');
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
      return (false, 'Failed to enable biometric: ${e.toString()}');
    }
  }

  static Future<void> disableBiometric() async {
    await passStore.delete(key: bioKey);
    await passStore.delete(key: passKey);
  }

  static Future<void> updateBiometricPassword(
    String newPassword,
  ) async {
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
