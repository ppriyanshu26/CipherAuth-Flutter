import 'package:flutter/material.dart';

class ChangelogEntry {
  final String date;
  final String version;
  final List<String> points;
  final bool isRelease;

  const ChangelogEntry({required this.date, required this.version, required this.points, this.isRelease = false});
}

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  final List<ChangelogEntry> changelogEntries = const [
    ChangelogEntry(
      date: '1st August, 2026',
      version: 'v8.1.0',
      points: [
        'Dedicated tab for FAQs in settings so it\'s easier to find and resolve some common queries.',
        'Users can now see the changes in each version for transparency.',
        'Password details are equipped with their authenticator codes.',
        'While autofilling passwords (Android), users can opt for \'add password\', and make a new login entry for the specific app opened.',
        'Strict checks on duplicate entries in passwords removed as they can be identified by their hash-id and creation time.',
        'Backward and Forward compatibility in importing csv files generated from a different versioned app.',
      ],
    ),
    ChangelogEntry(
      date: '10th June, 2026',
      version: 'v8.0.0',
      points: [
        'CipherAuth now has a dedicated tab for managing your passwords.',
        'Password hash is completely removed from the device storage, and authentication happens by decrypting the vault with the password entered.',
        'Local Sync is now faster without sharing the password hash over the network.',
        'Autofill your login credentials directly on apps and browsers. Currently supported in Android only.',
        'Say goodbye to passwords, say hello to passphrases. Easy to remember, harder to crack.',
        'Import and export of backup files is now more smooth.',
        'Long press a credential to view its details.',
      ],
    ),
    ChangelogEntry(
      date: '4th May, 2026',
      version: 'Google Play Store Release',
      isRelease: true,
      points: [
        'CipherAuth is now available on the Google Play Store for Android users, providing a seamless installation and update experience directly through the official channel.',
      ],
    ),
    ChangelogEntry(
      date: '4th May, 2026',
      version: 'v7.4.4',
      points: [
        'About screen updated with Google Play Store and Microsoft Store links.',
      ],
    ),
    ChangelogEntry(
      date: '4th May, 2026',
      version: 'v7.4.3',
      points: [
        'Users get a disclaimer on the create password screen to always remember their password as there as no back doors.',
      ],
    ),
    ChangelogEntry(
      date: '4th May, 2026',
      version: 'v7.4.2',
      points: [
        'On adding account, first character in every word of the platform name is capitalized.',
        'Platform name is further truncated on mobile devices for clean UI.',
      ],
    ),
    ChangelogEntry(
      date: '1st May, 2026',
      version: 'v7.4.1',
      points: [
        'Snackbar now comes with an undo button to quickly restore an accidentally deleted credential.',
        'Adding an account by scanning a QR is made more modern by a square layout and toggle button for flashlight.',
        'Android now handles files with same names more reliably, than appending numbers at last.',
        'The URLs in QR codes now handles encoding for special characters, and extracting the username by itself if not mentioned explicitly.',
        'Added icons on empty screens.',
      ],
    ),
    ChangelogEntry(
      date: '22nd April, 2026',
      version: 'v7.3.2',
      points: [
        'Deleted credentials now move to Recycle Bin instead of being removed immediately, with a 30-day retention window for recovery.',
        'Users can restore entries from Recycle Bin or permanently delete them when they want immediate cleanup.',
        'Added clear notes about deletion behavior, including that permanent delete is device-local and a later sync can re-add a credential as a fresh entry if another device still has it.',
      ],
    ),
    ChangelogEntry(
      date: '3rd April, 2026',
      version: 'v7.2.2',
      points: [
        'CipherAuth now deals additional icon support on the home screen UI.',
        'Added notes to let users know of the key details they should take care of.',
      ],
    ),
    ChangelogEntry(
      date: '30th March, 2026',
      version: 'v7.2.1',
      points: [
        'Scan any compatible QR with the native mobile camera app, and get directed to CipherAuth to add your account.',
        'Accidental touch outside the password input popup during import creds now returns a toast.',
      ],
    ),
    ChangelogEntry(
      date: '26th March, 2026',
      version: 'v7.1.0',
      points: [
        'The .csv file saved as backup to device is now encrypted and needs a password to decrypt it on import.',
        'Users can only use their password to view the QR to boost security.',
      ],
    ),
    ChangelogEntry(
      date: '25th March, 2026',
      version: 'v7.0.0',
      points: [
        'All files access permission that was blocking Play Store upload.',
        'Users can choose where to save (including Downloads) instead of the app writing directly to restricted storage.',
      ],
    ),
    ChangelogEntry(
      date: '23rd March, 2026',
      version: 'v6.5.5',
      points: [
        'A clear uniform policy for redistribution and transparency.',
      ],
    ),
    ChangelogEntry(
      date: '17th March, 2026',
      version: 'v6.5.4',
      points: [
        'Light Theme Correction and Snackbar to let users know secret key is copied.',
      ],
    ),
    ChangelogEntry(
      date: '26th February, 2026',
      version: 'v6.5.3',
      points: [
        'Snackbars now are of minimal color scheme.',
        'Screenshots are blocked and password is asked on resume in android application.',
        'Sync feature now handles deleted credentials and considers the created timestamp to add them back.',
      ],
    ),
    ChangelogEntry(
      date: '23rd February, 2026',
      version: 'v6.5.2',
      points: [
        'Sync now helps keep track of deleted accounts top provide consistent sharing of the same set of credentials across multiple devices.',
        'Users are shown a statement regarding the potential risks of viewing QRs and are prompted to use sync for encrypted sharing.',
        'Adjusted spacings between containers and consistent logic across similar screens.',
      ],
    ),
    ChangelogEntry(
      date: '23rd February, 2026',
      version: 'v6.3.2',
      points: [
        'Enhanced UI/UX for better navigation and organization.',
        'Users can now easily import their credentials into the app.',
        'Consistent design language throughout the application.',
        'Users receive the biometric authentication prompt automatically upon launching the app',
        'Account listings now display icons for quick visual identification.',
      ],
    ),
    ChangelogEntry(
      date: '17th February, 2026',
      version: 'v6.1.2',
      points: [
        'Added ability to browse and import QR images directly from device storage.',
        'New dedicated about screen with app information.',
        'Added support screen with contact and feedback options.',
      ],
    ),
    ChangelogEntry(
      date: '15th February, 2026',
      version: 'v6.0.0',
      points: [
        'A secure, cross-platform, local TOTP authenticator for simplicity and security.',
      ],
    ),
    ChangelogEntry(
      date: '4th February, 2026',
      version: 'v5.0.0.0',
      points: [
        'Replaced .ico format with .png for universal compatibility across Windows, macOS, and Linux.',
        'Fixed icon file path handling for both development and compiled executable environments.',
        'Added application icon overlay in the center of generated QR codes.',
        'Fixed PyInstaller path resolution to properly locate icon file in bundled app using sys._MEIPASS',
        'PyInstaller now correctly handles cross-platform deployment without code changes.',
        'Icon integration works seamlessly in both development (python app/main.py) and production (compiled EXE/Microsoft Store)',
        'QR code generation automatically uses bundled icon when app is packaged',
      ],
    ),
    ChangelogEntry(
      date: '25th January, 2026',
      version: 'v4.0.1.0',
      points: [
        'Added an eye button to toggle between hidden and visible states for sensitive secrets.',
      ],
    ),
    ChangelogEntry(
      date: '19th January, 2026',
      version: 'v4.0.0.0',
      points: [
        'Better keyboard navigation with Enter/Escape support.',
        'Tap to reveal/blur QR codes; displayed blurred by default for enhanced security.',
        'Removed keyring dependency',
        'Added reusable utility functions for text truncation',
        'Enhanced toast notification styling',
      ],
    ),
    ChangelogEntry(
      date: '12th January, 2026',
      version: 'Microsoft Store Release',
      isRelease: true,
      points: [
        'CipherAuth is now available on the Microsoft Store for Windows users, providing a seamless installation and update experience directly through the official channel.',
      ],
    ),
    ChangelogEntry(
      date: '11th January, 2026',
      version: 'v3.0.0.0',
      points: [
        'Upgraded data encryption to use AES-GCM for better integrity and security of your stored tokens.',
        'Refined search bar interactions and smoother transitions between screens.',
        'Improved blurring and revealing logic for QR codes to protect against shoulder-surfing.',
        'Optimized the .spec file for PyInstaller to ensure stable builds across platforms without source modifications.',
        'A more robust password reset handler that securely re-encrypts all local data.',
      ],
    ),
    ChangelogEntry(
      date: '3rd September, 2025',
      version: 'v2.0.0',
      points: [
        'Introduced a separate application for QR extraction, text encryption, and management of the encoded.txt file.',
        'The Authenticator now leverages the system credentials manager for enhanced security and robustness.',
        'Both applications can now be executed from any directory, without generating extra or redundant data.',
      ],
    ),
    ChangelogEntry(
      date: '27th August, 2025',
      version: 'v1.1.0',
      points: [
        'Ensured only one popup opens at a time.',
        'Ensured popups open inside the app.',
      ],
    ),
    ChangelogEntry(
      date: '26th August, 2025',
      version: 'v1.0.0',
      points: [
        'Minimal & user-friendly interface.',
        'Offline OTP generation.',
        'Secure and portable.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Changelog'), scrolledUnderElevation: 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('A security software you can\'t audit, is a security software you shouldn\'t trust.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: changelogEntries.length,
              itemBuilder: (context, index) {
                final entry = changelogEntries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                entry.isRelease ? Icons.rocket_launch : Icons.commit,
                                size: 18,
                                color: entry.isRelease ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: 
                                  Text(entry.version, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: entry.isRelease ? Colors.green : Colors.orange)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(entry.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.5),
                    ...entry.points.map((point) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 10),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: entry.isRelease ? Colors.green.withValues(alpha: 0.7) : theme.colorScheme.primary.withValues(alpha: 0.7),
                              ),
                            ),
                            Expanded(
                              child: SelectableText(point, style: const TextStyle(fontSize: 14, height: 1.4)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
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
