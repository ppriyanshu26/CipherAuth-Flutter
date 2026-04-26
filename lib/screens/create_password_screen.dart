import 'package:flutter/material.dart';
import '../utils/storage.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CreatePasswordScreen({super.key, required this.onToggleTheme});

  @override
  State<CreatePasswordScreen> createState() => CreatePasswordScreenState();
}

class CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;
  String? error;
  Future<void> create() async {
    final p1 = passwordController.text;
    final p2 = confirmController.text;

    if (p1.length < 8) {
      setState(() => error = 'Minimum 8 characters');
      return;
    }
    if (p1 != p2) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    await Storage.saveMasterPassword(p1);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(onToggleTheme: widget.onToggleTheme),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: const Text('Create Your Password'),
      scrolledUnderElevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
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
              controller: passwordController,
              obscureText: obscure1,
              onSubmitted: (_) => create(),
              decoration: InputDecoration(
                labelText: 'Master Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure1 ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => obscure1 = !obscure1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: obscure2,
              onSubmitted: (_) => create(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure2 ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => obscure2 = !obscure2),
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
                onPressed: create,
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
