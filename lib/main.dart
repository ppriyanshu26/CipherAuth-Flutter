import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:app_links/app_links.dart';
import 'screens/startup_screen.dart';
import 'screens/add_account_screen.dart';
import 'utils/services/storage_service.dart';
import 'utils/ui/app_lifecycle_manager.dart';
import 'utils/ui/app_flavor.dart';
import 'utils/crypto/runtime_key.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFlavorConfig.initialize();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setMinimumSize(const Size(400, 600));
      await windowManager.setSize(const Size(700, 800));
      await windowManager.show();
    });
  }

  final lifecycleManager = AppLifecycleManager();
  await lifecycleManager.initialize();

  runApp(MyApp(lifecycleManager: lifecycleManager));
}

class MyApp extends StatefulWidget {
  final AppLifecycleManager lifecycleManager;

  const MyApp({super.key, required this.lifecycleManager});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.light;
  final navigatorKey = GlobalKey<NavigatorState>();
  String? pendingDeepLink;
  @override
  void initState() {
    super.initState();
    loadTheme();
    setupLifecycleCallbacks();
    setupDeepLinkListener();
  }

  Future<void> loadTheme() async {
    final isDark = await Storage.isDarkMode();
    setState(() {
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme() async {
    final isDark = themeMode == ThemeMode.dark;
    await Storage.setDarkMode(!isDark);
    setState(() {
      themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void setupLifecycleCallbacks() {
    widget.lifecycleManager.navigatorKey = navigatorKey;
    widget.lifecycleManager.onAppResumed = handleAppResumed;
  }

  void setupDeepLinkListener() {
    final appLinks = AppLinks();

    appLinks
        .getInitialAppLink()
        .then((initialAppLink) {
          if (initialAppLink != null) {
            handleDeepLink(initialAppLink);
          }
        })
        .catchError((err) {});

    appLinks.uriLinkStream.listen((uri) {
      handleDeepLink(uri);
    }, onError: (err) {});
  }

  void handleDeepLink(Uri uri) {
    if (uri.scheme == 'otpauth' && uri.host == 'totp') {
      final otpauthUrl = uri.toString();

      if (RuntimeKey.rawPassword != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AddAccountScreen(initialUrl: otpauthUrl),
          ),
        );
      } else {
        pendingDeepLink = otpauthUrl;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/startup',
          (route) => false,
        );
      }
    }
  }

  void handleAppResumed() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/startup',
      (route) => false,
    );
  }

  @override
  void dispose() {
    widget.lifecycleManager.dispose();
    super.dispose();
  }

  String? takePendingDeepLink() {
    final link = pendingDeepLink;
    pendingDeepLink = null;
    return link;
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E88E5);
    const accentOrange = Color(0xFFFF7043);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      routes: {
        '/startup': (context) => StartupScreen(onToggleTheme: toggleTheme),
      },
      theme: ThemeData.light().copyWith(
        primaryColor: primaryBlue,
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: accentOrange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: primaryBlue,
        colorScheme: const ColorScheme.dark(
          primary: primaryBlue,
          secondary: accentOrange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: themeMode,
      home: StartupScreen(onToggleTheme: toggleTheme),
    );
  }
}
