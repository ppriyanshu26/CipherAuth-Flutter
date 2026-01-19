import 'package:flutter/material.dart';
import 'screens/startup_screen.dart';
import 'utils/storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await Storage.isDarkMode();
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme() async {
    final isDark = _themeMode == ThemeMode.dark;
    await Storage.setDarkMode(!isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: StartupScreen(onToggleTheme: toggleTheme),
    );
  }
}
