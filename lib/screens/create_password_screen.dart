import 'package:flutter/material.dart';
import '../utils/services/storage_service.dart';
import 'login_screen.dart';
import '../widgets/passphrase_generator_dialog.dart';

class CreatePasswordScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CreatePasswordScreen({super.key, required this.onToggleTheme});

  @override
  State<CreatePasswordScreen> createState() => CreatePasswordScreenState();
}

class CreatePasswordScreenState extends State<CreatePasswordScreen> with SingleTickerProviderStateMixin {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final scrollController = ScrollController();
  final passwordFocus = FocusNode();
  final confirmFocus = FocusNode();
  final passwordFieldKey = GlobalKey();
  bool obscure1 = true;
  bool obscure2 = true;
  String? error;
  late AnimationController animationController;
  late Animation<double> bounceAnimation;
  bool showHint = true; 

  @override
  void initState() {
    super.initState();
    passwordFocus.addListener(handleFocusChange);
    confirmFocus.addListener(handleFocusChange);

    animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    bounceAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
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

    if (p1.length < 12) {
      setState(() => error = 'Minimum 12 characters');
      return;
    }
    if (p1 != p2) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: const Text('I agree that I have copied my password and saved it. If I forget it beyond this point, I can never reset it and recover my data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('I Agree')),
        ],
      ),
    );

    if (confirm != true) return;

    final navigator = Navigator.of(context);
    await Storage.saveMasterPassword(p1);
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(onToggleTheme: widget.onToggleTheme),
      ),
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    scrollController.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Password'), scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (showHint) {
                  setState(() => showHint = false);
                }
                FocusScope.of(context).unfocus();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const PassphraseGeneratorDialog();
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_reset),
                    if (showHint)
                      AnimatedBuilder(
                        animation: bounceAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, bounceAnimation.value),
                            child: child,
                          );
                        },
                        child: const Text('Click Here!!!!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
                    'This password will be used to keep your vault data encrypted, unreadable and completely local.\nIf you forget it, there is no way to recover your data.\nThe safety of YOUR data is YOUR responsibility.',
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