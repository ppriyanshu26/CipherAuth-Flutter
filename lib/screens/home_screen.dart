import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/totp_store.dart';
import '../utils/totp.dart';
import '../utils/storage.dart';
import 'add_account_screen.dart';
import 'settings_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> totps = [];
  Set<int> selected = {};
  bool selectionMode = false;

  Timer? timer;
  int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final list = await TotpStore.load();
    setState(() => totps = list);
  }

  Future<void> addAccount() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (changed == true) load();
  }

  Future<bool> confirmPassword() async {
    final ctrl = TextEditingController();
    bool ok = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm password'),
        content: TextField(controller: ctrl, obscureText: true),
        actions: [
          TextButton(
            onPressed: () async {
              ok = await Storage.verifyMasterPassword(ctrl.text);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return ok;
  }

  Future<void> deleteSelected() async {
    if (selected.isEmpty) return;

    final ok = await confirmPassword();
    if (!ok) return;

    final remaining = <Map<String, String>>[];
    for (int i = 0; i < totps.length; i++) {
      if (!selected.contains(i)) remaining.add(totps[i]);
    }

    await TotpStore.saveAll(remaining);

    setState(() {
      totps = remaining;
      selected.clear();
      selectionMode = false;
    });
  }

  Future<void> showCiphertext() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('totp_store');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stored Ciphertext'),
        content: SingleChildScrollView(
          child: SelectableText(
            raw ?? 'null',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (raw != null) {
                Clipboard.setData(ClipboardData(text: raw));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ciphertext copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget tile(int index, Map<String, String> item) {
    final user = item['username'] ?? '';
    final secret = item['secretcode']!;
    final digits = 6;
    final period = 30;

    try {
      final code = Totp.generate(
        secret: secret,
        digits: digits,
        period: period,
        time: now,
      );

      final remaining = period - (now % period);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('TOTP copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete credential?'),
                content: Text('Delete ${item['platform']} - $user?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final ok = await confirmPassword();
                      if (!ok) return;

                      final remaining = <Map<String, String>>[];
                      for (int i = 0; i < totps.length; i++) {
                        if (i != index) remaining.add(totps[i]);
                      }

                      await TotpStore.saveAll(remaining);

                      setState(() {
                        totps = remaining;
                      });

                      if (!mounted) return;
                      Navigator.pop(context);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Credential deleted'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          child: ListTile(
            leading: selectionMode
                ? Checkbox(
                    value: selected.contains(index),
                    onChanged: (_) {
                      setState(() {
                        selected.contains(index)
                            ? selected.remove(index)
                            : selected.add(index);
                      });
                    },
                  )
                : null,
            title: Text(
              item['platform']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user),
            trailing: selectionMode
                ? null
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$remaining s',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
            onTap: selectionMode
                ? () {
                    setState(() {
                      selected.contains(index)
                          ? selected.remove(index)
                          : selected.add(index);
                    });
                  }
                : null,
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          leading: selectionMode
              ? Checkbox(
                  value: selected.contains(index),
                  onChanged: (_) {
                    setState(() {
                      selected.contains(index)
                          ? selected.remove(index)
                          : selected.add(index);
                    });
                  },
                )
              : null,
          title: Text(
            item['platform']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Error generating TOTP - try resetting password',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          trailing: selectionMode
              ? null
              : const Icon(Icons.error_outline, color: Colors.red),
          onTap: selectionMode
              ? () {
                  setState(() {
                    selected.contains(index)
                        ? selected.remove(index)
                        : selected.add(index);
                  });
                }
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(onToggleTheme: widget.onToggleTheme),
                ),
              );
              load();
            },
          ),
        ],
      ),
      body: totps.isEmpty
          ? const Center(child: Text('No accounts added'))
          : ListView.builder(
              itemCount: totps.length,
              itemBuilder: (_, i) => tile(i, totps[i]),
            ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            left: 32,
            bottom: 0,
            child: FloatingActionButton(
              heroTag: 'debug',
              mini: true,
              onPressed: showCiphertext,
              child: const Icon(Icons.code),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: selectionMode
                ? const SizedBox.shrink()
                : FloatingActionButton(
                    heroTag: 'add',
                    onPressed: addAccount,
                    child: const Icon(Icons.add),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: selectionMode
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectionMode = false;
                          selected.clear();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: deleteSelected,
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
