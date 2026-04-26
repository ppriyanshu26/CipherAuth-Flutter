import 'package:flutter/material.dart';
import '../utils/services/storage_service.dart';
import '../utils/crypto/runtime_key.dart';
import '../utils/services/biometric_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  String? error;
  bool isLoading = false;

  Future<void> resetPassword() async {
    if (oldPasswordController.text.isEmpty) {
      setState(() => error = 'Old password is required');
      return;
    }

    if (newPasswordController.text.isEmpty) {
      setState(() => error = 'New password is required');
      return;
    }

    if (confirmPasswordController.text.isEmpty) {
      setState(() => error = 'Please confirm new password');
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() => error = 'New passwords do not match');
      return;
    }

    if (newPasswordController.text == oldPasswordController.text) {
      setState(
        () => error = 'New password must be different from old password',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final ok = await Storage.verifyMasterPassword(oldPasswordController.text);
      if (!ok) {
        setState(() {
          error = 'Wrong password';
          isLoading = false;
        });
        return;
      }
      await Storage.resetMasterPassword(
        oldPasswordController.text,
        newPasswordController.text,
      );
      await BiometricService.updateBiometricPassword(
        newPasswordController.text,
      );
      RuntimeKey.rawPassword = newPasswordController.text;

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        error = 'Error resetting password';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Your Password'),
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: obscureOld,
                onSubmitted: (_) => resetPassword(),
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOld ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                onSubmitted: (_) => resetPassword(),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                onSubmitted: (_) => resetPassword(),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reset Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
