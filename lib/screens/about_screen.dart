import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About CipherAuth'), scrolledUnderElevation: 0),
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
                    'Version 6.5.4',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CipherAuth is a secure password and authentication manager that helps you store and manage your credentials safely.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
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
                '© 2026 Priyanshu Priyam\nThis app is open source and available on GitHub.\nContributions are welcome!!!',
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
