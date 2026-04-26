import 'package:flutter/material.dart';
import '../utils/services/storage_service.dart';
import '../utils/crypto/runtime_key.dart';
import '../utils/services/biometric_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const LoginScreen({super.key, required this.onToggleTheme});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final controller = TextEditingController();
  bool obscure = true;
  String? error;
  bool canUseBiometrics = false;
  bool isBioEnabled = false;
  bool isAuthenticating = false;

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

  Future<void> bioAuth() async {
    setState(() => isAuthenticating = true);
    final (authenticated, _) = await BiometricService.authenticateWithError();

    if (!mounted) return;
    if (authenticated) {
      final password = await BiometricService.getStoredMasterPassword();
      if (!mounted) return;

      if (password != null) {
        RuntimeKey.rawPassword = password;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(onToggleTheme: widget.onToggleTheme),
          ),
        );
      } else {
        setState(() {
          error = 'Biometric password not found. Please enter manually.';
          isAuthenticating = false;
        });
      }
    } else {
      setState(() {
        error = 'Biometric authentication failed';
        isAuthenticating = false;
      });
    }
  }

  Future<void> login() async {
    final ok = await Storage.verifyMasterPassword(controller.text);
    if (!ok) {
      setState(() => error = 'Wrong password');
      return;
    }

    RuntimeKey.rawPassword = controller.text;
    if (!mounted) return;
    navigateToHome();
  }

  void navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(onToggleTheme: widget.onToggleTheme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login To Your Account'), scrolledUnderElevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/icon.png', width: 100, height: 100),
            const SizedBox(height: 12),
            const Text(
              'Your Credentials, Your Device. Offline Encrypted and Completely Private',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: controller,
              obscureText: obscure,
              onSubmitted: (_) => login(),
              decoration: InputDecoration(
                labelText: 'Master Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: login,
                child: const Text('Login'),
              ),
            ),
            if (canUseBiometrics && isBioEnabled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isAuthenticating ? null : bioAuth,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Biometric Login'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
