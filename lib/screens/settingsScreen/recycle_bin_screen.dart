import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/crypto/totp.dart';
import '../../utils/crypto/totp_store.dart';
import '../../utils/crypto/password_store.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => RecycleBinScreenState();
}

class RecycleBinScreenState extends State<RecycleBinScreen> {
  List<Map<String, String>> recycleBinItems = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterType = 'all';

  @override
  void initState() {
    super.initState();
    loadRecycleBin();
  }

  Future<void> loadRecycleBin() async {
    final totps = await TotpStore.getRecycleBin(purgeExpired: true);
    final passwords = await PasswordStore.getRecycleBin(purgeExpired: true);
    final combined = <Map<String, String>>[
      ...totps.map((e) => {...e, 'itemType': 'totp'}),
      ...passwords.map((e) => {...e, 'itemType': 'password'}),
    ];

    combined.sort((a, b) {
      int dA = 0;
      int dB = 0;
      
      if (a['itemType'] == 'totp') {
        dA = TotpStore.getDeletedAtMillis(a);
      } else {
        dA = int.tryParse(a['deletedAt'] ?? '0') ?? 0;
      }
      
      if (b['itemType'] == 'totp') {
        dB = TotpStore.getDeletedAtMillis(b);
      } else {
        dB = int.tryParse(b['deletedAt'] ?? '0') ?? 0;
      }
      
      return dB.compareTo(dA);
    });

    if (!mounted) return;
    setState(() {
      recycleBinItems = combined;
      isLoading = false;
    });
  }

  int getDaysLeft(Map<String, String> item) {
    int deletedAt = 0;
    if (item['itemType'] == 'totp') {
      deletedAt = TotpStore.getDeletedAtMillis(item);
    } else {
      deletedAt = int.tryParse(item['deletedAt'] ?? '0') ?? 0;
    }
    
    if (deletedAt <= 0) return 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - deletedAt;
    final remaining = TotpStore.recycleBinRetentionMillis - elapsed;
    if (remaining <= 0) return 0;
    return (remaining / Duration.millisecondsPerDay).ceil();
  }

  Future<void> copyTotpOrPassword(Map<String, String> item) async {
    if (item['itemType'] == 'totp') {
      final secret = item['secretcode'] ?? '';
      if (secret.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret not available for this credential'), duration: Duration(seconds: 2)));
        return;
      }

      final code = Totp.generate( secret: secret, digits: 6, period: 30, time: DateTime.now().millisecondsSinceEpoch ~/1000);
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TOTP copied to clipboard'), duration: Duration(seconds: 2)));
    } else {
      final password = item['password'] ?? '';
      await Clipboard.setData(ClipboardData(text: password));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied to clipboard'), duration: Duration(seconds: 2)));
    }
  }

  Future<void> restoreCredential(Map<String, String> item) async {
    final id = item['id'] ?? '';
    if (id.isEmpty) return;

    bool restored = false;
    if (item['itemType'] == 'totp') {
      restored = await TotpStore.restoreFromRecycleBin(id);
    } else {
      restored = await PasswordStore.restoreFromRecycleBin(id);
    }

    if (!mounted) return;
    if (restored) {
      await loadRecycleBin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(item['itemType'] == 'totp' ? 'Authenticator restored' : 'Password restored'), duration: const Duration(seconds: 2)));
    }
  }

  Future<void> deletePermanently(Map<String, String> item) async {
    final id = item['id'] ?? '';
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog( 
        title: const Text('Delete permanently?'),
        content: const Text('This will remove the item from this device forever. It cannot be restored after this step.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete permanently', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    bool deleted = false;
    if (item['itemType'] == 'totp') {
      deleted = await TotpStore.deletePermanentlyFromRecycleBin(id);
    } else {
      deleted = await PasswordStore.deletePermanentlyFromRecycleBin(id);
    }

    if (!mounted) return;
    if (deleted) {
      await loadRecycleBin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Item permanently deleted from this device'), duration: Duration(seconds: 2)));
    }
  }

  Future<void> onItemAction(String value, Map<String, String> item) async {
    if (value == 'copy') {
      await copyTotpOrPassword(item);
      return;
    }
    if (value == 'restore') {
      await restoreCredential(item);
      return;
    }
    if (value == 'delete') {
      await deletePermanently(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = recycleBinItems.where((item) {
      if (filterType != 'all' && item['itemType'] != filterType) return false;
      
      final query = searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      
      final title = (item['itemType'] == 'totp' ? item['platform'] : item['name']) ?? '';
      final user = item['username'] ?? '';
      return title.toLowerCase().startsWith(query) || user.toLowerCase().startsWith(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recycle Bin'), scrolledUnderElevation: 0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search recycle bin',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric( horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.search, size: 20),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: filterType == 'all',
                        onSelected: (selected) {
                          if (selected) setState(() => filterType = 'all');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Authenticator'),
                        selected: filterType == 'totp',
                        onSelected: (selected) {
                          if (selected) setState(() => filterType = 'totp');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Passwords'),
                        selected: filterType == 'password',
                        onSelected: (selected) {
                          if (selected) setState(() => filterType = 'password');
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Latest deleted items appear at the top. Items are removed after 30 days.', style: Theme.of(context).textTheme.bodySmall),
                ),
                Expanded(
                  child: recycleBinItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 72, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 12),
                              Text('Empty recycle bin', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        )
                      : filteredItems.isEmpty
                      ? const Center(child: Text('No items match your search/filter'))
                      : ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isTotp = item['itemType'] == 'totp';
                            final titleText = isTotp ? (item['platform'] ?? '') : (item['name'] ?? '');
                            final username = item['username'] ?? '';
                            final daysLeft = getDaysLeft(item);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: Icon(isTotp ? Icons.security : Icons.password, color: Theme.of(context).colorScheme.primary),
                                title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text('Username: $username'),
                                    Text('Days Left: $daysLeft'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) => onItemAction(value, item),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'delete', child: Text('Delete permanently', style: TextStyle(color: Colors.red))),
                                    PopupMenuItem(value: 'copy', child: Text(isTotp ? 'Copy TOTP' : 'Copy Password')),
                                    const PopupMenuItem(value: 'restore', child: Text('Restore')),
                                  ],
                                  icon: const Icon(Icons.more_vert),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}