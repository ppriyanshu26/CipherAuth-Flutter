import 'package:flutter/material.dart';
import '../utils/storage.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CreatePasswordScreen({super.key, required this.onToggleTheme});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscure1 = true;
  bool obscure2 = true;
  String? error;

  Future<void> _create() async {
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

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: const Text('Create Master Password'),
      actions: [
        IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.wb_sunny
                : Icons.nightlight_round,
          ),
          onPressed: widget.onToggleTheme,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: passwordController,
              obscureText: obscure1,
              decoration: InputDecoration(
                labelText: 'Master Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure1 ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => obscure1 = !obscure1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: obscure2,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure2 ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => obscure2 = !obscure2),
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child:
                Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _create, child: const Text('Create')),
          ],
        ),
      ),
    );
  }
}
