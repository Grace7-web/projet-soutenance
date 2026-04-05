import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'core/widgets/splash_screen.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.init();
  } catch (_) {}
  runApp(const LeBoncoinApp());
}

class LeBoncoinApp extends StatefulWidget {
  const LeBoncoinApp({super.key});
  @override
  State<LeBoncoinApp> createState() => _LeBoncoinAppState();
}

class _LeBoncoinAppState extends State<LeBoncoinApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void toggleTheme() => setState(() => _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffoldLight,
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.scaffoldDark,
      ),
      home: SplashScreen(toggleTheme: toggleTheme, themeMode: _themeMode),
    );
  }
}
