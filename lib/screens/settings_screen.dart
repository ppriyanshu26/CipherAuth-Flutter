import 'package:flutter/material.dart';
import '../utils/storage.dart';
import '../utils/export_service.dart';
import '../utils/biometric_service.dart';
import '../utils/runtime_key.dart';
import 'reset_password_screen.dart';
import 'sync_screen.dart';
import 'view_qr_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const SettingsScreen({super.key, required this.onToggleTheme});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool canUseBiometric = false;
  bool isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    loadTheme();
    loadBiometricStatus();
  }

  Future<void> loadTheme() async {
    final dark = await Storage.isDarkMode();
    if (!mounted) return;
    setState(() => isDarkMode = dark);
  }

  Future<void> loadBiometricStatus() async {
    final canUse = await BiometricService.canUseBiometrics();
    final isEnabled = await BiometricService.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      canUseBiometric = canUse;
      isBiometricEnabled = isEnabled;
    });
  }

  Future<void> toggleBiometric(bool value) async {
    if (value) {
      if (RuntimeKey.rawPassword != null) {
        final (success, error) = await BiometricService.enableBiometric(
          RuntimeKey.rawPassword!,
        );
        if (!mounted) return;
        if (success) {
          setState(() => isBiometricEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric unlock enabled'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          setState(() => isBiometricEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to enable biometric'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      try {
        await BiometricService.disableBiometric();
        setState(() => isBiometricEnabled = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric unlock disabled'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable biometric: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> toggleTheme() async {
    final newValue = !isDarkMode;
    setState(() => isDarkMode = newValue);
    await Storage.setDarkMode(newValue);
    widget.onToggleTheme();
  }

  Future<void> resetPassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> exportCredentials() async {
    final (success, message) = await ExportService.exportToCsv();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Reset Password'),
                    subtitle: const Text('Change your master password'),
                    onTap: resetPassword,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    ),
                    title: const Text('Theme'),
                    subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                    onTap: toggleTheme,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('Biometrics'),
                    subtitle: const Text(
                      'Unlock with your fingerprint or face',
                    ),
                    enabled: canUseBiometric,
                    trailing: Switch(
                      value: isBiometricEnabled,
                      onChanged: canUseBiometric ? toggleBiometric : null,
                    ),
                    onTap: canUseBiometric
                        ? () => toggleBiometric(!isBiometricEnabled)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sync to Devices'),
                    subtitle: const Text('Sync credentials with other devices'),
                    onTap: () async {
                      final syncOccurred = await Navigator.push<bool?>(
                        context,
                        MaterialPageRoute(builder: (_) => const SyncScreen()),
                      );
                      if (syncOccurred == true && mounted) {}
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: const Text('View QR'),
                    subtitle: const Text('Scan with any authenticator app'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ViewQrScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.upload),
                    title: const Text('Export Credentials'),
                    subtitle: const Text('Export your credentials to a file'),
                    onTap: exportCredentials,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    subtitle: const Text('About CipherAuth and features'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
