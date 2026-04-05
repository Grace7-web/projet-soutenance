import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../features/auth/screens/auth_pages.dart';
import '../../features/home/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;
  const SplashScreen(
      {super.key, required this.toggleTheme, required this.themeMode});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AuthService().initAuthState();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthService.isLoggedIn
            ? MainScreen(
                toggleTheme: widget.toggleTheme, themeMode: widget.themeMode)
            : LoginPage(
                toggleTheme: widget.toggleTheme, themeMode: widget.themeMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
      child: Text(
        AppStrings.appName,
        style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary),
      ),
    ));
  }
}
