import 'package:flutter/material.dart';

import '../../utils/ui/support_helpers.dart';

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
          const Text('Need Help?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Contact me for support or view the policies', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('Send me an email'),
              children: [
                supportTileData([
                  const Text('Email me at:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const SelectableText('cipherauth@ppriyanshu26.online'),
                  const SizedBox(height: 8),
                  const Text('I would typically respond within 24-48 hours.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                  const SelectableText('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'License Model',
                    'CipherAuth is source-available software. See the LICENSE file for usage and redistribution terms.'),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Data Storage',
                    'All data is stored locally on your device. The app uses AES-256-GCM encryption for all sensitive information. No cloud upload.',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'What The App Stores',
                    '• Encrypted Passwords & TOTP credentials \n• Biometric settings \n• Theme preferences',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'What The App Doesn\'t Collect',
                    '✗ No login information \n✗ No personal data \n✗ No analytics/tracking \n✗ No cloud sync',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Synchronization',
                    'Local network only (same WiFi band). Encrypted data transmission. Both devices must have same master password. No internet involved.',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Your Rights',
                    'Export, delete, or reset your data anytime. Full control.',
                  ),
                  const SizedBox(height: 12),
                  supportPolicySection(
                    'Permissions',
                    '1. Storage: Used to save exported CSVs to Downloads and to browse QR images when you use the QR import flow; the app never transmits or reads any other files.\n2. Camera: Needed only for scanning QR codes when you add credentials; nothing is stored or shared.\n3. Network access: Required for local sync feature to discover other devices over your LAN and exchange encrypted data; there is no internet upload.\n4. Biometric auth: Used only if you enable biometric unlock.\n5. Autofill: Used to fill your usernames and passwords in other apps.',
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
                  supportLinkButton(this,'https://github.com/ppriyanshu26/CipherAuth-Flutter/blob/main/LICENSE'),
                  const SizedBox(height: 8),
                  supportLinkButton(this, 'https://gist.github.com/ppriyanshu26/b9c863813ee032a9ffd9f94ff1f78aee'),
                  const SizedBox(height: 12),
                  const Text('This app is designed with privacy in mind. If you have any questions or concerns about the policies, please contact me.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                  const SelectableText('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const SelectableText('By using CipherAuth, you agree to the terms of service. This application is provided "as is" without any warranties. You are responsible for maintaining the security of your master password. The safety of your DIGITAL IDENTITY is solely your responsibility.'),
                  const SizedBox(height: 12),
                  const SelectableText('Source code is provided for transparency and learning. Reuse, redistribution, and derivative standalone releases require prior written permission. As everything is stored locally and there is no account system, there are no account-related user obligations. The main responsibility is to keep your master password secure, as it is the key to your credentials.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                  const SelectableText('Q: How secure is CipherAuth?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: CipherAuth uses military-grade AES-GCM encryption to protect your credentials and maintain integrity.'),
                  const SizedBox(height: 12),
                  const SelectableText('Q: What are passphrases?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: Passphrases are sequences of random words (e.g., "correct-bell-pepper-salt") instead of traditional passwords. Because of their length, they are highly secure and extremely difficult for computers to brute-force, yet much easier to remember and type.'),
                  const SizedBox(height: 12),
                  const SelectableText('Q: How does autofill work?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: Copying passwords and pasting them poses a risk, clipboard is an open book for all the apps to read and write to. To make you secure from password thefts, CipherAuth integrates with the operating system itself, which tells the app the url of the website, and CipherAuth securely fills the credentials directly in the input fields. For browsers, change their settings to allow 3rd party apps to autofill.'),
                  const SizedBox(height: 12),
                  const SelectableText('Q: What is Local Sync?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: Since CipherAuth doesn\'t have a cloud server, syncing manually between every device is a pain, in sync, your devices should be on the same network and have the same password. Encrypted credentials from one device are sent over to the other, decrypted, processed, merged, and sent back again encrypted. Anyone sniffing the packets will only see a ciphertext.'),
                  const SizedBox(height: 12),
                  const SelectableText('Q: Is a backup csv file safe?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: Yes, even the csv files are encrypted and can only be decrypted by the same password it was used to encrypt. Your digital identity is completely secure and truly in your hands.'),
                  const SizedBox(height: 12),
                  const SelectableText('Q: What if I forget my master password?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: If you forget your master password, there is no way to recover your data. There are no "backdoors" or password recovery options for your security. Please ensure you keep your password in a safe place. It is highly advisable to turn on biometric protection as a backup to your master password for easier access while maintaining security.'),
                  const SizedBox(height: 12),
                  const SelectableText('Q: Is permanent delete applied to all my devices?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: No. CipherAuth has no central server to force-delete entries everywhere. Permanent delete only affects the current device. If another device still has the same credential (in the main list or its Recycle Bin), a later sync can add it back as a fresh entry. Even importing from an exported csv file can resurrect the deleted credentials.'),
                  const SizedBox(height: 12),
                  const SelectableText('Q: What if someone gains access to my device?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const SelectableText('A: All data stays encrypted locally using your master password or biometric protection; without that master password, the stored credentials are unreadable.'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.handshake),
              title: const Text('Feedback & Contributions'),
              subtitle: const Text('Suggestions and permission requests'),
              children: [
                supportTileData([
                  const Text('Source-Available Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const SelectableText('CipherAuth is source-available. You may review the code for transparency and learning, but redistribution, relicensing, or publishing modified builds requires prior written permission.\n\nFor feature requests, bug reports, business licensing, or collaboration inquiries, use the repository and email below:'),
                  const SizedBox(height: 4),
                  supportLinkButton(this, 'https://github.com/ppriyanshu26/CipherAuth-Flutter'),
                  const SizedBox(height: 12),
                  const Text('Contact me at:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const SelectableText('cipherauth@ppriyanshu26.online'),
                  const SizedBox(height: 12),
                  const Text('Thankyou for using CipherAuth! I look forward to hearing from you!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
