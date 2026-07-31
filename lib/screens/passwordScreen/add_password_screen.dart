import 'package:flutter/material.dart';
import '../../utils/crypto/password_store.dart';
import '../../utils/crypto/totp_store.dart';
import '../../widgets/passphrase_generator_dialog.dart';

class AddPasswordScreen extends StatefulWidget {
  final Map<String, String>? existingPassword;
  final String? initialUrl;
  const AddPasswordScreen({super.key, this.existingPassword, this.initialUrl});

  static String formatPrefillUrl(String input) {
    var clean = input.trim();
    if (clean.isEmpty) return '';

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    if (clean.contains('.') && !clean.contains('/')) {
      final parts = clean.split('.');
      if (parts.length >= 2) {
        final tlds = {'com', 'org', 'net', 'gov', 'edu', 'io', 'co', 'in', 'app'};
        
        String mainName = '';
        String ext = 'com';
        
        if (tlds.contains(parts[0].toLowerCase())) {
          ext = parts[0];
          if (parts.length > 1) {
            mainName = parts[1];
          }
        } else if (tlds.contains(parts.last.toLowerCase())) {
          ext = parts.last;
          if (parts.length > 1) {
            mainName = parts[parts.length - 2];
          }
        } else {
          final ignored = {'android', 'app', 'client', 'mobile', 'play'};
          final candidateParts = parts.where((p) => !ignored.contains(p.toLowerCase())).toList();
          if (candidateParts.isNotEmpty) {
            mainName = candidateParts.last;
          } else {
            mainName = parts[0];
          }
        }
        
        if (mainName.isNotEmpty) {
          return 'https://$mainName.$ext';
        }
      }
    }

    if (clean.contains('.') && !clean.contains(':') && !clean.contains('/')) {
      return 'https://$clean';
    }

    return clean;
  }

  static String guessTitleFromUrl(String url) {
    var clean = url.trim().toLowerCase();
    if (clean.contains('://')) {
      clean = clean.substring(clean.indexOf('://') + 3);
    }
    if (clean.startsWith('www.')) {
      clean = clean.substring(4);
    }
    final parts = clean.split('/');
    final host = parts[0].split(':')[0];
    final hostParts = host.split('.');
    if (hostParts.length >= 2) {
      final tlds = {'com', 'org', 'net', 'gov', 'edu', 'io', 'co', 'in', 'app', 'uk', 'us', 'ca'};
      if (hostParts.length >= 3 && tlds.contains(hostParts[hostParts.length - 2])) {
        final candidate = hostParts[hostParts.length - 3];
        if (candidate.isNotEmpty) {
          return candidate[0].toUpperCase() + candidate.substring(1);
        }
      }
      final candidate = hostParts[0];
      if (candidate.isNotEmpty) {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
    return '';
  }

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
  List<Map<String, String>> authenticators = [];
  String? selectedTotpId;

  @override
  void initState() {
    super.initState();
    domainCtrl.addListener(validateDomain);
    loadAuthenticators();
    if (isEditing) {
      nameCtrl.text = widget.existingPassword!['name'] ?? '';
      domainCtrl.text = widget.existingPassword!['domain'] ?? '';
      usernameCtrl.text = widget.existingPassword!['username'] ?? '';
      passwordCtrl.text = widget.existingPassword!['password'] ?? '';
      notesCtrl.text = widget.existingPassword!['notes'] ?? '';
      selectedTotpId = widget.existingPassword!['linkedTotpId'] ?? '';
      if (selectedTotpId == '') {
        selectedTotpId = null;
      }
      validateDomain();
    } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      domainCtrl.text = widget.initialUrl!;
      final guessedTitle = AddPasswordScreen.guessTitleFromUrl(widget.initialUrl!);
      if (guessedTitle.isNotEmpty) {
        nameCtrl.text = guessedTitle;
      }
      validateDomain();
    }
  }

  Future<void> loadAuthenticators() async {
    final list = await TotpStore.load();
    setState(() {
      authenticators = list;
      if (selectedTotpId != null && !list.any((t) => t['id'] == selectedTotpId)) {
        selectedTotpId = null;
      }
    });
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


  Future<void> savePassword() async {
    setState(() => error = null);
    final title = nameCtrl.text.trim();
    final domain = domainCtrl.text.trim();
    final username = usernameCtrl.text.trim();

    if (title.isEmpty) {
      setState(() => error = 'Title is required');
      return;
    }
    if (username.isEmpty) {
      setState(() => error = 'Username/Email is required');
      return;
    }
    if (passwordCtrl.text.isEmpty) {
      setState(() => error = 'Password is required');
      return;
    }
    if (domain.isEmpty) {
      setState(() => error = 'A URL is required');
      return;
    }
    if (!isDomainValid) {
      setState(() => error = getDomainErrorText() ?? 'Please enter valid a URL');
      return;
    }

    try {

      if (isEditing) {
        final newId = await PasswordStore.update(
          widget.existingPassword!['id']!,
          title,
          domain,
          username,
          passwordCtrl.text,
          notesCtrl.text.trim(),
          linkedTotpId: selectedTotpId ?? '',
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
          domain,
          username,
          passwordCtrl.text,
          notesCtrl.text.trim(),
          linkedTotpId: selectedTotpId ?? '',
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
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
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
              decoration: InputDecoration(labelText: 'URL', border: const OutlineInputBorder(),
                errorText: domainCtrl.text.isNotEmpty && !isDomainValid ? getDomainErrorText() : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: selectedTotpId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Linked Authenticator (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                ...authenticators.map((auth) {
                  final platform = auth['platform'] ?? 'Unknown';
                  final username = auth['username'] ?? '';
                  final displayName = username.isNotEmpty ? '$platform ($username)' : platform;
                  return DropdownMenuItem<String?>(
                    value: auth['id'],
                    child: Text(displayName, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  selectedTotpId = val;
                });
              },
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