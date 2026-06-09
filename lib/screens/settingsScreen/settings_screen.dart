import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/services/storage_service.dart';
import '../../utils/services/export_service.dart';
import '../../utils/services/import_service.dart';
import '../../utils/services/biometric_service.dart';
import '../../utils/crypto/runtime_key.dart';
import '../../utils/ui/app_lifecycle_manager.dart';
import 'reset_password_screen.dart';
import 'sync_screen.dart';
import 'view_qr_screen.dart';
import 'about_screen.dart';
import 'support_screen.dart';
import 'recycle_bin_screen.dart';
import '../../widgets/app_snackbars.dart';

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
  bool isAutofillServiceSelected = false;

  @override
  void initState() {
    super.initState();
    loadTheme();
    loadBiometricStatus();
    loadAutofillStatus();
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

  Future<void> loadAutofillStatus() async {
    if (!Platform.isAndroid) return;
    try {
      const channel = MethodChannel('cipherauth/autofill');
      final selected =
          await channel.invokeMethod<bool>('isAutofillEnabled') ?? false;
      if (!mounted) return;
      setState(() {
        isAutofillServiceSelected = selected;
      });
    } catch (_) {}
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
          if (Platform.isAndroid) {
            try {
              await const MethodChannel('cipherauth/autofill').invokeMethod(
                'enableBiometricAutofill',
                {'password': RuntimeKey.rawPassword!},
              );
            } catch (_) {}
          }
          if (!mounted) return;
          AppSnackBars.showCustomSnackBar(context: context, message: 'Biometric unlock enabled', textColor: Colors.blue);
        } else {
          setState(() => isBiometricEnabled = false);
          AppSnackBars.showCustomSnackBar(context: context, message: error ?? 'Failed to enable biometric', textColor: Colors.red);
        }
      }
    } else {
      try {
        await BiometricService.disableBiometric();
        setState(() => isBiometricEnabled = false);
        if (Platform.isAndroid) {
          try {
            await const MethodChannel(
              'cipherauth/autofill',
            ).invokeMethod('disableBiometricAutofill');
          } catch (_) {}
        }
        if (!mounted) return;
        AppSnackBars.showCustomSnackBar(context: context, message: 'Biometric unlock disabled', textColor: Colors.blue);
      } catch (e) {
        if (!mounted) return;
        setState(() => isBiometricEnabled = true);
        AppSnackBars.showCustomSnackBar(context: context, message: 'Failed to disable biometric', textColor: Colors.red);
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
      AppSnackBars.showCustomSnackBar(context: context, message: 'Password reset successfully', textColor: Colors.greenAccent.shade700);
    }
  }

  Future<void> exportCredentials() async {
    final hasCredentials = await ExportService.hasExportableCredentials();
    if (!hasCredentials) {
      if (!mounted) return;
      AppSnackBars.showCustomSnackBar(context: context, message: 'No credentials to export', textColor: Colors.red);
      return;
    }

    final (success, message) = await ExportService.exportToCsv();
    if (!mounted) return;

    if (success) {
      AppSnackBars.showCustomSnackBar(context: context, message: message, textColor: Colors.greenAccent.shade700);
    } else {
      AppSnackBars.showCustomSnackBar(context: context,  message: message, textColor: Colors.red);
    }
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
        AppSnackBars.showCustomSnackBar(context: context, message: 'Failed to access file', textColor: Colors.red);
        return;
      }

      await Future.delayed(const Duration(milliseconds: 250));
      final importPassword = await askImportPassword();
      if (!mounted || importPassword == null) {
        if (!mounted) return;
        if (importPassword == null) {
          AppSnackBars.showCustomSnackBar(context: context, message: 'Password input cancelled', textColor: Colors.red);
        }
        return;
      }

      final file = File(result.files.single.path!);
      final (success, message, newTotps, newPasswords) = await ImportService.importFromEncryptedCsv(file, importPassword);

      if (!mounted) return;

      if (success && (newTotps.isNotEmpty || newPasswords.isNotEmpty)) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Credentials'),
            content: Text('Found ${newTotps.length} new authenticator(s) and ${newPasswords.length} new password(s).\n\nDo you want to import them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (!mounted) return;
        if (confirmed == true) {
          final (added, addMessage,) = await ImportService.addImportedCredentials(newTotps, newPasswords);
          if (!mounted) return;
          AppSnackBars.showCustomSnackBar(context: context, message: addMessage, textColor: added ? Colors.greenAccent.shade700 : Colors.red);
        } else {
          AppSnackBars.showCustomSnackBar(context: context, message: 'Import cancelled', textColor: Colors.red);
        }
      } else {
        AppSnackBars.showCustomSnackBar(context: context, message: message, textColor: Colors.red);
      }
    } finally {
      AppLifecycleManager.preventPasswordClear = false;
      AppLifecycleManager.suppressReauthOnResume = false;
    }
  }

  Future<String?> askImportPassword() async {
    final controller = TextEditingController();
    var isVisible = false;
    String? errorText;

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
                  errorText: errorText,
                  suffixIcon: IconButton(
                    icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
                    tooltip: isVisible ? 'Hide Password' : 'Show Password',
                    onPressed: () {
                      setDialogState(() {
                        isVisible = !isVisible;
                      });
                    },
                  ),
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },
                onSubmitted: (value) {
                  final password = value.trim();
                  if (password.isEmpty) {
                    setDialogState(() {
                      errorText = 'Password cannot be empty';
                    });
                    return;
                  }

                  Navigator.pop(context, password);
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final password = controller.text.trim();
                    if (password.isEmpty) {
                      setDialogState(() {
                        errorText = 'Password cannot be empty';
                      });
                      return;
                    }

                    Navigator.pop(context, password);
                  },
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
                  child: Text('Management', style: Theme.of(context).textTheme.titleMedium),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                    title: const Text('Theme'),
                    subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
                    onTap: toggleTheme,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Recycle Bin'),
                    subtitle: const Text('Manage deleted credentials up to 30 days'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                      );
                    },
                  ),
                ),
                if (Platform.isAndroid) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.vpn_key),
                      title: const Text('Android Autofill'),
                      subtitle: Text(isAutofillServiceSelected ? 'CipherAuth is your default provider' : 'Select CipherAuth as default provider'),
                      trailing: isAutofillServiceSelected ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        if (isAutofillServiceSelected) {
                          AppSnackBars.showCustomSnackBar(context: context, message: 'Open phone settings to change autofill', textColor: Colors.blue);
                        } else {
                          const channel = MethodChannel('cipherauth/autofill');
                          await channel.invokeMethod('openAutofillSettings');
                        }
                      },
                    ),
                  ),
                ],
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
                    subtitle: const Text('Use your device to unlock'),
                    enabled: canUseBiometric,
                    trailing: Switch(value: isBiometricEnabled, onChanged: canUseBiometric ? toggleBiometric : null),
                    onTap: canUseBiometric ? () => toggleBiometric(!isBiometricEnabled) : null,
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
                        MaterialPageRoute(builder: (_) => const SupportScreen()),
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
