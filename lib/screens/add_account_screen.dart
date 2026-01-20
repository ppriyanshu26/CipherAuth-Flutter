import 'package:flutter/material.dart';
import '../utils/totp_store.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => AddAccountScreenState();
}

class AddAccountScreenState extends State<AddAccountScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;

  final platformCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final secretCtrl = TextEditingController();
  final qrCtrl = TextEditingController();

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
    final cleaned = input
        .replaceAll(' ', '')
        .replaceAll('=', '')
        .toUpperCase();

    final regex = RegExp(r'^[A-Z2-7]+$');
    return cleaned.isNotEmpty && regex.hasMatch(cleaned);
  }

  Future<void> saveManual() async {
    final platform = platformCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    final secret = secretCtrl.text.replaceAll(' ', '').toUpperCase();

    if (platform.isEmpty || username.isEmpty || secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    if (!isValidBase32(secret)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Base32 secret')),
      );
      return;
    }

    final url = buildTotpUrl(
      platform: platform,
      username: username,
      secret: secret,
    );

    await TotpStore.add(url);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> saveQr() async {
    final text = qrCtrl.text.trim();

    if (!text.startsWith('otpauth://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid otpauth URL')),
      );
      return;
    }

    await TotpStore.add(text);

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Paste otpauth URL',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qrCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'otpauth://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: saveQr,
                  child: const Text('Save'),
                ),
              ],
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
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secretCtrl,
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
