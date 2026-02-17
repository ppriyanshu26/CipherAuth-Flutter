import 'package:flutter/material.dart';

import '../utils/support_helpers.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => SupportScreenState();
}

class SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Need Help?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Contact me for support or view our policies',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('Send me an email'),
              children: [
                supportTileData([
                  const Text(
                    'Email me at:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const SelectableText('cipherauth@ppriyanshu26.online'),
                  const SizedBox(height: 8),
                  const Text(
                    'I would typically respond within 24-48 hours.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.description),
              title: const Text('Privacy Policy'),
              subtitle: const Text('View the privacy policy'),
              children: [
                supportTileData([
                  const SelectableText(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Data Storage',
                    'All data is stored locally on your device. The app uses AES-256-GCM encryption for all sensitive information. No cloud upload.',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'What The App Stores',
                    '• TOTP credentials (platform, username, secret)\n• Master password hash (SHA-256)\n• Biometric settings\n• Theme preferences',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'What The App Doesn\'t Collect',
                    '✗ No personal data\n✗ No analytics/tracking\n✗ No usage data\n✗ No biometric samples\n✗ No cloud sync',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Synchronization',
                    'Local network only (same WiFi). Encrypted data transmission. Both devices must have same master password. No internet involved.',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Your Rights',
                    'Export, delete, or reset your data anytime. Full control.',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Permissions',
                    '1. Storage: Used to save exported CSVs to Downloads and to browse QR images when you use the QR import flow; the app never transmits or reads any other files.\n2. Camera: Needed only for scanning QR codes when you add credetials; nothing is stored or shared.\n3. Network access: Required for local sync feature to discover other devices over your LAN and exchange encrypted data; there is no internet upload.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This app is designed with privacy in mind. If you have any questions or concerns about our policies, please contact me.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Terms of Service'),
              subtitle: const Text('View the terms and conditions'),
              children: [
                supportTileData([
                  const SelectableText(
                    'Terms of Service',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'By using CipherAuth, you agree to the terms of service. This application is provided "as is" without any warranties. You are responsible for maintaining the security of your master password.',
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'As everythig is stored locally and there is no account system, there are no user obligations or account-related terms. The main responsibility is to keep your master password secure, as it is the key to all your credentials.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.help),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              children: [
                supportTileData([
                  const SelectableText(
                    'Q: How secure is CipherAuth?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const SelectableText(
                    'A: CipherAuth uses military-grade  AES-GCM encryption to protect your credentials and maintain integrity.',
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'Q: What if I forget my master password?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const SelectableText(
                    'A: If you forget your master password, there is no way to recover your data. There are no "backdoors" or password recovery options for your security. Please ensure you keep your password in a safe place. It is highly advisable to turn on biometric protection as a backup to your master password for easier access while maintaining security.',
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'Q: How do I add or delete a credential?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const SelectableText(
                    'A: Use the Add Account flow to save a new credential, and tap and hold on a credential on the home screen to delete it.',
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'Q: What if someone gains access to my device?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const SelectableText(
                    'A: All data stays encrypted locally using your master password or biometric protection; without that master password, the stored credentials are unreadable.',
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'Q: Can I sync the creds with other authenticator apps?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const SelectableText(
                    'A: With no cloud upload, synchronization is limited to other CipherAuth devices over your local network; the app does not exchange data with third-party authenticator apps. However, you can export generated TOTP secrets as QR codes and scan them with other apps if you wish to migrate or use multiple authenticators.',
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.handshake),
              title: const Text('Collaborate & Feedback'),
              subtitle: const Text('Help me develop for other platforms'),
              children: [
                supportTileData([
                  const Text(
                    'Interested in Contributing?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'If you wish to collaborate and develop and test apps on other platforms, you are free to edit and mail your suggestions.\nHere is the github repository for the project:',
                  ),
                  const SizedBox(height: 4),
                  supportLinkButton(
                    this,
                    'https://github.com/ppriyanshu26/CipherAuth-Flutter',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Contact me at:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const SelectableText('cipherauth@ppriyanshu26.online'),
                  const SizedBox(height: 12),
                  const Text(
                    'I look forward to hearing from you!',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
