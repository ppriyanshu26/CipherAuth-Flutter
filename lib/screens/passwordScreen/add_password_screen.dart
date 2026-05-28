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
  bool isDomainValid = false;
  bool get isEditing => widget.existingPassword != null;

  @override
  void initState() {
    super.initState();
    domainCtrl.addListener(validateDomain);
    if (isEditing) {
      nameCtrl.text = widget.existingPassword!['name'] ?? '';
      domainCtrl.text = widget.existingPassword!['domain'] ?? '';
      usernameCtrl.text = widget.existingPassword!['username'] ?? '';
      passwordCtrl.text = widget.existingPassword!['password'] ?? '';
      notesCtrl.text = widget.existingPassword!['notes'] ?? '';
      validateDomain();
    }
  }

  void validateDomain() {
    final text = domainCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => isDomainValid = false);
      return;
    }
    final parts = text.split(RegExp(r'[,\n\s]+'));
    bool allValid = true;
    for (var p in parts) {
      final pt = p.trim();
      if (pt.isEmpty) continue;
      final urlRegex = RegExp(r'^(https?:\/\/)?([\w\-]+(\.[\w\-]+)+)([\w\-\.,@?^=%&:/~\+#]*[\w\-\@?^=%&/~\+#])?$');
      if (!urlRegex.hasMatch(pt)) {
        allValid = false;
        break;
      }
    }
    setState(() => isDomainValid = allValid && parts.isNotEmpty);
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

  String normalizeTitle(String input) {
    final words = input.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.map((word) {
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  Future<void> savePassword() async {
    setState(() => error = null);
    final title = normalizeTitle(nameCtrl.text);

    if (title.isEmpty) {
      setState(() => error = 'Title is required');
      return;
    }
    if (usernameCtrl.text.trim().isEmpty) {
      setState(() => error = 'Username/Email is required');
      return;
    }
    if (passwordCtrl.text.isEmpty) {
      setState(() => error = 'Password is required');
      return;
    }
    if (domainCtrl.text.trim().isEmpty) {
      setState(() => error = 'A URL is required');
      return;
    }
    if (!isDomainValid) {
      setState(() => error = 'Please enter valid a URL');
      return;
    }

    try {
      if (isEditing) {
        final newId = await PasswordStore.update(
          widget.existingPassword!['id']!,
          title,
          domainCtrl.text.trim().toLowerCase(),
          usernameCtrl.text.trim().toLowerCase(),
          passwordCtrl.text,
          notesCtrl.text.trim(),
        );
        if (newId != null) {
          if (!mounted) return;
          Navigator.pop(context, newId);
        } else {
          setState(() => error = 'Failed to update password');
        }
      } else {
        final newId = await PasswordStore.add(
          title,
          domainCtrl.text.trim().toLowerCase(),
          usernameCtrl.text.trim().toLowerCase(),
          passwordCtrl.text,
          notesCtrl.text.trim(),
        );
        if (newId != null) {
          if (!mounted) return;
          Navigator.pop(context, newId);
        } else {
          setState(() => error = 'Failed to add password');
        }
      }
    } catch (e) {
      setState(() => error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  String formatDateString(String dateStr) {
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
  Widget build(BuildContext context) {
    String displayDate = '';
    if (isEditing) {
      final createdAt = widget.existingPassword!['createdAt'] ?? '';
      final updatedAt = widget.existingPassword!['updatedAt'] ?? '';
      if (updatedAt.isNotEmpty && updatedAt != createdAt) {
        displayDate = 'Last edited: ${formatDateString(updatedAt)}';
      } else if (createdAt.isNotEmpty) {
        displayDate = 'Created at: ${formatDateString(createdAt)}';
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Password' : 'Add Password'), scrolledUnderElevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Title (e.g. Google, GitHub)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username/Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              decoration: InputDecoration(labelText: 'Password', border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                  tooltip: obscurePassword ? 'Show Password' : 'Hide Password',
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: domainCtrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(labelText: 'Site URL(s)', border: const OutlineInputBorder(),
                errorText: domainCtrl.text.isNotEmpty && !isDomainValid ? 'Contains invalid domain format' : null,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: TextField(
                controller: notesCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder(), alignLabelWithHint: true),
              ),
            ),
            const SizedBox(height: 16),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: savePassword, child: Text(isEditing ? 'Update' : 'Save')),
            ),
            if (displayDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(displayDate,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}