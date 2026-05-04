import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/ui/app_flavor.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=in.ppriyanshu.cipherauth';
    const msStoreUrl = 'https://apps.microsoft.com/detail/9NS2R9NTRF2Z';

    return Scaffold(
      appBar: AppBar(
        title: Text('About ${AppFlavorConfig.aboutTitle}'),
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Version 7.4.5',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CipherAuth is a secure local-first authenticator that helps you store and manage your 2FA credentials securely solely on your device.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️  Important: Although everything is on your device, if you forget your master password, there is no way to retrieve your encrypted credentials. Please keep your password safe and secure.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  if (isWindows) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Install on your Android phone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/play.png',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Scan this QR to open Google Play',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: playStoreUrl,
                        version: QrVersions.auto,
                        size: 200,
                        embeddedImage: AssetImage('assets/icon/icon.png'),
                        embeddedImageStyle: QrEmbeddedImageStyle(
                          size: Size(40, 40),
                        ),
                      ),
                    ),
                  ],

                  if (isAndroid) ...[
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(msStoreUrl);
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icon/store.png',
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              'Get CipherAuth from Microsoft Store',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.underline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(
                                'https://www.github.com/ppriyanshu26/',
                              );
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Image.asset(
                              'assets/social/github.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ppriyanshu26',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(
                                'https://www.linkedin.com/in/ppriyanshu26/',
                              );
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Image.asset(
                              'assets/social/linkedin.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ppriyanshu26',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(
                                'https://www.instagram.com/ppriyanshu26_/',
                              );
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Image.asset(
                              'assets/social/instagram.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ppriyanshu26_',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '© 2026 Priyanshu Priyam\nThis app is source-available on GitHub.\nFor licensing and contribution inquiries, please contact the developer.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
