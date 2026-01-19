import 'package:flutter/material.dart';
import '../utils/storage.dart';
import 'create_password_screen.dart';
import 'login_screen.dart';

class StartupScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const StartupScreen({super.key, required this.onToggleTheme});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool? hasPassword;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    hasPassword = await Storage.hasMasterPassword();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (hasPassword == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return hasPassword!
        ? LoginScreen(onToggleTheme: widget.onToggleTheme)
        : CreatePasswordScreen(onToggleTheme: widget.onToggleTheme);
  }
}
