import 'package:flutter/material.dart';
import '../../utils/crypto/password_store.dart';
import '../../widgets/passphrase_generator_dialog.dart';

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
    final parts = text.split(RegExp(r'[,\n\s]+')).where((p) => p.trim().isNotEmpty).toList();
    if (parts.length > 1) {
      setState(() => isDomainValid = false);
      return;
    }
    bool allValid = true;
    for (var p in parts) {
      final pt = p.trim();
      if (pt.isEmpty) continue;
      final urlRegex = RegExp(r'^(?:https?://)?(?:www\.)?(?:localhost|(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|(?:(?!www\.)[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})(?::\d+)?(?:\/[^\s]*)?$', caseSensitive: false);
      if (!urlRegex.hasMatch(pt)) {
        allValid = false;
        break;
      }
    }
    setState(() => isDomainValid = allValid && parts.isNotEmpty);
  }

  String? getDomainErrorText() {
    final text = domainCtrl.text.trim();
    if (text.isEmpty) return null;
    final parts = text.split(RegExp(r'[,\n\s]+')).where((p) => p.trim().isNotEmpty).toList();
    if (parts.length > 1) {
      return 'Only one domain is allowed';
    }
    return 'Contains invalid domain format';
  }

  String normalizeDomainInput(String input) {
    final parts = input.trim().split(RegExp(r'[,\n\s]+'));
    final normalized = <String>[];

    for (final part in parts) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value);
      normalized.add(hasScheme ? value : 'https://$value');
    }
    return normalized.join(', ');
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

  String extractBaseDomain(String url) {
    try {
      String strUrl = url.trim().toLowerCase();
      if (!strUrl.startsWith('http://') && !strUrl.startsWith('https://')) {
        strUrl = 'https://$strUrl';
      }
      final uri = Uri.parse(strUrl);
      String host = uri.host;
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      final parts = host.split('.');
      if (parts.length > 2) {
        if (['co', 'com', 'net', 'org', 'ac']
          .contains(parts[parts.length - 2])) {
          return parts.sublist(parts.length - 3).join('.');
        }
        return parts.sublist(parts.length - 2).join('.');
      }
      return host;
    } catch (_) {
      return url;
    }
  }

  Future<void> savePassword() async {
    setState(() => error = null);
    final title = normalizeTitle(nameCtrl.text);
    final normalizedDomain = normalizeDomainInput(domainCtrl.text).toLowerCase();

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
      setState(() => error = getDomainErrorText() ?? 'Please enter valid a URL');
      return;
    }

    try {
      final inputUsername = usernameCtrl.text.trim().toLowerCase();
      final inputDomains = domainCtrl.text
          .split(RegExp(r'[,\n\s]+'))
          .where((e) => e.trim().isNotEmpty)
          .map(extractBaseDomain)
          .toSet();

      final allPasswords = await PasswordStore.load();
      for (var pwd in allPasswords) {
        if (isEditing && pwd['id'] == widget.existingPassword?['id']) continue;

        final pwdUsername = (pwd['username'] ?? '').toLowerCase();
        if (pwdUsername != inputUsername) continue;

        final pwdDomains = (pwd['domain'] ?? '')
            .split(RegExp(r'[,\n\s]+'))
            .where((e) => e.trim().isNotEmpty)
            .map(extractBaseDomain)
            .toSet();

        if (pwdDomains.intersection(inputDomains).isNotEmpty) {
          setState(() => error = 'Account with same username already exists');
          return;
        }
      }

      final binPasswords = await PasswordStore.getRecycleBin(
        purgeExpired: true,
      );
      for (var pwd in binPasswords) {
        final pwdUsername = (pwd['username'] ?? '').toLowerCase();
        if (pwdUsername != inputUsername) continue;

        final pwdDomains = (pwd['domain'] ?? '')
            .split(RegExp(r'[,\n\s]+'))
            .where((e) => e.trim().isNotEmpty)
            .map(extractBaseDomain)
            .toSet();

        if (pwdDomains.intersection(inputDomains).isNotEmpty) {
          setState(() => error = 'Account with same username presists bin');
          return;
        }
      }

      if (isEditing) {
        final newId = await PasswordStore.update(
          widget.existingPassword!['id']!,
          title,
          normalizedDomain,
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
          normalizedDomain,
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
      appBar: AppBar(title: Text(isEditing ? 'Edit Password' : 'Add Password'), scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: 'Passphrase Generator',
            onPressed: () {
              FocusScope.of(context).unfocus();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const PassphraseGeneratorDialog();
                },
              );
            },
          ),
        ],
      ),
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
                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                  tooltip: obscurePassword ? 'Show Password' : 'Hide Password',
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: domainCtrl,
              decoration: InputDecoration(labelText: 'Site URL', border: const OutlineInputBorder(),
                errorText: domainCtrl.text.isNotEmpty && !isDomainValid ? getDomainErrorText() : null,
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