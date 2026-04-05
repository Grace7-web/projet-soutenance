import 'package:flutter/material.dart';
import '../../home/screens/home_page.dart';
import '../../messages/screens/messages_page.dart';
import '../../publish/screens/publish_page.dart';
import '../../profile/screens/profile_pages.dart';
import '../../../core/constants/app_colors.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;
  const MainScreen(
      {super.key, required this.toggleTheme, required this.themeMode});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const MessagesPage(),
      const PublishPage(),
      const FavoritesPage(),
      AccountPage(toggleTheme: widget.toggleTheme, themeMode: widget.themeMode),
    ];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Rechercher'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Publier'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Favoris'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Compte'),
        ],
      ),
    );
  }
}
