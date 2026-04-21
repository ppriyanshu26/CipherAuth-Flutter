import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/totp.dart';
import '../utils/totp_store.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => RecycleBinScreenState();
}

class RecycleBinScreenState extends State<RecycleBinScreen> {
  List<Map<String, String>> recycleBinItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecycleBin();
  }

  Future<void> loadRecycleBin() async {
    final items = await TotpStore.getRecycleBin(purgeExpired: true);
    if (!mounted) return;
    setState(() {
      recycleBinItems = items;
      isLoading = false;
    });
  }

  int getDaysLeft(Map<String, String> item) {
    final deletedAt = TotpStore.getDeletedAtMillis(item);
    if (deletedAt <= 0) return 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - deletedAt;
    final remaining = TotpStore.recycleBinRetentionMillis - elapsed;
    if (remaining <= 0) return 0;
    return (remaining / Duration.millisecondsPerDay).ceil();
  }

  Future<void> copyTotp(Map<String, String> item) async {
    final secret = item['secretcode'] ?? '';
    if (secret.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Secret not available for this credential'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final code = Totp.generate(
        secret: secret,
        digits: 6,
        period: 30,
        time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TOTP copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate TOTP'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> restoreCredential(Map<String, String> item) async {
    final id = item['id'] ?? '';
    if (id.isEmpty) return;

    final restored = await TotpStore.restoreFromRecycleBin(id);
    if (!mounted) return;
    if (restored) {
      await loadRecycleBin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credential restored'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> deletePermanently(Map<String, String> item) async {
    final id = item['id'] ?? '';
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await TotpStore.deletePermanentlyFromRecycleBin(id);
    if (!mounted) return;
    if (deleted) {
      await loadRecycleBin();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credential deleted permanently'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> onItemAction(String value, Map<String, String> item) async {
    if (value == 'copy') {
      await copyTotp(item);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        scrolledUnderElevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recycleBinItems.isEmpty
          ? const Center(child: Text('Recycle bin is empty'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Latest deleted credentials appear at the top. Items are removed after 30 days.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: recycleBinItems.length,
                    itemBuilder: (context, index) {
                      final item = recycleBinItems[index];
                      final platform = item['platform'] ?? '';
                      final username = item['username'] ?? '';
                      final daysLeft = getDaysLeft(item);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            platform.isEmpty ? 'Unknown Platform' : platform,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                'Username: ${username.isEmpty ? '-' : username}',
                              ),
                              Text('Days Left: $daysLeft'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => onItemAction(value, item),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete permanently'),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: Text('Copy TOTP'),
                              ),
                              PopupMenuItem(
                                value: 'restore',
                                child: Text('Restore'),
                              ),
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
