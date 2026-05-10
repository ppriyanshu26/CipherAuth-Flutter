import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/crypto/password_store.dart';
import 'add_password_screen.dart';
import 'password_details_screen.dart';
import '../settingsScreen/settings_screen.dart';

class PasswordManagerScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const PasswordManagerScreen({super.key, required this.onToggleTheme});

  @override
  State<PasswordManagerScreen> createState() => PasswordManagerScreenState();
}

class PasswordManagerScreenState extends State<PasswordManagerScreen> {
  List<Map<String, String>> passwords = [];
  String searchQuery = '';
  late FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final list = await PasswordStore.load();
    setState(() => passwords = list);
  }

  Future<void> openAddOrEdit([Map<String, String>? existingItem]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPasswordScreen(existingPassword: existingItem),
      ),
    );
    
    if (result == 'added' || result == 'edited') {
      load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'added' 
                ? 'Password added successfully' 
                : 'Password updated successfully',
            style: const TextStyle(color: Colors.green),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      load();
    }
  }

  String _getGroupingLetter(String name) {
    var clean = name.trim().toUpperCase();
    if (clean.isEmpty) return '#';
    final firstChar = clean[0];
    if (firstChar.contains(RegExp(r'[A-Z]'))) {
      return firstChar;
    }
    return '#';
  }

  @override
  Widget build(BuildContext context) {
    final filteredPasswords = passwords.where((item) {
      final query = searchQuery.toLowerCase();
      final name = (item['name'] ?? '').toLowerCase();
      final domain = (item['domain'] ?? '').toLowerCase();
      return name.contains(query) || domain.contains(query);
    }).toList();

    final grouped = <String, List<Map<String, String>>>{};
    
    for (final item in filteredPasswords) {
      final name = item['name'] ?? '';
      final groupKey = _getGroupingLetter(name);
      
      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Manager'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              searchFocusNode.unfocus();
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  focusNode: searchFocusNode,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Search from ${passwords.length} ${passwords.length == 1 ? 'password' : 'passwords'}',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Expanded(
              child: passwords.isEmpty
                  ? const Center(child: Text('No passwords added'))
                  : searchQuery.isNotEmpty && filteredPasswords.isEmpty
                  ? const Center(child: Text('No passwords match your search'))
                  : ListView.builder(
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final key = sortedKeys[index];
                        final items = grouped[key]!;
                        
                        items.sort((a, b) {
                          var nameA = (a['name'] ?? '').toLowerCase();
                          var nameB = (b['name'] ?? '').toLowerCase();
                          return nameA.compareTo(nameB);
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Text(
                                key,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            ...items.map((item) {
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                elevation: 1,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                                    child: Text(
                                      key,
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(item['username'] ?? ''),
                                  onTap: () {
                                    final pass = item['password'] ?? '';
                                    Clipboard.setData(ClipboardData(text: pass));
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  onLongPress: () async {
                                    HapticFeedback.heavyImpact();
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PasswordDetailsScreen(passwordItem: item),
                                      ),
                                    );
                                    
                                    load();
                                    
                                    if (result == 'deleted') {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Password deleted',
                                            style: TextStyle(color: Colors.green),
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => openAddOrEdit(),
        backgroundColor: Colors.orange.withValues(alpha: 0.5),
        child: const Icon(Icons.add),
      ),
    );
  }
}