import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';
import '../utils/totp_store.dart';
import '../utils/totp.dart';
import 'add_account_screen.dart';
import 'settings_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });
    });

    // Check for pending deep link after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPendingDeepLink();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final list = await TotpStore.load();
    setState(() => totps = list);
  }

  Future<void> addAccount() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (changed == true) load();
  }

  void _checkForPendingDeepLink() {
    try {
      // Get the root navigator state to find MyAppState
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final rootContext = rootNavigator.context;

      // Try to find MyAppState in the widget tree
      final myAppState = rootContext.findAncestorStateOfType<MyAppState>();
      if (myAppState == null) return;

      // Get pending deep link
      final pendingUrl = myAppState.takePendingDeepLink();
      if (pendingUrl == null || pendingUrl.isEmpty) return;

      // Open AddAccountScreen with the pending deep link
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddAccountScreen(initialUrl: pendingUrl),
        ),
      ).then((result) {
        if (result == true) {
          load();
        }
      });
    } catch (e) {
      debugPrint('Error checking pending deep link: $e');
    }
  }

  Future<void> deleteSelected() async {
    if (selected.isEmpty) return;

    final remaining = <Map<String, String>>[];
    for (int i = 0; i < totps.length; i++) {
      if (!selected.contains(i)) remaining.add(totps[i]);
    }

    await TotpStore.saveAll(remaining);

    setState(() {
      totps = remaining;
      selected.clear();
      selectionMode = false;
    });
  }

  Color changeColor(int remaining, int period) {
    final percentage = (remaining / period) * 100;
    if (percentage > 66) {
      return Colors.green;
    } else if (percentage > 33) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  late final Map<String, IconData> platformIcons = {
    'apple': FontAwesomeIcons.apple,
    'amazon web services': FontAwesomeIcons.aws,
    'amazon': FontAwesomeIcons.amazon,
    'aws': FontAwesomeIcons.aws,
    'bitbucket': FontAwesomeIcons.bitbucket,
    'brave': FontAwesomeIcons.brave,
    'chatgpt': FontAwesomeIcons.openai,
    'cloudflare': FontAwesomeIcons.cloudflare,
    'discord': FontAwesomeIcons.discord,
    'dropbox': FontAwesomeIcons.dropbox,
    'edge': FontAwesomeIcons.edge,
    'facebook': FontAwesomeIcons.facebook,
    'firefox': FontAwesomeIcons.firefox,
    'github': FontAwesomeIcons.github,
    'gitlab': FontAwesomeIcons.gitlab,
    'google': FontAwesomeIcons.google,
    'instagram': FontAwesomeIcons.instagram,
    'linkedin': FontAwesomeIcons.linkedin,
    'meta': FontAwesomeIcons.meta,
    'microsoft': FontAwesomeIcons.microsoft,
    'mozilla': FontAwesomeIcons.firefox,
    'netflix': FontAwesomeIcons.film,
    'openai': FontAwesomeIcons.openai,
    'opera': FontAwesomeIcons.opera,
    'pinterest': FontAwesomeIcons.pinterest,
    'reddit': FontAwesomeIcons.reddit,
    'safari': FontAwesomeIcons.safari,
    'signal': FontAwesomeIcons.signal,
    'snapchat': FontAwesomeIcons.snapchat,
    'spotify': FontAwesomeIcons.spotify,
    'steam': FontAwesomeIcons.steam,
    'telegram': FontAwesomeIcons.telegram,
    'twitch': FontAwesomeIcons.twitch,
    'twitter': FontAwesomeIcons.x,
    'whatsapp': FontAwesomeIcons.whatsapp,
    'x': FontAwesomeIcons.x,
    'youtube': FontAwesomeIcons.youtube,
  };

  IconData getPlatformIcon(String input) {
    final text = input.toLowerCase().trim();
    for (final key in platformIcons.keys) {
      if (text.contains(key)) {
        return platformIcons[key]!;
      }
    }
    return FontAwesomeIcons.globe;
  }

  String truncate(String text, {int maxLength = 27}) {
    if ((Platform.isAndroid || Platform.isIOS) && text.length > maxLength) {
      return '${text.substring(0, maxLength - 2)}...';
    }
    return text;
  }

  Widget tile(int index, Map<String, String> item) {
    final user = item['username'] ?? '';
    final secret = item['secretcode']!;
    final digits = 6;
    final period = 30;

    try {
      final code = Totp.generate(
        secret: secret,
        digits: digits,
        period: period,
        time: now,
      );

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('TOTP copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete credential?'),
                content: Text('Delete ${item['platform']} - $user?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final remaining = <Map<String, String>>[];
                      for (int i = 0; i < totps.length; i++) {
                        if (i != index) remaining.add(totps[i]);
                      }

                      await TotpStore.saveAll(remaining);

                      setState(() {
                        totps = remaining;
                      });

                      if (!mounted) return;
                      Navigator.pop(context);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Credential deleted'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            minLeadingWidth: 0,
            leading: selectionMode
                ? Checkbox(
                    value: selected.contains(index),
                    onChanged: (_) {
                      setState(() {
                        selected.contains(index)
                            ? selected.remove(index)
                            : selected.add(index);
                      });
                    },
                  )
                : Icon(
                    getPlatformIcon(item['platform']!),
                    size: 24,
                    color: Colors.orange,
                  ),
            title: Text(
              truncate(item['platform']!, maxLength: 18),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              truncate(user),
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
                        Text(
                          code,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 0),
                        Text(
                          '$remaining s',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
            onTap: selectionMode
                ? () {
                    setState(() {
                      selected.contains(index)
                          ? selected.remove(index)
                          : selected.add(index);
                    });
                  }
                : null,
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
        child: ListTile(
          leading: selectionMode
              ? Checkbox(
                  value: selected.contains(index),
                  onChanged: (_) {
                    setState(() {
                      selected.contains(index)
                          ? selected.remove(index)
                          : selected.add(index);
                    });
                  },
                )
              : Icon(
                  getPlatformIcon(item['platform']!),
                  size: 24,
                  color: Colors.orange,
                ),
          title: Text(
            item['platform']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Error generating TOTP - try resetting password',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          trailing: selectionMode
              ? null
              : const Icon(Icons.error_outline, color: Colors.red),
          onTap: selectionMode
              ? () {
                  setState(() {
                    selected.contains(index)
                        ? selected.remove(index)
                        : selected.add(index);
                  });
                }
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTotps = totps.where((item) {
      final platform = item['platform']?.toLowerCase() ?? '';
      return platform.startsWith(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CipherAuth'),
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
                    hintText: 'Search from ${totps.length} ${totps.length == 1 ? 'account' : 'accounts'}',
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
        onPressed: addAccount,
        backgroundColor: Colors.orange.withValues(alpha: 0.5),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: selectionMode
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
