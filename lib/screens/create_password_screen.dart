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

  final _scrollController = ScrollController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _passwordFieldKey = GlobalKey();

  bool obscure1 = true;
  bool obscure2 = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(_handleFocusChange);
    _confirmFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_passwordFocus.hasFocus || _confirmFocus.hasFocus) {
      _scrollToFirstField();
    }
  }

  void _scrollToFirstField() {
    final fieldContext = _passwordFieldKey.currentContext;
    if (fieldContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        fieldContext,
        alignment: 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final ctx = _passwordFieldKey.currentContext;
      if (ctx == null) return;
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
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    _scrollController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
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
            controller: _scrollController,
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
                    'Your Credentials, Your Device. Privacy meets Convenience.',
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
                    key: _passwordFieldKey,
                    focusNode: _passwordFocus,
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
                    focusNode: _confirmFocus,
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
