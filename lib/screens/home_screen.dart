import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/totp_store.dart';
import '../utils/totp.dart';
import 'add_account_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<String> totps = [];
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
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final list = await TotpStore.load();
    setState(() {
      totps = list;
    });
  }

  Future<void> addAccount() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAccountScreen()),
    );
    if (changed == true) load();
  }

  Widget tile(String url) {
    final uri = Uri.parse(url);

    final label = uri.pathSegments.last;
    String platform = label;
    String user = '';

    if (label.contains(':')) {
      final parts = label.split(':');
      platform = parts[0];
      user = parts.sublist(1).join(':');
    }

    final issuer = uri.queryParameters['issuer'];
    if (issuer != null && issuer.isNotEmpty) {
      platform = issuer;
    }

    final secret = uri.queryParameters['secret']!;
    final digits = int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6;
    final period = int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30;

    final code = Totp.generate(
      secret: secret,
      digits: digits,
      period: period,
      time: now,
    );

    final remaining = period - (now % period);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(platform, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(user),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$remaining s',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: widget.onToggleTheme,
          ),
          PopupMenuButton(
            itemBuilder: (_) => const [
              PopupMenuItem(child: Text('Reset password')),
              PopupMenuItem(child: Text('Sync')),
              PopupMenuItem(child: Text('Download')),
            ],
          ),
        ],
      ),
      body: totps.isEmpty
          ? const Center(child: Text('No accounts added'))
          : ListView.builder(
        itemCount: totps.length,
        itemBuilder: (_, i) => tile(totps[i]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}
