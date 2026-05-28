import 'package:flutter/material.dart';
import '../utils/services/storage_service.dart';
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

  final scrollController = ScrollController();
  final passwordFocus = FocusNode();
  final confirmFocus = FocusNode();
  final passwordFieldKey = GlobalKey();

  bool obscure1 = true;
  bool obscure2 = true;
  String? error;

  @override
  void initState() {
    super.initState();
    passwordFocus.addListener(handleFocusChange);
    confirmFocus.addListener(handleFocusChange);
  }

  void handleFocusChange() {
    if (passwordFocus.hasFocus || confirmFocus.hasFocus) {
      scrollToFirstField();
    }
  }

  void scrollToFirstField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = passwordFieldKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final ctx = passwordFieldKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

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

    final navigator = Navigator.of(context);
    await Storage.saveMasterPassword(p1);
    if (!mounted) return;
    navigator.pushReplacement(
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
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    scrollController.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: appBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: keyboardOpen
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icon/icon.png', width: 100, height: 100),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Credentials, Your Device. \nPrivacy meets Convenience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Keep your password safe. If you forget it, there is no way to recover your data because you are responsible for the safety of your accounts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    key: passwordFieldKey,
                    focusNode: passwordFocus,
                    controller: passwordController,
                    obscureText: obscure1,
                    onSubmitted: (_) => create(),
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscure1 ? Icons.visibility : Icons.visibility_off),
                        tooltip: obscure1 ? 'Show Password' : 'Hide Password',
                        onPressed: () => setState(() => obscure1 = !obscure1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    focusNode: confirmFocus,
                    controller: confirmController,
                    obscureText: obscure2,
                    onSubmitted: (_) => create(),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscure2 ? Icons.visibility : Icons.visibility_off),
                        tooltip: obscure2 ? 'Show Password' : 'Hide Password',
                        onPressed: () => setState(() => obscure2 = !obscure2),
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
        },
      ),
    );
  }
}
