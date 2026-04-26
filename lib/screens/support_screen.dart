import 'package:flutter/material.dart';

import '../utils/ui/support_helpers.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => SupportScreenState();
}

class SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support'), scrolledUnderElevation: 0),
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
                    'License Model',
                    'CipherAuth is source-available software (not open-source). See the LICENSE file for usage and redistribution terms.',
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
                    '1. Storage: Used to save exported CSVs to Downloads and to browse QR images when you use the QR import flow; the app never transmits or reads any other files.\n2. Camera: Needed only for scanning QR codes when you add credentials; nothing is stored or shared.\n3. Network access: Required for local sync feature to discover other devices over your LAN and exchange encrypted data; there is no internet upload.\n4. Biometric auth: Used only if you enable biometric unlock.',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Distribution Channels',
                    'CipherAuth app behavior is the same whether installed from GitHub Releases, Microsoft Store, or Google Play. Store/platform providers may process store-level telemetry under their own privacy policies.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Policy Files',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  supportLinkButton(
                    this,
                    'https://github.com/ppriyanshu26/CipherAuth-Flutter/blob/main/LICENSE',
                  ),
                  const SizedBox(height: 8),
                  supportLinkButton(
                    this,
                    'https://gist.github.com/ppriyanshu26/b9c863813ee032a9ffd9f94ff1f78aee',
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
                    'Source visibility is provided for transparency and learning. Reuse, redistribution, and derivative standalone releases require prior written permission. As everything is stored locally and there is no account system, there are no account-related user obligations. The main responsibility is to keep your master password secure, as it is the key to your credentials.',
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
                    'A: Use the Add Account flow to save a new credential. To delete, tap and hold a credential on the home screen; it is moved to Recycle Bin first. You can restore it within 30 days, or delete it permanently from Settings > Recycle Bin.',
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'Q: Is permanent delete applied to all my devices?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const SelectableText(
                    'A: No. CipherAuth has no central server to force-delete entries everywhere. Permanent delete only affects the current device. If another device still has the same credential (in the main list or its Recycle Bin), a later sync can add it back as a fresh entry.',
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
              title: const Text('Feedback & Licensing'),
              subtitle: const Text('Suggestions and permission requests'),
              children: [
                supportTileData([
                  const Text(
                    'Source-Available Notice',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'CipherAuth is source-available. You may review the code for transparency and learning, but redistribution, relicensing, or publishing modified builds requires prior written permission.\n\nFor feature requests, bug reports, business licensing, or collaboration inquiries, use the repository and email below:',
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
