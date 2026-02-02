import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/totp_store.dart';
import '../utils/totp.dart';
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
  String searchQuery = '';
  late FocusNode searchFocusNode = FocusNode();
  bool isSearching = false;

  Timer? timer;
  int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    load();
    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus && isSearching) {
        setState(() {
          isSearching = false;
          searchQuery = '';
        });
      }
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    searchFocusNode.dispose();
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

  Future<void> deleteSelected() async {
    if (selected.isEmpty) return;

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
    final filteredTotps = totps.where((item) {
      final platform = item['platform']?.toLowerCase() ?? '';
      return platform.startsWith(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isSearching = false;
                        searchQuery = '';
                      });
                      searchFocusNode.unfocus();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      focusNode: searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search platforms...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.only(left: 8),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            : const Text('CipherAuth'),
        actions: [
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = true;
                });
                searchFocusNode.requestFocus();
              },
            ),
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
      body: GestureDetector(
        onTap: () {
          searchFocusNode.unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: totps.isEmpty
                  ? const Center(child: Text('No accounts added'))
                  : filteredTotps.isEmpty
                  ? const Center(child: Text('No platforms match your search'))
                  : ListView.builder(
                      itemCount: filteredTotps.length,
                      itemBuilder: (_, i) => tile(i, filteredTotps[i]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: selectionMode
          ? null
          : FloatingActionButton(
              heroTag: 'add',
              onPressed: addAccount,
              child: const Icon(Icons.add),
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
