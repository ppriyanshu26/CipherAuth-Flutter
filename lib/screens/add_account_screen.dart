import 'package:flutter/material.dart';
import '../utils/totp_store.dart';
import 'qr_scan_screen.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => AddAccountScreenState();
}

class AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final platformCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final secretCtrl = TextEditingController();

  bool fromQr = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  String buildTotpUrl({
    required String platform,
    required String username,
    required String secret,
  }) {
    return Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '$platform:$username',
      queryParameters: {
        'secret': secret,
        'issuer': platform,
        'digits': '6',
        'period': '30',
      },
    ).toString();
  }

  bool isValidBase32(String input) {
    final cleaned =
    input.replaceAll(' ', '').replaceAll('=', '').toUpperCase();
    return cleaned.isNotEmpty &&
        RegExp(r'^[A-Z2-7]+$').hasMatch(cleaned);
  }

  void populateFromOtpAuth(String url) {
    final uri = Uri.parse(url);
    final label = uri.pathSegments.last;

    String platform = '';
    String username = '';

    if (label.contains(':')) {
      final parts = label.split(':');
      platform = parts[0];
      username = parts.sublist(1).join(':');
    } else {
      platform = label;
    }

    final issuer = uri.queryParameters['issuer'];
    if (issuer != null && issuer.isNotEmpty) {
      platform = issuer;
    }

    final secret = uri.queryParameters['secret'] ?? '';

    platformCtrl.text = platform;
    usernameCtrl.text = username;
    secretCtrl.text = secret.toUpperCase();

    fromQr = true;
    tabController.animateTo(1);
    setState(() {});
  }

  Future<void> scanQr() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );

    if (result != null &&
        result is String &&
        result.startsWith('otpauth://')) {
      populateFromOtpAuth(result);
    }
  }

  Future<void> saveManual() async {
    final platform = platformCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final secret = secretCtrl.text.replaceAll(' ', '').toUpperCase();

    if (platform.isEmpty || username.isEmpty || secret.isEmpty) return;
    if (!isValidBase32(secret)) return;

    final url = buildTotpUrl(
      platform: platform,
      username: username,
      secret: secret,
    );

    final added = await TotpStore.add(platform, url);

    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account already exists')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR'),
              onPressed: scanQr,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: platformCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  readOnly: fromQr,
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretCtrl,
                  readOnly: fromQr,
                  decoration: const InputDecoration(
                    labelText: 'Secret key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: saveManual,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
