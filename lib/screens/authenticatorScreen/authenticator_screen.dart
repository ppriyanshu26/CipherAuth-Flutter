import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../main.dart';
import '../../utils/crypto/totp_store.dart';
import '../../utils/crypto/totp.dart';
import 'add_account_screen.dart';
import '../settingsScreen/settings_screen.dart';
import 'package:flutter/services.dart';
import 'authenticator_card.dart';
import '../../widgets/app_snackbars.dart';

class AuthenticatorScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ValueNotifier<int> refreshNotifier;

  const AuthenticatorScreen({
    super.key, 
    required this.onToggleTheme, 
    required this.refreshNotifier,
  });

  @override
  State<AuthenticatorScreen> createState() => AuthenticatorScreenState();
}

class AuthenticatorScreenState extends State<AuthenticatorScreen> {
  List<Map<String, String>> totps = [];
  Set<int> selected = {};
  bool selectionMode = false;
  String searchQuery = '';
  late FocusNode searchFocusNode = FocusNode();
  Timer? timer;
  int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    load();
    widget.refreshNotifier.addListener(load);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForPendingDeepLink();
    });
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(load);
    timer?.cancel();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final list = await TotpStore.load();
    if (!mounted) return;
    setState(() => totps = list);
  }

  Future<void> addAccount() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (changed == true) {
      widget.refreshNotifier.value++;
    }
  }

  void checkForPendingDeepLink() {
    try {
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final rootContext = rootNavigator.context;
      final myAppState = rootContext.findAncestorStateOfType<MyAppState>();
      if (myAppState == null) return;

      final pendingUrl = myAppState.takePendingDeepLink();
      if (pendingUrl == null || pendingUrl.isEmpty) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddAccountScreen(initialUrl: pendingUrl)),
      ).then((result) {
        if (result == true) {
          widget.refreshNotifier.value++;
        }
      });
    } catch (_) {}
  }

  Future<void> deleteSelected() async {
    if (selected.isEmpty) return;
    final ids = <String>[];
    for (final index in selected) {
      if (index >= 0 && index < totps.length) {
        final id = totps[index]['id'] ?? '';
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }
    }
    await TotpStore.moveToRecycleBinAndDeleteByIds(ids);

    setState(() {
      selected.clear();
      selectionMode = false;
    });
    widget.refreshNotifier.value++;
  }

  Color changeColor(int remaining, int period) {
    final percentage = (remaining/period)*100;
    if (percentage > 67) {
      return Colors.green;
    } else if (percentage > 34) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

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

  Widget tile(int index, Map<String, String> item) {
    final user = item['username'] ?? '';
    final secret = item['secretcode']!;
    final digits = 6;
    final period = 30;
    final code = Totp.generate(secret: secret, digits: digits, period: period, time: now);
    final remaining = period - (now % period);
    final color = changeColor(remaining, period);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: code));
          HapticFeedback.lightImpact();
          AppSnackBars.showCustomSnackBar(context: context, message: 'Code copied to clipboard', textColor: Colors.blue);
        },
        onLongPress: () async {
          HapticFeedback.heavyImpact();
          final result = await showDialog(
            context: context,
            builder: (_) => AuthenticatorCard(totpItem: item),
          );
          if (result is Map && result['action'] == 'deleted') {
            final id = result['id'];
            widget.refreshNotifier.value++;

            if (!mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            
            var undoPressed = false;
            Timer? autoCloseTimer;
            final deleteSnackBarController = AppSnackBars.showCustomSnackBar(
              context: context,
              message: 'Credential moved to recycle bin',
              textColor: Colors.blue,
              actionLabel: 'UNDO',
              onActionPressed: () async {
                undoPressed = true;
                autoCloseTimer?.cancel();
                
                final restored = await TotpStore.restoreFromRecycleBin(id);
                if (!restored || !mounted) return;
                
                widget.refreshNotifier.value++;
                if (!mounted) return;
                
                AppSnackBars.showCustomSnackBar(context: context, message: 'Credential restored', textColor: Colors.blue);
              },
            );
            
            autoCloseTimer = Timer(const Duration(seconds: 3), () {
              if (!mounted || undoPressed) return;
              deleteSnackBarController.close();
            });
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minLeadingWidth: 0,
          leading: selectionMode
              ? Checkbox(
                  value: selected.contains(index),
                  onChanged: (_) {
                    setState(() {
                      selected.contains(index) ? selected.remove(index) : selected.add(index);
                    });
                  },
                )
              : FaIcon(getPlatformIcon(item['platform']!), size: 24, color: Colors.orange),
          title: Text(item['platform']!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(user,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: selectionMode
              ? null
              : SizedBox(
                  width: 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(code,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: color),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 0),
                      Text('$remaining s',
                        style: TextStyle( fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
          onTap: selectionMode
              ? () {
                  setState(() {
                    selected.contains(index) ? selected.remove(index) : selected.add(index);
                  });
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTotps = totps.where((item) {
      final platform = item['platform']?.toLowerCase() ?? '';
      return platform.startsWith(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Authenticator"), scrolledUnderElevation: 0,
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
        onTap: () {
          searchFocusNode.unfocus();
        },
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
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText:'Search from ${totps.length} ${totps.length == 1 ? 'account' : 'accounts'}',
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
              child: totps.isEmpty
                  ? const Center(child: Text('No accounts added'))
                  : searchQuery.isNotEmpty && filteredTotps.isEmpty
                  ? const Center(child: Text('No platforms match your search'))
                  : ListView.builder(
                      itemCount: filteredTotps.length,
                      itemBuilder: (_, i) => tile(
                        totps.indexOf(filteredTotps[i]),
                        filteredTotps[i],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: addAccount,
        tooltip: 'Add New Account',
        backgroundColor: Colors.orange.withValues(alpha: 0.5),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: selectionMode
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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