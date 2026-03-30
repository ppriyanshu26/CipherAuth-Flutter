import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/storage.dart';
import '../utils/export_service.dart';
import '../utils/import_service.dart';
import '../utils/biometric_service.dart';
import '../utils/runtime_key.dart';
import '../utils/app_lifecycle_manager.dart';
import 'reset_password_screen.dart';
import 'sync_screen.dart';
import 'view_qr_screen.dart';
import 'about_screen.dart';
import 'support_screen.dart';

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
              content: Text(error ?? 'Failed to enable biometric', style: const TextStyle(color: Colors.red)),
              duration: const Duration(seconds: 2),
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
        setState(() => isBiometricEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable biometric', style: const TextStyle(color: Colors.red)),
            duration: const Duration(seconds: 2),
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
        content: Text(message, style: TextStyle(color: success ? Colors.green : Colors.red)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> importCredentials() async {
    try {
      AppLifecycleManager.preventPasswordClear = true;
      AppLifecycleManager.suppressReauthOnResume = true;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      if (result.files.single.path == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to access selected file'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final importPassword = await askImportPassword();
      if (!mounted || importPassword == null) {
        return;
      }

      if (importPassword.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import password is required'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final file = File(result.files.single.path!);
      final (success, message, newCreds) =
          await ImportService.importFromEncryptedCsv(file, importPassword);

      if (!mounted) return;

      if (success && newCreds.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Credentials'),
            content: Text(
              'Found ${newCreds.length} new credential(s).\n\nDo you want to import them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final (added, addMessage) =
              await ImportService.addImportedCredentials(newCreds);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(addMessage, style: TextStyle(color: added ? Colors.green : Colors.red)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(color: Colors.red)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      AppLifecycleManager.preventPasswordClear = false;
      AppLifecycleManager.suppressReauthOnResume = false;
    }
  }

  Future<String?> askImportPassword() async {
    final controller = TextEditingController();
    var isVisible = false;

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Import Password'),
              content: TextField(
                controller: controller,
                obscureText: !isVisible,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        isVisible = !isVisible;
                      });
                    },
                  ),
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      controller.dispose();
    });
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), scrolledUnderElevation: 0),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Display', style: Theme.of(context).textTheme.titleMedium),
                ),
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Security', style: Theme.of(context).textTheme.titleMedium),
                ),
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Sync & Share', style: Theme.of(context).textTheme.titleMedium),
                ),
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Backup', style: Theme.of(context).textTheme.titleMedium),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.upload),
                    title: const Text('Export Credentials'),
                    subtitle: const Text('Export your credentials to a CSV file'),
                    onTap: exportCredentials,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Import Credentials'),
                    subtitle: const Text('Import credentials from a CSV file'),
                    onTap: importCredentials,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('About', style: Theme.of(context).textTheme.titleMedium),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Support'),
                    subtitle: const Text('View policy and contact support'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About CipherAuth'),
                    subtitle: const Text('Learn about the app'),
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
