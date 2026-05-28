import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/crypto/password_store.dart';
import 'add_password_screen.dart';
import '../settingsScreen/settings_screen.dart';
import 'password_flip_card.dart';
import '../../widgets/app_snackbars.dart';

class PasswordManagerScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ValueNotifier<int> refreshNotifier;

  const PasswordManagerScreen({
    super.key,
    required this.onToggleTheme,
    required this.refreshNotifier,
  });

  @override
  State<PasswordManagerScreen> createState() => PasswordManagerScreenState();
}

class PasswordManagerScreenState extends State<PasswordManagerScreen> {
  List<Map<String, String>> passwords = [];
  String searchQuery = '';
  late FocusNode searchFocusNode = FocusNode();

  late final Map<String, FaIconData> platformIcons = {
    'airbnb': FontAwesomeIcons.airbnb,
    'amazon web services': FontAwesomeIcons.aws,
    'amazon pay': FontAwesomeIcons.amazonPay,
    'amazon': FontAwesomeIcons.amazon,
    'android': FontAwesomeIcons.android,
    'apple pay': FontAwesomeIcons.applePay,
    'apple': FontAwesomeIcons.apple,
    'arch linux': FontAwesomeIcons.archLinux,
    'aws': FontAwesomeIcons.aws,
    'bitbucket': FontAwesomeIcons.bitbucket,
    'brave': FontAwesomeIcons.brave,
    'chatgpt': FontAwesomeIcons.brave,
    'chrome': FontAwesomeIcons.chrome,
    'claude': FontAwesomeIcons.claude,
    'cloudflare': FontAwesomeIcons.cloudflare,
    'debian': FontAwesomeIcons.debian,
    'discord': FontAwesomeIcons.discord,
    'docker': FontAwesomeIcons.docker,
    'dropbox': FontAwesomeIcons.dropbox,
    'edge': FontAwesomeIcons.edge,
    'facebook': FontAwesomeIcons.facebook,
    'fedora': FontAwesomeIcons.fedora,
    'figma': FontAwesomeIcons.figma,
    'firefox': FontAwesomeIcons.firefox,
    'github': FontAwesomeIcons.github,
    'gitlab': FontAwesomeIcons.gitlab,
    'git': FontAwesomeIcons.git,
    'google': FontAwesomeIcons.google,
    'instagram': FontAwesomeIcons.instagram,
    'jenkins': FontAwesomeIcons.jenkins,
    'kaggle': FontAwesomeIcons.kaggle,
    'kubernetes': FontAwesomeIcons.kubernetes,
    'linkedin': FontAwesomeIcons.linkedin,
    'meta': FontAwesomeIcons.meta,
    'microsoft': FontAwesomeIcons.microsoft,
    'mozilla': FontAwesomeIcons.firefox,
    'netflix': FontAwesomeIcons.film,
    'orcid': FontAwesomeIcons.orcid,
    'openai': FontAwesomeIcons.openai,
    'opera': FontAwesomeIcons.opera,
    'patreon': FontAwesomeIcons.patreon,
    'pinterest': FontAwesomeIcons.pinterest,
    'reddit': FontAwesomeIcons.reddit,
    'salesforce': FontAwesomeIcons.salesforce,
    'safari': FontAwesomeIcons.safari,
    'signal': FontAwesomeIcons.signal,
    'snapchat': FontAwesomeIcons.snapchat,
    'spotify': FontAwesomeIcons.spotify,
    'steam': FontAwesomeIcons.steam,
    'skype': FontAwesomeIcons.skype,
    'telegram': FontAwesomeIcons.telegram,
    'twitch': FontAwesomeIcons.twitch,
    'twitter': FontAwesomeIcons.x,
    'whatsapp': FontAwesomeIcons.whatsapp,
    'windows': FontAwesomeIcons.windows,
    'x': FontAwesomeIcons.x,
    'youtube': FontAwesomeIcons.youtube,
    'zoom': FontAwesomeIcons.zoom,
  };

  FaIconData getPlatformIcon(String input) {
    final text = input.toLowerCase().trim();
    for (final key in platformIcons.keys) {
      if (text.startsWith(key)) {
        return platformIcons[key]!;
      }
    }
    return FontAwesomeIcons.globe;
  }

  @override
  void initState() {
    super.initState();
    load();
    widget.refreshNotifier.addListener(load);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(load);
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

    if (result is String) {
      widget.refreshNotifier.value++;
      if (!mounted) return;
      AppSnackBars.showCustomSnackBar(context: context, message: existingItem == null ? 'Password added successfully' : 'Password updated successfully', textColor: Colors.greenAccent.shade700);
    } else {
      widget.refreshNotifier.value++;
    }
  }

  String getGroupingLetter(String name) {
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
      return name.startsWith(query) || domain.startsWith(query);
    }).toList();

    final grouped = <String, List<Map<String, String>>>{};
    for (final item in filteredPasswords) {
      final name = item['name'] ?? '';
      final groupKey = getGroupingLetter(name);
      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Password Manager'), scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open Settings',
            onPressed: () async {
              searchFocusNode.unfocus();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(onToggleTheme: widget.onToggleTheme)),
              );
              widget.refreshNotifier.value++;
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => searchFocusNode.unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  focusNode: searchFocusNode,
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText:'Search from ${passwords.length} ${passwords.length == 1 ? 'password' : 'passwords'}',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            Expanded(
              child: passwords.isEmpty
                  ? const Center(child: Text('No passwords added')) : searchQuery.isNotEmpty && filteredPasswords.isEmpty
                  ? const Center(child: Text('No passwords match your search')) : ListView.builder(
                      itemCount: sortedKeys.length,
                      itemBuilder: (listContext, index) {
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
                              padding: const EdgeInsets.symmetric( horizontal: 20, vertical: 8),
                              child: Text(key,
                                style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            ...items.map((item) {
                              return Card(
                                margin: const EdgeInsets.symmetric( horizontal: 12, vertical: 4),
                                elevation: 1,
                                child: ListTile(
                                  leading: FaIcon(getPlatformIcon(item['name'] ?? ''), size: 24, color: Colors.orange),
                                  title: Text(
                                    item['name']?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(item['username']?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  onTap: () {
                                    final pass = item['password'] ?? '';
                                    Clipboard.setData(
                                      ClipboardData(text: pass),
                                    );
                                    HapticFeedback.lightImpact();
                                    AppSnackBars.showCustomSnackBar(context: context, message: 'Password copied to clipboard', textColor: Colors.blue);
                                  },
                                  onLongPress: () async {
                                    HapticFeedback.heavyImpact();
                                    final result = await showDialog(
                                      context: context,
                                      builder: (_) => PasswordFlipCard(passwordItem: item),
                                    );
                                    widget.refreshNotifier.value++;
                                    if (result is Map &&
                                        result['action'] == 'deleted') {
                                      final id = result['id'];

                                      if (!context.mounted) return;
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      messenger.hideCurrentSnackBar();
                                      var undoPressed = false;
                                      Timer? autoCloseTimer;

                                      final deleteSnackBarController = AppSnackBars.showCustomSnackBar(
                                        context: context,
                                        message: 'Password moved to recycle bin',
                                        textColor: Colors.blue,
                                        actionLabel: 'UNDO',
                                        onActionPressed: () async {
                                          undoPressed = true;
                                          autoCloseTimer?.cancel();
                                          
                                          final restored = await PasswordStore.restoreFromRecycleBin(id);
                                          if (!restored || !mounted) return;
                                          
                                          widget.refreshNotifier.value++;
                                          if (!mounted) return;
                                          
                                          AppSnackBars.showCustomSnackBar(context: this.context, message: 'Password restored', textColor: Colors.lightGreenAccent.shade700);
                                        },
                                      );
                                      autoCloseTimer = Timer(
                                        const Duration(seconds: 3),
                                        () {
                                          if (!mounted || undoPressed) return;
                                          deleteSnackBarController.close();
                                        },
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
        tooltip: 'Add New Password',
        onPressed: () => openAddOrEdit(),
        backgroundColor: Colors.orange.withValues(alpha: 0.5),
        child: const Icon(Icons.add),
      ),
    );
  }
}
