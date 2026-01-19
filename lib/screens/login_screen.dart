import 'package:flutter/material.dart';
import '../utils/storage.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const LoginScreen({super.key, required this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = TextEditingController();
  bool obscure = true;
  String? error;

  Future<void> _login() async {
    final ok = await Storage.verifyMasterPassword(controller.text);
    if (!ok) {
      setState(() => error = 'Wrong password');
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(onToggleTheme: widget.onToggleTheme),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: const Text('Login'),
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
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Master Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => obscure = !obscure),
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
            ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}
