import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/crypto/password_store.dart';
import 'add_password_screen.dart';

class PasswordDetailsScreen extends StatefulWidget {
  final Map<String, String> passwordItem;

  const PasswordDetailsScreen({super.key, required this.passwordItem});

  @override
  State<PasswordDetailsScreen> createState() => _PasswordDetailsScreenState();
}

class _PasswordDetailsScreenState extends State<PasswordDetailsScreen> {
  late Map<String, String> item;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    item = widget.passwordItem;
  }

  Future<void> _editPassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPasswordScreen(existingPassword: item),
      ),
    );

    if (result == 'edited') {
      final list = await PasswordStore.load();
      final updatedItem = list.firstWhere(
        (e) => e['id'] == item['id'],
        orElse: () => item,
      );
      setState(() {
        item = updatedItem;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated successfully',
            style: TextStyle(color: Colors.green),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deletePassword() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Password?'),
        content: Text('Are you sure you want to delete ${item['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await PasswordStore.deleteById(item['id'] ?? '');
                if (!mounted) return;
                Navigator.pop(context); 
                Navigator.pop(context, 'deleted'); 
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to delete password',
                      style: TextStyle(color: Colors.red),
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDateString(String dateStr) {
    if (dateStr.length == 15 && dateStr.contains(' ')) {
      final parts = dateStr.split(' ');
      final date = parts[0];
      final time = parts[1];
      if (date.length == 8 && time.length == 6) {
        return '${date.substring(0, 2)}/${date.substring(2, 4)}/${date.substring(4, 8)} at ${time.substring(0, 2)}:${time.substring(2, 4)}';
      }
    }
    return dateStr;
  }

  Widget _buildDetailTile(String title, String value, {bool isPassword = false, bool isNotes = false}) {
    if (value.isEmpty && isNotes) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isNotes)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => _copyToClipboard(value, title),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: isNotes ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: isNotes
                      ? SizedBox(
                          height: 120,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black26
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          isPassword && obscurePassword ? '•' * value.length : value,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: isPassword ? 'monospace' : null,
                          ),
                        ),
                ),
                if (isPassword)
                  IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  ),
                if (!isNotes)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(value, title),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = item['updatedAt'] ?? '';
    final createdAt = item['createdAt'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Details'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPassword,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deletePassword,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailTile('Name', item['name'] ?? ''),
            _buildDetailTile('URL / Domain', item['domain'] ?? ''),
            _buildDetailTile('Username / Email', item['username'] ?? ''),
            _buildDetailTile('Password', item['password'] ?? '', isPassword: true),
            _buildDetailTile('Notes', item['notes'] ?? '', isNotes: true),
            const SizedBox(height: 24),
            if (createdAt.isNotEmpty)
              Center(
                child: Text(
                  'Created: ${_formatDateString(createdAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            if (updatedAt.isNotEmpty && updatedAt != createdAt)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Last Edited: ${_formatDateString(updatedAt)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}