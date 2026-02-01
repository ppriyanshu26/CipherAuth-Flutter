import 'package:flutter/material.dart';
import '../utils/storage.dart';
import 'reset_password_screen.dart';
import 'sync_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const SettingsScreen({super.key, required this.onToggleTheme});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String? storedPasswordHash;

  @override
  void initState() {
    super.initState();
    loadTheme();
    loadPasswordHash();
  }

  Future<void> loadTheme() async {
    final dark = await Storage.isDarkMode();
    if (!mounted) return;
    setState(() => isDarkMode = dark);
  }

  Future<void> loadPasswordHash() async {
    final hash = await Storage.getStoredPassword();
    if (!mounted) return;
    setState(() => storedPasswordHash = hash);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
              leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Theme'),
              subtitle: Text(isDarkMode ? 'Dark Mode' : 'Light Mode'),
              onTap: toggleTheme,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Unlock with Biometrics'),
              subtitle: const Text('Unavailable'),
              enabled: false,
              onTap: null,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('View Password Hash'),
              subtitle: const Text('Debug: Show stored password hash'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Stored Password Hash'),
                    content: SingleChildScrollView(
                      child: SelectableText(
                        storedPasswordHash ?? 'No password set',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
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
                if (syncOccurred == true && mounted) {
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
