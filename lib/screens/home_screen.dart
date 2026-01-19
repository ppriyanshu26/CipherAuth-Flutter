import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: const Center(
        child: Text('Hello', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
