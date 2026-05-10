import 'package:flutter/material.dart';
import '../../utils/crypto/password_store.dart';

class AddPasswordScreen extends StatefulWidget {
  final Map<String, String>? existingPassword;

  const AddPasswordScreen({super.key, this.existingPassword});

  @override
  State<AddPasswordScreen> createState() => AddPasswordScreenState();
}

class AddPasswordScreenState extends State<AddPasswordScreen> {
  final nameCtrl = TextEditingController();
  final domainCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  
  bool obscurePassword = true;
  String? error;
  bool _isDomainValid = false;
  
  bool get isEditing => widget.existingPassword != null;

  @override
  void initState() {
    super.initState();
    domainCtrl.addListener(_validateDomain);
    
    if (isEditing) {
      nameCtrl.text = widget.existingPassword!['name'] ?? '';
      domainCtrl.text = widget.existingPassword!['domain'] ?? '';
      usernameCtrl.text = widget.existingPassword!['username'] ?? '';
      passwordCtrl.text = widget.existingPassword!['password'] ?? '';
      notesCtrl.text = widget.existingPassword!['notes'] ?? '';
      _validateDomain();
    }
  }

  void _validateDomain() {
    final text = domainCtrl.text.trim();
    final RegExp urlRegExp = RegExp(r'^(https?:\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(:\d+)?(\/.*)?$');
    setState(() {
      _isDomainValid = text.isNotEmpty && urlRegExp.hasMatch(text);
      if (error != null && _isDomainValid) {
        error = null;
      }
    });
  }

  Future<void> savePassword() async {
    final name = nameCtrl.text.trim();
    final domain = domainCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text.trim();
    final notes = notesCtrl.text.trim();

    if (name.isEmpty || domain.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => error = 'Name, URL, Username, and Password are required');
      return;
    }

    if (!_isDomainValid) {
      setState(() => error = 'Please enter a valid URL or Domain (e.g., example.com)');
      return;
    }

    try {
      if (isEditing) {
        await PasswordStore.update(
          widget.existingPassword!['id']!,
          name,
          domain,
          username,
          password,
          notes,
        );
      } else {
        await PasswordStore.add(name, domain, username, password, notes);
      }

      if (!mounted) return;
      Navigator.pop(context, isEditing ? 'edited' : 'added');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to save password',
            style: TextStyle(color: Colors.red),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
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

  @override
  void dispose() {
    nameCtrl.dispose();
    domainCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = widget.existingPassword?['updatedAt'] ?? '';
    final createdAt = widget.existingPassword?['createdAt'] ?? '';
    
    String displayDate = '';
    if (isEditing) {
      if (updatedAt.isNotEmpty) {
        displayDate = 'Last edited at: ${_formatDateString(updatedAt)}';
      } else if (createdAt.isNotEmpty) {
        displayDate = 'Created at: ${_formatDateString(createdAt)}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Password' : 'Add Password'),
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name (e.g., Google Account)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: domainCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'URL (e.g., https://google.com)',
                border: const OutlineInputBorder(),
                suffixIcon: domainCtrl.text.isNotEmpty
                    ? Icon(
                        _isDomainValid ? Icons.check_circle : Icons.error,
                        color: _isDomainValid ? Colors.green : Colors.red,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username / Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: TextField(
                controller: notesCtrl,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: savePassword,
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ),
            if (displayDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    displayDate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}