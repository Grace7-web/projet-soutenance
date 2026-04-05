import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/auth_pages.dart';
import '../../home/screens/product_detail_page.dart';

import '../../admin/screens/admin_dashboard.dart';
import '../../home/screens/archives_page.dart';

class AccountPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const AccountPage({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _api.getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_role');

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            toggleTheme: widget.toggleTheme,
            themeMode: widget.themeMode,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?['role'] == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildHeader(context),
                if (isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings,
                        color: Colors.teal),
                    title: const Text('Panneau Administrateur',
                        style: TextStyle(
                            color: Colors.teal, fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminDashboard())),
                  ),
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text('Mes annonces'),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyAdsPage())),
                ),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Mes produits vendus'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ArchivesPage(isUserOnly: true))),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Mes favoris'),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage())),
                ),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Apparence'),
                  trailing: Switch(
                    value: widget.themeMode == ThemeMode.dark,
                    onChanged: (_) => widget.toggleTheme(),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Déconnexion',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final userName = _user?['username'] ?? AuthService.userName;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
              radius: 30,
              child: Text(userName.isEmpty ? 'U' : userName[0].toUpperCase())),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName.isEmpty ? 'Utilisateur' : userName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (_user?['role'] != null)
                Text(_user!['role'] == 'admin' ? 'Administrateur' : 'Vendeur',
                    style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class MyAdsPage extends StatefulWidget {
  const MyAdsPage({super.key});
  @override
  State<MyAdsPage> createState() => _MyAdsPageState();
}

class _MyAdsPageState extends State<MyAdsPage> {
  final ApiService _api = ApiService();
  List _ads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ads = await _api.getUserListings();
      setState(() {
        _ads = ads;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes annonces')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _ads.length,
              itemBuilder: (context, i) {
                final ad = _ads[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ad['photoUrl'] ?? 'https://via.placeholder.com/150',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image, size: 40),
                      ),
                    ),
                    title: Text(ad['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${ad['price']} FCFA'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductDetailPage(ad: ad)),
                      );
                      if (result == true) _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ApiService _api = ApiService();
  List _favs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final f = await _api.getUserFavorites();
      setState(() {
        _favs = f;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _favs.length,
              itemBuilder: (context, i) {
                final ad = _favs[i];
                final photoUrl = ad['image'] ??
                    ad['photoUrl'] ??
                    'https://via.placeholder.com/150';
                final price = ad['price'] ?? '0 FCFA';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image, size: 40),
                      ),
                    ),
                    title: Text(ad['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(price.toString().contains('FCFA')
                        ? price.toString()
                        : '$price FCFA'),
                    trailing: const Icon(Icons.favorite, color: Colors.red),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductDetailPage(ad: ad)),
                      );
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}
