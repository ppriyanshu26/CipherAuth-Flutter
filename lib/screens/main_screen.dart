import 'package:flutter/material.dart';
import 'authenticatorScreen/authenticator_screen.dart';
import 'passwordScreen/password_manager_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainScreen({super.key, required this.onToggleTheme});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  late final List<Widget> screens;
  
  final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    screens = [
      AuthenticatorScreen(onToggleTheme: widget.onToggleTheme, refreshNotifier: refreshNotifier),
      PasswordManagerScreen(onToggleTheme: widget.onToggleTheme, refreshNotifier: refreshNotifier),
    ];
  }

  @override
  void dispose() {
    refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Authenticator',
          ),
          NavigationDestination(
            icon: Icon(Icons.password_outlined),
            selectedIcon: Icon(Icons.password),
            label: 'Passwords',
          ),
        ],
      ),
    );
  }
}