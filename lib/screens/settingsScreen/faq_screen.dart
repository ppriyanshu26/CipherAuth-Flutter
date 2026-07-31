import 'package:flutter/material.dart';
import '../../utils/ui/support_helpers.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  final List<Map<String, String>> faqItems = const [
    {
      'question': 'How secure is CipherAuth?',
      'answer': 'CipherAuth uses military-grade AES-GCM encryption to protect your credentials and maintain integrity. Every bit of information is stored as ciphertext in the device storage and the OS KeyStore, and only decrypted in runtime memory.',
    },
    {
      'question': 'What is MFA or 2FA?',
      'answer': 'Multi or 2 Factor Authentication adds a second layer to the safety of your accounts, asking for a configured service and a login success with password. This ensures that it is the rightful owner accessing his account. Traditionally SMS and Email OTPs are used, but they pose an eavesropping risk. TOTP based authenticators remove this factor as the code is refreshed twice a minute, and is always locally available in your device.',
    },
    {
      'question': 'What are passphrases?',
      'answer': 'Passphrases are sequences of random words (e.g., "correct-bell-pepper-salt") instead of traditional passwords. Because of their length, they are highly secure and extremely difficult for computers to brute-force, yet much easier to remember and type.',
    },
    {
      'question': 'What is autofill?',
      'answer': 'Copying passwords and pasting them poses a risk, clipboard is an open book for all the apps to read and write to. To make you secure from password thefts, CipherAuth integrates with the operating system itself, which tells the app the url of the website, and CipherAuth securely fills the credentials directly in the input fields. For browsers, change their settings to allow 3rd party apps to autofill.',
    },
    {
      'question': 'How does autofill work?',
      'answer': 'You are asked for a URL while creating a password. This plus the username is a unique identifier of the password. During autofill, the OS hands over the url of the browser to CipherAuth and the only the filtered credentials are returned.',
    },
    {
      'question': 'What is Local Sync?',
      'answer': 'Since CipherAuth doesn\'t have a cloud server, syncing manually between every device is a pain, in sync, your devices should be on the same network and have the same password. Encrypted credentials from one device are sent over to the other, decrypted, processed, merged, and sent back again encrypted. Anyone sniffing the packets will only see a ciphertext.',
    },
    {
      'question': 'Are devices with different versions compatible with other?',
      'answer': 'The core concept of the app is privacy and it is still ever since the app was made. However with newer versions, it gets better and convenient. It is advisable to keep your app updated. Although backward and forward compatibility is implemented wherever it could be, some features in sync and import could break since both apps have different versions. Please keep your backup csv files at all times.',
    },
    {
      'question': 'Is exporting a csv file safe?',
      'answer': 'Yes, even the csv files are encrypted and can only be decrypted by the same password it was used to encrypt. Your digital identity is completely secure and truly in your hands. It is saved in your Downloads directory. However, still it is a better approach to safeguard this file.',
    },
    {
      'question': 'How does the import work?',
      'answer': 'Importing a file works only if it has not been tampered with and you know the password which which it was encrypted. It scans the file data and current vault and prompts the user of new accounts that are found and ready to be added.',
    },
    {
      'question': 'What if I forget my master password?',
      'answer': 'If you forget your master password, there is no way to recover your data. There are no "backdoors" or password recovery options for your security. Please ensure you keep your password in a safe place. It is highly advisable to turn on biometric protection as a backup to your master password for easier access while maintaining security.',
    },
    {
      'question': 'Is permanent delete applied to all my devices?',
      'answer': 'No. CipherAuth has no central server to force-delete entries everywhere. Permanent delete only affects the current device. If another device still has the same credential (in the main list or its Recycle Bin), a later sync can add it back as a fresh entry. Even importing from an exported csv file can resurrect the deleted credentials.',
    },
    {
      'question': 'What if someone gains access to my device?',
      'answer': 'All data stays encrypted locally using your master password or biometric protection; without that master password, the stored credentials are unreadable.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs'), scrolledUnderElevation: 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Feel free to contact me or leave a review if any issues.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: faqItems.length,
              itemBuilder: (context, index) {
                final faq = faqItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    child: ExpansionTile(
                      title: Text(faq['question']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        supportTileData([SelectableText(faq['answer']!, style: const TextStyle(height: 1.4))]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
