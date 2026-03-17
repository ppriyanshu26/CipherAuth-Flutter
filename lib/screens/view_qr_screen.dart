import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/totp_store.dart';
import '../utils/storage.dart';
import '../utils/biometric_service.dart';
import '../utils/runtime_key.dart';

class ViewQrScreen extends StatefulWidget {
  const ViewQrScreen({super.key});

  @override
  State<ViewQrScreen> createState() => ViewQrScreenState();
}

class ViewQrScreenState extends State<ViewQrScreen> {
  final passwordController = TextEditingController();
  List<Map<String, String>> totps = [];
  bool isPasswordVerified = false;
  String? selectedIndex;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool canUseBiometrics = false;
  bool isBioEnabled = false;
  bool isAuthenticating = false;
  String? error;

  @override
  void initState() {
    super.initState();
    startupBiometric();
  }

  Future<void> startupBiometric() async {
    await checkBio();
    if (!mounted) return;
    if (canUseBiometrics && isBioEnabled) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          bioAuth();
        }
      });
    }
  }

  Future<void> checkBio() async {
    final canUse = await BiometricService.canUseBiometrics();
    final bioEnabled = await BiometricService.isBiometricEnabled();
    setState(() {
      canUseBiometrics = canUse;
      isBioEnabled = bioEnabled;
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> verifyPassword() async {
    if (passwordController.text.isEmpty) {
      setState(() => error = 'Password cannot be empty');
      return;
    }

    setState(() => isLoading = true);
    try {
      final isValid = await Storage.verifyMasterPassword(
        passwordController.text,
      );

      if (isValid) {
        final list = await TotpStore.load();
        setState(() {
          totps = list;
          isPasswordVerified = true;
          error = null;
        });
      } else {
        setState(() => error = 'Wrong password');
      }
    } catch (e) {
      setState(() => error = 'Error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> bioAuth() async {
    setState(() => isAuthenticating = true);
    final (authenticated, _) = await BiometricService.authenticateWithError();

    if (!mounted) return;
    if (authenticated) {
      final password = await BiometricService.getStoredMasterPassword();
      if (!mounted) return;

      if (password != null) {
        RuntimeKey.rawPassword = password;
        try {
          final list = await TotpStore.load();
          setState(() {
            totps = list;
            isPasswordVerified = true;
            isAuthenticating = false;
            error = null;
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            isAuthenticating = false;
            error = 'Error: ${e.toString()}';
          });
        }
      } else {
        setState(() {
          isAuthenticating = false;
          error = 'Biometric password not found. Please use password';
        });
      }
    } else {
      setState(() {
        isAuthenticating = false;
        error = 'Biometric authentication failed';
      });
    }
  }

  String generateOtpauthUrl(Map<String, String> item) {
    final secret = item['secretcode']!;
    final username = item['username'] ?? '';
    final platform = item['platform']!;

    return 'otpauth://totp/$platform:$username?secret=$secret&issuer=$platform';
  }

  @override
  Widget build(BuildContext context) {
    if (!isPasswordVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('View QR'), scrolledUnderElevation: 0),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This app is developed keeping privacy in mind, be sure with who you share the QR codes, it is advisable to use the sync feature to securely sync with your devices',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter your password to view QR codes',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                onSubmitted: (_) => verifyPassword(),
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyPassword,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ),
              if (canUseBiometrics && isBioEnabled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isAuthenticating ? null : bioAuth,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Try Biometric'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (selectedIndex == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Credential'),
          scrolledUnderElevation: 0,
        ),
        body: totps.isEmpty
            ? const Center(child: Text('No credentials found'))
            : ListView.builder(
                itemCount: totps.length,
                itemBuilder: (context, index) {
                  final item = totps[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        item['platform']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item['username'] ?? ''),
                      trailing: const Icon(Icons.qr_code),
                      onTap: () {
                        setState(() => selectedIndex = index.toString());
                      },
                    ),
                  );
                },
              ),
      );
    }

    final index = int.parse(selectedIndex!);
    final item = totps[index];
    final otpauthUrl = generateOtpauthUrl(item);

    return Scaffold(
      appBar: AppBar(
        title: Text(item['platform']!),
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => selectedIndex = null);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['platform']!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['username'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
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
                  data: otpauthUrl,
                  version: QrVersions.auto,
                  size: 250,
                  embeddedImage: const AssetImage('assets/icon/icon.png'),
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: const Size(60, 60),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Scan this QR code with your authenticator app',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Text(
                'Or use secret key:\nTap to copy it!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final secretKey = item['secretcode']!;
                  Clipboard.setData(ClipboardData(text: secretKey));
                  if (!context.mounted) return;

                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Secret key copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Text(
                    item['secretcode']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
