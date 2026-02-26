import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/payment_service.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  runApp(const LeBoncoinApp());
}

// ====================================================================
// CLASSE PRINCIPALE AVEC THÈME GLOBAL
// ====================================================================

class LeBoncoinApp extends StatefulWidget {
  const LeBoncoinApp({Key? key}) : super(key: key);

  @override
  State<LeBoncoinApp> createState() => _LeBoncoinAppState();
}

class _LeBoncoinAppState extends State<LeBoncoinApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'marketmboa',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF00897B),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF00897B),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF00897B),
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00897B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF4DB6AC),
          unselectedItemColor: Colors.grey,
        ),
        cardColor: const Color(0xFF1E1E1E),
        dialogBackgroundColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey[700],
      ),
      home: SplashScreen(
        toggleTheme: toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

// ====================================================================
// SPLASH SCREEN
// ====================================================================

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const SplashScreen({
    Key? key,
    required this.toggleTheme,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // ✅ MODIFICATION: Vérifier le token et naviguer en conséquence
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        final apiService = ApiService();
        final token = await apiService.getToken();

        Widget nextScreen;
        if (token != null && token.isNotEmpty) {
          // ✅ Utilisateur connecté → Aller à l'accueil
          nextScreen = MainScreen(
            toggleTheme: widget.toggleTheme,
            themeMode: widget.themeMode,
          );
        } else {
          // ✅ Utilisateur non connecté → Aller à la connexion
          nextScreen = LoginPage(
            toggleTheme: widget.toggleTheme,
            themeMode: widget.themeMode,
          );
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00897B),
              const Color(0xFF4DB6AC),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 70,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'marketmboa',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cameroun',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({Key? key, required this.child}) : super(key: key);
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const EmailPage();
        }
        return widget.child;
      },
    );
  }
}

class EmailPage extends StatefulWidget {
  const EmailPage({Key? key}) : super(key: key);
  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final _emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votre email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final email = _emailController.text.trim();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PasswordPage(email: email)),
                );
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordPage extends StatefulWidget {
  final String email;
  const PasswordPage({Key? key, required this.email}) : super(key: key);
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.email),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      try {
                        try {
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: widget.email,
                            password: _passwordController.text,
                          );
                        } catch (e) {
                          final msg = '$e';
                          if (msg.contains('user-not-found')) {
                            final cred = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: widget.email,
                              password: _passwordController.text,
                            );
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(cred.user!.uid)
                                .set({
                              'email': widget.email,
                              'createdAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                          } else {
                            rethrow;
                          }
                        }
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() {
                          _error = '$e';
                        });
                      } finally {
                        setState(() {
                          _loading = false;
                        });
                      }
                    },
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Se connecter / Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ÉCRAN PRINCIPAL
// ====================================================================

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const MainScreen({
    Key? key,
    required this.toggleTheme,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (!AuthState.isLoggedIn && index != 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            toggleTheme: widget.toggleTheme,
            themeMode: widget.themeMode,
          ),
        ),
      ).then((_) => setState(() {}));
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _pages => [
        const HomePage(),
        const MessagesPage(),
        const PublishPage(),
        const FavoritesPage(),
        AccountPage(
          toggleTheme: widget.toggleTheme,
          themeMode: widget.themeMode,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Rechercher',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}

// Classe pour gérer l'état de connexion
class AuthState {
  static bool _isLoggedIn = false;
  static String _userName = '';

  static bool get isLoggedIn => _isLoggedIn;
  static String get userName => _userName;

  static void login(String name) {
    _isLoggedIn = true;
    _userName = name;
  }

  static void logout() {
    _isLoggedIn = false;
    _userName = '';
  }
}

// ====================================================================
// PAGE 1: ACCUEIL - RECHERCHER (VERSION CONNECTÉE AU BACKEND)
// ====================================================================

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService(); // ← AJOUTEZ CECI
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allAds = [];
  List<Map<String, dynamic>> _filteredAds = [];
  bool _isLoading = true; // ← AJOUTEZ CECI

  // ✅ NOUVEAUX: Pour gérer les favoris
  List<int> _favoriteIds = [];
  bool _loadingFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadAds(); // ← Cette fonction va changer
    _loadFavoriteIds(); // ← CHARGER LES FAVORIS
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ NOUVELLE FONCTION: Charger les IDs des favoris
  Future<void> _loadFavoriteIds() async {
    try {
      final ids = await _api.getFavoriteIds();
      setState(() {
        _favoriteIds = ids;
      });
    } catch (e) {
      print('Erreur chargement favoris: $e');
    }
  }

  // ✅ NOUVELLE FONCTION: Toggle favoris
  Future<void> _toggleFavorite(int listingId) async {
    if (_loadingFavorites) return;

    setState(() {
      _loadingFavorites = true;
    });

    try {
      if (_favoriteIds.contains(listingId)) {
        // Retirer des favoris
        await _api.removeFavorite(listingId);
        setState(() {
          _favoriteIds.remove(listingId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiré des favoris'),
            backgroundColor: Colors.grey,
            duration: Duration(milliseconds: 800),
          ),
        );
      } else {
        // Ajouter aux favoris
        await _api.addFavorite(listingId);
        setState(() {
          _favoriteIds.add(listingId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajouté aux favoris'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      print('Erreur toggle favoris: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loadingFavorites = false;
      });
    }
  }

  // ====================================================================
  // ⚠️ FONCTION MODIFIÉE - CHARGE LES ANNONCES DEPUIS LE BACKEND
  // ====================================================================
  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ← APPEL API POUR RÉCUPÉRER LES ANNONCES
      final listings = await _api.getAllListings();

      setState(() {
        _allAds = listings.map((listing) {
          // Utiliser photoUrl si disponible, sinon chercher dans photos
          var photoUrl =
              listing['photoUrl'] ?? 'https://via.placeholder.com/400';

          if (photoUrl == 'https://via.placeholder.com/400' &&
              listing['photos'] != null &&
              listing['photos'].isNotEmpty) {
            final firstPhoto = listing['photos'][0];
            if (firstPhoto is Map && firstPhoto.containsKey('url')) {
              photoUrl = firstPhoto['url'];
            }
          }

          // Construire l'URL complète si c'est un chemin relatif
          if (photoUrl.startsWith('/uploads/')) {
            photoUrl = 'http://192.168.43.76:3000$photoUrl';
          }

          return {
            'id': listing['id'],
            'title': listing['title'] ?? 'Sans titre',
            'price': '${listing['price'] ?? 0} FCFA',
            'image': photoUrl,
            'category': listing['category'] ?? 'général',
            'location': 'Yaoundé',
            'description': listing['description'] ?? '',
            'photos': listing['photos'] ?? [],
            'photoUrl': listing['photoUrl'] ?? photoUrl,
          };
        }).toList();

        _filteredAds = List.from(_allAds);
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur de chargement: $e');

      setState(() {
        _isLoading = false;
      });

      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger les annonces: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadAds,
            ),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredAds = List.from(_allAds);
      } else {
        _filteredAds = _allAds.where((ad) {
          final title = ad['title'].toString().toLowerCase();
          final category = ad['category'].toString().toLowerCase();
          final location = ad['location'].toString().toLowerCase();

          return title.contains(query) ||
              category.contains(query) ||
              location.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String _img(String url, {int w = 600}) {
      if (url.contains('/upload/')) {
        return url.replaceFirst('/upload/', '/upload/f_auto,q_auto,w_$w/');
      }
      return url;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            // ← AJOUT DU LOADER
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00897B),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAds, // ← Pull to refresh
                  color: const Color(0xFF00897B),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        _buildCategories(context),
                        const SizedBox(height: 25),
                        _buildPromoBanner(),
                        const SizedBox(height: 25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Annonces récentes',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                Text(
                                  '${_filteredAds.length} résultat(s)',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Chip(
                            avatar: const Icon(Icons.location_on,
                                size: 18, color: Color(0xFF00897B)),
                            label: const Text('Tout le Cameroun'),
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _filteredAds.isEmpty
                            ? _buildNoResults()
                            : _buildAdsGrid(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Color(0xFF00897B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'marketmboa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher sur marketmboa',
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.grey, size: 20),
                  ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCategoryIcon(context, Icons.home_outlined, 'Immobilier'),
          _buildCategoryIcon(
              context, Icons.directions_car_outlined, 'Véhicules'),
          _buildCategoryIcon(context, Icons.beach_access_outlined, 'Vacances'),
          _buildCategoryIcon(context, Icons.more_horiz, 'Autres'),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00897B), size: 28),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 20,
            bottom: 20,
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: NetworkImage(
                      'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=400'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, color: Color(0xFFFF6B35), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'marketmboa',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Découvrez nos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
                const Text(
                  'actus Immo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredAds.length,
        itemBuilder: (context, index) {
          final ad = _filteredAds[index];
          // ✅ PASS ID POUR LES FAVORIS
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(ad: ad),
                ),
              );
            },
            child: _buildAdCard(
              ad['id'],
              ad['title'],
              ad['price'],
              ad['image'],
              ad['location'],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdCard(
      int id, String title, String price, String imageUrl, String location) {
    // ✅ VÉRIFIER SI C'EST UN FAVORI
    final isFavorite = _favoriteIds.contains(id);
    final displayUrl = imageUrl.startsWith('http')
        ? (imageUrl.contains('/upload/')
            ? imageUrl.replaceFirst('/upload/', '/upload/f_auto,q_auto,w_600/')
            : imageUrl)
        : imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  displayUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback: réessayer sans transformation si possible
                    if (displayUrl != imageUrl && imageUrl.startsWith('http')) {
                      return Image.network(
                        imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) {
                          return Container(
                            height: 140,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return Container(
                      height: 140,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Center(
                          child: Icon(Icons.image,
                              size: 50,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3))),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 140,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00897B), strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
              // ✅ CŒUR CLIQUABLE
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.search_off,
                size: 80,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// PAGE 2: MESSAGES
// ====================================================================

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'local';
    final stream = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        var docs = snapshot.data?.docs ?? [];
        // Tri côté client pour éviter les soucis d'index/latence de timestamp serveur
        docs.sort((a, b) {
          final ta = a.data()['lastMessageAt'];
          final tb = b.data()['lastMessageAt'];
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          try {
            return (tb as Timestamp).compareTo(ta as Timestamp);
          } catch (_) {
            return 0;
          }
        });
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: const Text('Messages',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: snapshot.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Erreur de chargement des messages',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                )
              : docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline,
                              size: 100,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune conversation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final c = {'id': doc.id, ...doc.data()};
                        final title = (c['sellerName'] as String?)?.trim();
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.chat)),
                          title: Text(title == null || title.isEmpty
                              ? 'Conversation'
                              : title),
                          subtitle: Text(
                            (c['lastMessageText'] as String?) ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ConversationPage(conversation: c),
                              ),
                            );
                          },
                        );
                      },
                    ),
        );
      },
    );
  }
}

// ====================================================================
// PAGE 3: PUBLIER (AVEC PHOTOS)
// ====================================================================

class PublishPage extends StatefulWidget {
  const PublishPage({Key? key}) : super(key: key);

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final ApiService _api = ApiService();

  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Contrôleurs
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();

  // États
  bool _isDonation = false;
  String? _selectedColor;
  String? _selectedCondition;

  // Gestion des photos
  Map<String, File?> _categoryImages = {
    'Vue de face': null,
    'Vue arrière': null,
    'Vue de côté': null,
    'Vue détaillée': null,
    'Emballage': null,
  };

  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  bool _isAllowedFormat(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  bool _isAllowedSize(String path, {int maxBytes = 10 * 1024 * 1024}) {
    try {
      final f = File(path);
      return f.existsSync() ? f.lengthSync() <= maxBytes : false;
    } catch (_) {
      return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 5) {
      // Étape 6 (Coordonnées) : appeler l'API
      _submitAd();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitAd() async {
    // Vérifier les champs obligatoires
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un titre'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isDonation && _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un prix'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convertir les images en File
      List<File> photoFiles = [];
      for (var category in _categoryImages.values) {
        if (category != null) {
          photoFiles.add(category);
        }
      }

      // Vérifier qu'il y a au moins 2 photos
      if (photoFiles.length < 2) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Veuillez ajouter au moins les photos de face et arrière'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('📤 Envoi de l\'annonce...');
      print('Titre: ${_titleController.text}');
      print('Photos: ${photoFiles.length}');

      final result = await _api.createListing(
        title: _titleController.text,
        description: _descriptionController.text,
        price: _isDonation ? 0 : (double.tryParse(_priceController.text) ?? 0),
        color: _selectedColor ?? 'Non spécifié',
        condition: _selectedCondition ?? 'Bon état',
        photos: photoFiles,
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
      );

      print('✅ Réponse reçue: $result');

      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              toggleTheme: () {},
              themeMode: ThemeMode.light,
            ),
          ),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce publiée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur: $e');

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Fonction pour choisir une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (!mounted) return;
      if (image != null) {
        if (!_isAllowedFormat(image.path)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Format non supporté. Utilise JPG, JPEG, PNG ou WEBP.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (!_isAllowedSize(image.path)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fichier trop lourd (max 10 Mo).'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fonction pour afficher le menu de choix
  void _showImagePickerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Choisir une photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ListTile(
              leading:
                  Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
              title: Text('Prendre une photo',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: Theme.of(context).primaryColor),
              title: Text('Choisir depuis la galerie',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text('Annuler', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Fonction pour supprimer une image
  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Supprimer la photo',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cette photo ?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedImages.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: _previousStep,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close,
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF00897B),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Chargement de la photo...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 7,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1QuickStart(),
                      _buildStep2Photos(), // Étape avec photos
                      _buildStep3Details(),
                      _buildStep4Description(),
                      _buildStep5Price(),
                      _buildStep6Coordinates(),
                      _buildStep7Success(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ====================================================================
  // ÉTAPE 1: COMMENÇONS PAR L'ESSENTIEL
  // ====================================================================
  Widget _buildStep1QuickStart() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commençons par l\'essentiel !',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '*Champs obligatoires',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _titleController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Quel est le titre de votre annonce ? *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style:
                  TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Me renseigner',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const TextSpan(
                  text:
                      ' sur les finalités du traitement de mes données personnelles, les destinataires, le responsable de traitement, les durées de conservation, les coordonnées du DPO et mes droits.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildContinueButton(),
        ],
      ),
    );
  }

  // ====================================================================
  // ÉTAPE 2: AJOUTEZ DES PHOTOS (VERSION SIMPLIFIÉE SANS POINTILLÉS)
  // ====================================================================
  Widget _buildStep2Photos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajoutez des photos',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
            'Ajoutez un maximum de photos pour augmenter le nombre de contacts',
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 30),
          const Text(
            'Vos photos *',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 15),

          // Grille simplifiée
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.85,
            children: [
              _buildMainAddButton(), // Case Blanche "Ajouter 20 photos"
              _buildPhotoSlot('Vue de face', Icons.smartphone, isCover: true),
              _buildPhotoSlot('Vue de côté', Icons.stay_current_portrait),
              _buildPhotoSlot('Vue arrière', Icons.camera_rear),
              _buildPhotoSlot('Vue détaillée', Icons.zoom_in),
              _buildPhotoSlot('Emballage', Icons.inventory_2_outlined),
            ],
          ),

          const SizedBox(height: 40),

          // Bouton Continuer (Activé si Face et Arrière sont remplis)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_categoryImages['Vue de face'] != null &&
                      _categoryImages['Vue arrière'] != null)
                  ? _nextStep
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Case "Ajouter 20 photos" (Style blanc avec ombre légère)
  Widget _buildMainAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo_outlined, size: 35, color: Color(0xFF1A3D63)),
          SizedBox(height: 10),
          Text(
            'Ajouter 20\nphotos',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3D63),
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Cases Photo (Sans pointillés)
  Widget _buildPhotoSlot(String label, IconData icon, {bool isCover = false}) {
    File? image = _categoryImages[label];

    return GestureDetector(
      onTap: () => _pickImageForCategory(label),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCover && image == null
                    ? const Color(0xFF1A3D63)
                    : Colors.grey.shade300,
                width: isCover && image == null ? 2 : 1,
              ),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 30, color: const Color(0xFF1A3D63)),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                            color: Color(0xFF1A3D63),
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
          ),
          if (isCover)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A3D63),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: const Text(
                  'Photo de couverture',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (image != null)
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _categoryImages[label] = null;
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Fonction de sélection d'image mise à jour pour la Map
  Future<void> _pickImageForCategory(String category) async {
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF6B35)),
              title: const Text("Prendre une photo"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.camera);
                if (!mounted) return;
                if (pickedFile != null) {
                  if (!_isAllowedFormat(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Format non supporté. Utilise JPG, JPEG, PNG ou WEBP.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (!_isAllowedSize(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fichier trop lourd (max 10 Mo).'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _categoryImages[category] = File(pickedFile.path);
                  });
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFFF6B35)),
              title: const Text("Choisir depuis la galerie"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);
                if (!mounted) return;
                if (pickedFile != null) {
                  if (!_isAllowedFormat(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Format non supporté. Utilise JPG, JPEG, PNG ou WEBP.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (!_isAllowedSize(pickedFile.path)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fichier trop lourd (max 10 Mo).'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _categoryImages[category] = File(pickedFile.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // ÉTAPE 3: DITES-NOUS EN PLUS (Détails)
  // ====================================================================
  Widget _buildStep3Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dites-nous en plus',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mettez en valeur votre annonce !\nPlus il y a de détails, plus vos futurs contacts vous trouveront rapidement.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'Couleur',
            value: _selectedColor,
            hint: 'Choisissez',
            onChanged: (value) => setState(() => _selectedColor = value),
            items: ['Noir', 'Blanc', 'Bleu', 'Rouge', 'Vert', 'Rose', 'Gris'],
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            label: 'État *',
            value: _selectedCondition,
            hint: 'Choisissez',
            onChanged: (value) => setState(() => _selectedCondition = value),
            items: [
              'Neuf',
              'Très bon état',
              'Bon état',
              'État satisfaisant',
              'À réparer'
            ],
          ),
          const SizedBox(height: 40),
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).hintColor,
            )),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
          dropdownColor: Theme.of(context).cardColor,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ====================================================================
  // ÉTAPE 4: DÉCRIVEZ VOTRE BIEN
  // ====================================================================
  Widget _buildStep4Description() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Décrivez votre bien !',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Mettez en valeur votre bien ! Plus il y a de détails, plus votre annonce sera de qualité. Détaillez ici ce qui a de l\'importance et ajoutera de la valeur.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _titleController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Titre de l\'annonce *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              hintText: 'Ex: Samsung Galaxy A54',
              hintStyle: TextStyle(color: Theme.of(context).hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vous n\'avez pas besoin de mentionner « Achat » ou « Vente » ici.',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Me proposer une description'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descriptionController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            maxLines: 6,
            maxLength: 4000,
            decoration: InputDecoration(
              labelText: 'Description de l\'annonce *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              hintText: 'Décrivez votre article en détail...',
              hintStyle: TextStyle(color: Theme.of(context).hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nous vous rappelons que la vente de contrefaçons est interdite. Nous vous invitons à ajouter tout élément permettant de prouver l\'authenticité de votre article: numéro de série, facture, certificat, inscription de la marque sur l\'article, emballage etc.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Indiquez dans le texte de l\'annonce si vous proposez un droit de rétractation à l\'acheteur. En l\'absence de toute mention, l\'acheteur n\'en bénéficiera pas et ne pourra pas demander le remboursement ou l\'échange du bien ou service proposé',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildContinueButton(),
        ],
      ),
    );
  }

  // ====================================================================
  // ÉTAPE 5: QUEL EST VOTRE PRIX
  // ====================================================================
  Widget _buildStep5Price() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quel est votre prix ?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vous le savez, le prix est important. Soyez juste, mais ayez en tête une marge de négociation si besoin.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Je fais un don',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
              Switch(
                value: _isDonation,
                onChanged: (value) => setState(() => _isDonation = value),
                activeColor: const Color(0xFF00897B),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isDonation) ...[
            TextField(
              controller: _priceController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Votre prix de vente *',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
                suffixText: 'FCFA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text(
                  'Prix recommandé entre 2000 FCFA et 10000 FCFA',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.help_outline,
                    size: 18, color: Theme.of(context).hintColor),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard,
                      color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Article offert gratuitement',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          _buildContinueButton(),
        ],
      ),
    );
  }

  // ====================================================================
  // ÉTAPE 6: VOS COORDONNÉES
  // ====================================================================
  Widget _buildStep6Coordinates() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos coordonnées',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pour faciliter vos échanges avec vos futurs contacts, renseignez votre nom et prénom. Ils n\'apparaîtront pas sur l\'annonce.',
            style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _lastNameController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Nom *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _firstNameController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Prénom *',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 15),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
              ),
              children: [
                const TextSpan(
                  text:
                      'Vos nom et prénom n\'apparaîtront pas sur votre annonce. ',
                ),
                TextSpan(
                  text: 'Pourquoi est-ce important ?',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildContinueButton(label: 'Publier mon annonce'),
        ],
      ),
    );
  }

  // ====================================================================
  // ÉTAPE 7: PAGE DE SUCCÈS
  // ====================================================================
  Widget _buildStep7Success() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 20,
                  child: Icon(Icons.star, color: Colors.yellow[700], size: 30),
                ),
                Positioned(
                  top: 10,
                  left: 80,
                  child: Icon(Icons.star, color: Colors.yellow[600], size: 20),
                ),
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: Icon(Icons.star, color: Colors.yellow[700], size: 25),
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00897B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 60),
                      ),
                      const SizedBox(height: 15),
                      Icon(Icons.person,
                          color: Theme.of(context).primaryColor, size: 50),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Nous avons bien reçu votre annonce !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Une fois contrôlée et validée, vous recevrez une notification et pourrez la retrouver dans la section « Annonces » de votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                height: 1.5,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Bouton "Déposer une nouvelle annonce"
                onPressed: () {
                  // Réinitialiser le formulaire
                  setState(() {
                    _currentStep = 0;
                    _titleController.clear();
                    _descriptionController.clear();
                    _priceController.clear();
                    _lastNameController.clear();
                    _firstNameController.clear();
                    _isDonation = false;
                    _selectedColor = null;
                    _selectedCondition = null;
                    _categoryImages = {
                      'Vue de face': null,
                      'Vue arrière': null,
                      'Vue de côté': null,
                      'Vue détaillée': null,
                      'Emballage': null,
                    };
                  });
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Déposer une nouvelle annonce',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                // Bouton "Voir mes annonces"
                onPressed: () {
                  // Retourner à l'accueil (index 0)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Voir mes annonces',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton({String label = 'Continuer'}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }
}

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> ad;
  const ProductDetailPage({Key? key, required this.ad}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _api = ApiService();
  final PaymentService _payments = PaymentService();
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  Map<String, dynamic>? _seller;

  List<String> get _photos {
    final raw = widget.ad['photos'];
    if (raw is List && raw.isNotEmpty) {
      if (raw.first is Map && (raw.first as Map).containsKey('url')) {
        return raw.map((e) => (e as Map)['url'].toString()).toList();
      }
      if (raw.first is String) {
        return raw.cast<String>();
      }
    }
    final cover = widget.ad['image'] ?? widget.ad['photoUrl'];
    if (cover is String) return [cover];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _initFavorite();
    _loadSeller();
  }

  Future<void> _initFavorite() async {
    final ids = await _api.getFavoriteIds();
    setState(() {
      _isFavorite = ids.contains(widget.ad['id']);
    });
  }

  Future<void> _loadSeller() async {
    final sellerId = widget.ad['sellerUserId'] is int
        ? widget.ad['sellerUserId'] as int
        : null;
    Map<String, dynamic> seller;
    if (sellerId != null) {
      seller = await _api.getUserById(sellerId);
    } else {
      seller = await _api.getCurrentUser();
    }
    setState(() {
      _seller = seller;
    });
  }

  void _toggleFavorite() async {
    final id = widget.ad['id'] as int;
    if (_isFavorite) {
      await _api.removeFavorite(id);
    } else {
      await _api.addFavorite(id);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _openInbox() async {
    final sellerId = widget.ad['sellerUserId'] is int
        ? widget.ad['sellerUserId'] as int
        : (_seller != null ? _seller!['id'] as int : 1);
    final conv = await _api.getOrCreateConversation(
      sellerUserId: sellerId,
      listingId: widget.ad['id'] as int,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(conversation: conv),
      ),
    );
  }

  void _contactSellerLegacy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contacter le vendeur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _seller != null &&
                          (_seller!['phone'] as String?) != null &&
                          (_seller!['phone'] as String).isNotEmpty
                      ? 'Téléphone: ${_seller!['phone']}'
                      : 'Téléphone non renseigné',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonction d’appel à venir'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                        ),
                        child: const Text('Appeler'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pay(String provider, double amount) async {
    final controller = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Entrer le numéro mobile'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Ex: 6XXXXXXXX'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dCtx).pop(controller.text.trim()),
              child: const Text('Valider'),
            )
          ],
        );
      },
    );
    if (phone == null || phone.isEmpty) return;
    final ref =
        'ad_${widget.ad['id']}_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await _payments.startCinetPayPayment(
        phone: phone,
        amount: amount,
        currency: 'XAF',
        reference: ref,
        channel: provider,
      );
      if (!mounted) return;
      final url = res['paymentUrl']?.toString();
      if (url != null && url.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(initialUrl: url, reference: ref),
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']?.toString() ?? 'Paiement initié')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur paiement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openPaymentSheet() async {
    final amount = (widget.ad['price'] is num)
        ? (widget.ad['price'] as num).toDouble()
        : double.tryParse(widget.ad['price']?.toString() ?? '') ?? 0.0;
    Future<void> _launchUSSD(String encoded) async {
      final uri = Uri.parse('tel:$encoded');
      await launchUrl(uri);
    }

    Future<void> _confirmUssdPayment(String provider) async {
      final ref =
          'ussd_${widget.ad['id']}_${DateTime.now().millisecondsSinceEpoch}';
      final res = await _api.createManualOrder(
        listingId: widget.ad['id'] as int,
        amount: amount,
        provider: provider,
        reference: ref,
        sellerPhone: _seller?['phone'] as String?,
      );
      if (!mounted) return;
      if (res['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${res['error']}'),
          backgroundColor: Colors.red,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Commande enregistrée. Paiement à confirmer.'),
          backgroundColor: Colors.green,
        ));
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisir le moyen de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Montant: ${amount.toStringAsFixed(0)} FCFA',
                style: TextStyle(color: Theme.of(ctx).hintColor),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _pay('orange', amount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7900), // Orange brand
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.white),
                            SizedBox(height: 6),
                            Text('Orange Money',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _pay('mtn', amount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDD00), // MTN brand yellow
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.black),
                            SizedBox(height: 6),
                            Text('MTN Mobile Money',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mode soutenance (USSD sur votre téléphone)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Orange Money CM USSD: #150#
                        await _launchUSSD('%23150%23');
                      },
                      icon: const Icon(Icons.phone_in_talk),
                      label: const Text('USSD Orange'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // MTN MoMo CM USSD: *126#
                        await _launchUSSD('*126%23');
                      },
                      icon: const Icon(Icons.phone_in_talk),
                      label: const Text('USSD MTN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _confirmUssdPayment('orange_ussd'),
                    child: const Text('J’ai payé (OM)'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => _confirmUssdPayment('mtn_ussd'),
                    child: const Text('J’ai payé (MTN)'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.ad['title']?.toString() ?? 'Sans titre';
    final priceText = widget.ad['price']?.toString() ?? '';
    final priceDisplay =
        priceText.contains('FCFA') ? priceText : '${priceText} FCFA';
    final description = widget.ad['description']?.toString() ?? '';
    final category = widget.ad['category']?.toString() ?? 'général';
    final condition = widget.ad['condition']?.toString() ?? 'Bon état';
    final color = widget.ad['color']?.toString() ?? 'Non spécifié';
    final location = widget.ad['location']?.toString() ?? 'Cameroun';
    final sellerFirst = widget.ad['sellerFirstName']?.toString() ?? '';
    final sellerLast = widget.ad['sellerLastName']?.toString() ?? '';
    String sellerName = (sellerFirst + ' ' + sellerLast).trim().isEmpty
        ? 'Utilisateur'
        : (sellerFirst + ' ' + sellerLast).trim();
    if (_seller != null) {
      final sFirst = (_seller!['firstName'] as String?) ?? '';
      final sLast = (_seller!['lastName'] as String?) ?? '';
      final sUser = (_seller!['username'] as String?) ?? '';
      final computed = (sFirst + ' ' + sLast).trim();
      sellerName = computed.isNotEmpty ? computed : sUser;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share,
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage à venir')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite
                  ? Colors.red
                  : Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _photos.length,
                  onPageChanged: (i) => setState(() {
                    _currentImageIndex = i;
                  }),
                  itemBuilder: (context, index) {
                    final src = _photos[index];
                    String url = src;
                    if (src.contains('/upload/')) {
                      url = src.replaceFirst(
                          '/upload/', '/upload/f_auto,q_auto,w_1000/');
                    }
                    if (url.startsWith('http')) {
                      return Image.network(url, fit: BoxFit.cover);
                    } else {
                      return Image.file(File(src), fit: BoxFit.cover);
                    }
                  },
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${_photos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          priceDisplay,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.verified_user,
                            size: 18,
                            color:
                                Theme.of(context).hintColor.withOpacity(0.9)),
                        const SizedBox(width: 6),
                        Text(
                          'Transaction sécurisée',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.location_on,
                              size: 18, color: Color(0xFF00897B)),
                          label: Text(location),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Informations clés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.category, 'Catégorie', category),
                    _infoRow(Icons.color_lens, 'Couleur', color),
                    _infoRow(Icons.verified, 'État', condition),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.isEmpty ? 'Aucune description' : description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            sellerName.isEmpty
                                ? 'U'
                                : sellerName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(sellerName),
                        subtitle: Text(
                          _seller != null &&
                                  (_seller!['phone'] as String?) != null &&
                                  (_seller!['phone'] as String).isNotEmpty
                              ? 'Téléphone: ${_seller!['phone']}'
                              : 'Téléphone non renseigné',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _openInbox,
                child: const Text('Inbox'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _openPaymentSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Acheter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).hintColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationPage extends StatefulWidget {
  final Map<String, dynamic> conversation;
  const ConversationPage({Key? key, required this.conversation})
      : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // StreamBuilder gère le rafraîchissement en temps réel
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _api.sendMessage(widget.conversation['id'].toString(), text);
    _controller.clear();
  }

  Future<void> _callSeller() async {
    final phone = widget.conversation['sellerPhone'] as String?;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversation['id'].toString())
        .collection('messages')
        .orderBy('at')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation #${widget.conversation['id']}'),
        actions: [
          if ((widget.conversation['sellerPhone'] as String?) != null)
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: _callSeller,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data();
                    final myUid = FirebaseAuth.instance.currentUser?.uid;
                    final isMine = m['senderUid'] == myUid;
                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMine
                              ? const Color(0xFF00897B)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            color: isMine ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Votre message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                    ),
                    child: const Text('Envoyer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentWebView extends StatefulWidget {
  final String initialUrl;
  final String reference;
  const PaymentWebView(
      {Key? key, required this.initialUrl, required this.reference})
      : super(key: key);
  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  final PaymentService _payments = PaymentService();
  late final WebViewController _controller;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.initialUrl));
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_done) return;
    try {
      final res = await _payments.getPaymentStatus(widget.reference);
      final s = (res['status'] ?? '').toString().toLowerCase();
      if (s.isEmpty) return;
      if (s.contains('success') ||
          s.contains('complete') ||
          s.contains('paid')) {
        _done = true;
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement réussi')),
        );
      } else if (s.contains('fail') ||
          s.contains('cancel') ||
          s.contains('refus')) {
        _done = true;
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement non abouti')),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class PublishSuccessDialog extends StatelessWidget {
  const PublishSuccessDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle,
              color: Theme.of(context).primaryColor, size: 80),
          const SizedBox(height: 20),
          Text(
            'Annonce publiée !',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// PAGE 4: FAVORIS
// ====================================================================

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // ✅ CHARGER LES FAVORIS DEPUIS LE BACKEND
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _api.getUserFavorites();
      setState(() {
        _favorites = List<Map<String, dynamic>>.from(favorites);
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement favoris: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadFavorites,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text('Favoris',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00897B),
              ),
            )
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 100,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3)),
                      const SizedBox(height: 20),
                      Text(
                        'Aucun favori',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ajoutez des annonces à vos favoris\npour les retrouver facilement',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  color: const Color(0xFF00897B),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final fav = _favorites[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              fav['image'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                );
                              },
                            ),
                          ),
                          title: Text(fav['title'] ?? ''),
                          subtitle: Text(fav['price'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                await _api.removeFavorite(fav['id']);
                                setState(() {
                                  _favorites.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Retiré des favoris'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
// ====================================================================
// PAGE 5: CONNEXION
// ====================================================================

class LoginPage extends StatefulWidget {
  final VoidCallback toggleTheme;

  final ThemeMode themeMode;

  const LoginPage({
    Key? key,
    required this.toggleTheme,
    required this.themeMode,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiService _api = ApiService(); // ← AJOUTÉ

  final TextEditingController _emailController =
      TextEditingController(); // ← AJOUTÉ

  int? userId; // ← AJOUTÉ

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: widget.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: const Color(0xFF00897B),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF00897B),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00897B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 180,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB3E5FC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.smartphone,
                                  size: 50, color: Color(0xFF0277BD)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          left: 200,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1BEE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          left: 0,
                          right: 200,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9C4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.weekend,
                                  size: 80, color: Color(0xFFF57F17)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 90,
                          right: 0,
                          left: 200,
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCCBC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.toys,
                                  size: 60, color: Color(0xFFE64A19)),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 200,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8BBD0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.directions_car,
                                  size: 60, color: Color(0xFFC2185B)),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          left: 200,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB2DFDB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(Icons.work_outline,
                                  size: 50, color: Color(0xFF00695C)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Connectez-vous ou créez\nvotre compte marketmboa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _emailController,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'E-mail *',
                      labelStyle: TextStyle(color: Theme.of(context).hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () async {
                      // Vérifier que l'email n'est pas vide
                      if (_emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez entrer votre email'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        final result =
                            await _api.register(_emailController.text.trim());

                        // Vérifier que userId existe dans la réponse
                        if (result['userId'] == null) {
                          throw Exception('Erreur serveur: userId manquant');
                        }

                        setState(() {
                          userId = result['userId'];
                        });

                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmailVerification(
                              userId: userId!,
                              email: _emailController.text.trim(),
                            ),
                          ),
                        );
                      } catch (e) {
                        print('Erreur complète: $e');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFAB91),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Ou',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// ÉTAPE 1: VÉRIFICATION DE L'EMAIL (CODE À 4 CHIFFRES)
// ====================================================================

class EmailVerification extends StatefulWidget {
  final int userId;
  final String email;

  const EmailVerification({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Message simple de confirmation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code envoyé à ${widget.email}'),
            backgroundColor: const Color(0xFF00897B),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).hintColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: 0.2,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
            const SizedBox(height: 30),
            Text(
              'Entrez votre mot de passe',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Saisissez votre mot de passe pour continuer. Si votre compte n’existe pas, il sera créé automatiquement.',
              style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00897B), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(height: 10),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAB91),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {},
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12),
                  children: [
                    TextSpan(
                      text: 'Me renseigner',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' sur les finalités du traitement de mes données personnelles, les destinataires, le responsable de traitement, les durées de conservation, les coordonnées du DPO et mes droits.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    final pwd = _passwordController.text.trim();
    if (pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre mot de passe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: widget.email.trim(),
          password: pwd,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          final cred =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: widget.email.trim(),
            password: pwd,
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
            'email': widget.email.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else if (e.code == 'invalid-email') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email invalide'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } else if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe incorrect'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } else if (e.code == 'operation-not-allowed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activez “Email/mot de passe” dans Firebase Auth'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } else if (e.code == 'invalid-credential') {
          try {
            final cred =
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: widget.email.trim(),
              password: pwd,
            );
            await FirebaseFirestore.instance
                .collection('users')
                .doc(cred.user!.uid)
                .set({
              'email': widget.email.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } on FirebaseAuthException catch (ce) {
            if (ce.code == 'email-already-in-use') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mot de passe incorrect'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneNumberEntry(userId: widget.userId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}

// ====================================================================
// ÉTAPE 2: ENTRÉE DU NUMÉRO DE TÉLÉPHONE
// ====================================================================

class PhoneNumberEntry extends StatefulWidget {
  final int userId;

  const PhoneNumberEntry({Key? key, required this.userId}) : super(key: key);

  @override
  State<PhoneNumberEntry> createState() => _PhoneNumberEntryState();
}

class _PhoneNumberEntryState extends State<PhoneNumberEntry> {
  final ApiService _api = ApiService();

  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).hintColor),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: 0.4,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
            const SizedBox(height: 30),
            Text(
              'Votre numéro de téléphone',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Entrez votre numéro de téléphone camerounais.\nIl sera utilisé pour sécuriser votre compte.',
              style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        const Text('🇨🇲', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          '(+237)',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                      keyboardType: TextInputType.phone,
                      maxLength: 9,
                      decoration: InputDecoration(
                        hintText: 'Numéro de téléphone',
                        hintStyle:
                            TextStyle(color: Theme.of(context).hintColor),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 15),
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).dialogBackgroundColor,
                    title: Text(
                      'En savoir plus',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    content: Text(
                      'Votre numéro de téléphone sera utilisé pour:\n\n'
                      '• Vérifier votre identité\n'
                      '• Sécuriser votre compte\n'
                      '• Vous envoyer des notifications importantes\n\n'
                      'Nous n\'utiliserons jamais votre numéro à des fins commerciales sans votre consentement.',
                      style: TextStyle(
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Compris',
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.info_outline,
                  size: 20, color: Theme.of(context).hintColor),
              label: Text(
                'En savoir plus',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final phone = _phoneController.text.trim();

                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer votre numéro'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (phone.length != 9) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le numéro doit contenir 9 chiffres'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await _api.addPhone(widget.userId, '+237' + phone);

                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SignUpStep1(userId: widget.userId),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAB91),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ÉTAPE 3: CHOIX DU TYPE DE COMPTE (ANCIENNE ÉTAPE 1)
// ====================================================================

class SignUpStep1 extends StatefulWidget {
  final int userId;

  const SignUpStep1({Key? key, required this.userId}) : super(key: key);

  @override
  State<SignUpStep1> createState() => _SignUpStep1State();
}

class _SignUpStep1State extends State<SignUpStep1> {
  final ApiService _api = ApiService();

  String _accountType = 'personal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).hintColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
            const SizedBox(height: 30),
            Text(
              'Créez un compte',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bénéficiez d\'une expérience personnalisée avec du contenu en lien avec votre activité et vos centres d\'intérêt sur notre service',
              style: TextStyle(color: Theme.of(context).hintColor, height: 1.5),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => setState(() => _accountType = 'personal'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _accountType == 'personal'
                        ? const Color(0xFF00897B)
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accountType == 'personal'
                              ? const Color(0xFF00897B)
                              : Theme.of(context).dividerColor,
                          width: 2,
                        ),
                        color: _accountType == 'personal'
                            ? const Color(0xFF00897B)
                            : Theme.of(context).cardColor,
                      ),
                      child: _accountType == 'personal'
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      'Pour vous *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => setState(() => _accountType = 'business'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _accountType == 'business'
                        ? const Color(0xFF00897B)
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _accountType == 'business'
                              ? const Color(0xFF00897B)
                              : Theme.of(context).dividerColor,
                          width: 2,
                        ),
                        color: _accountType == 'business'
                            ? const Color(0xFF00897B)
                            : Theme.of(context).cardColor,
                      ),
                      child: _accountType == 'business'
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      'Pour votre entreprise',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '* Vous agissez à titre professionnel ?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Créez plutôt un compte pro !',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'À défaut, en application de l\'article L 132–2 du Code de la consommation qui sanctionne les pratiques commerciales trompeuses, vous encourez une peine d\'emprisonnement de 2 ans et une amende de 300 000 FCFA.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _api.updateAccountType(widget.userId, _accountType);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SignUpStep2(userId: widget.userId),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// ÉTAPE 4: NOM D'UTILISATEUR (ANCIENNE ÉTAPE 4)
// ====================================================================

class SignUpStep2 extends StatefulWidget {
  final int userId;

  const SignUpStep2({Key? key, required this.userId}) : super(key: key);

  @override
  State<SignUpStep2> createState() => _SignUpStep2State();
}

class _SignUpStep2State extends State<SignUpStep2> {
  final ApiService _api = ApiService();

  final _usernameController = TextEditingController();
  bool _receiveNewsletters = false;
  bool _receivePartnerComms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).hintColor),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: 0.8,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
            const SizedBox(height: 30),
            Text(
              'Et pour finir, choisissez un\nnom d\'utilisateur',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _usernameController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Nom d\'utilisateur',
                labelStyle: TextStyle(color: Theme.of(context).hintColor),
                hintText: 'Ex: KamtoBusiness237',
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Votre nom d\'utilisateur sera visible sur votre profil ainsi que sur vos futures annonces. Vous pourrez le modifier quand vous le souhaitez !',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            CheckboxListTile(
              value: _receiveNewsletters,
              onChanged: (value) =>
                  setState(() => _receiveNewsletters = value!),
              activeColor: const Color(0xFF00897B),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Recevoir à propos des nouvelles fonctionnalités, des offres promo du moment et des tendances de recherches',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _receivePartnerComms,
              onChanged: (value) =>
                  setState(() => _receivePartnerComms = value!),
              activeColor: const Color(0xFF00897B),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Recevoir les communications en collaboration avec nos partenaires',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_usernameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez choisir un nom d\'utilisateur'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await _api.completeRegistration(
                      userId: widget.userId,
                      username: _usernameController.text,
                      firstName: '',
                      lastName: '',
                      receiveNotifications: _receiveNewsletters,
                      receivePartnerComms: _receivePartnerComms,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SignUpSuccess(username: _usernameController.text),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAB91),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style:
                    TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                children: [
                  const TextSpan(
                    text:
                        'Nous vous enverrons des communications automatiques basées sur votre activité. Pour ne pas en recevoir, ',
                  ),
                  TextSpan(
                    text: 'cliquez ici',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style:
                    TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                children: [
                  const TextSpan(
                    text:
                        'En créant mon compte je reconnais avoir lu et accepté les ',
                  ),
                  TextSpan(
                    text: 'Conditions Générales de Vente',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(text: ' et les '),
                  TextSpan(
                    text: 'Conditions Générales d\'Utilisation',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(
                      text: ' et je confirme être âgé d\'au moins 18 ans.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}

// ====================================================================
// ÉTAPE 5: PAGE DE SUCCÈS (CONSERVÉE)
// ====================================================================

// ====================================================================
// ÉTAPE 5: PAGE DE SUCCÈS
// ====================================================================

class SignUpSuccess extends StatelessWidget {
  final String username;

  const SignUpSuccess({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).hintColor),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: -20,
                    left: 50,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 20,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.yellow[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.handshake,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        Positioned(
                          top: 30,
                          right: 30,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Voilà,',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Votre compte est créé !',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Vous pouvez maintenant vendre, acheter, louer, chercher, discuter... et surtout trouver votre bonheur !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'E-mail vérifié',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          'Numéro de téléphone vérifié',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AuthState.login(username);
                    // ✅ MODIFICATION: Naviguer vers MainScreen au lieu de popUntil
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => MainScreen(
                          toggleTheme: () {},
                          themeMode: ThemeMode.light,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'C\'est parti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// PAGE 6: MON COMPTE
// ====================================================================

class AccountPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const AccountPage({
    Key? key,
    required this.toggleTheme,
    required this.themeMode,
  }) : super(key: key);

  // ✅ NOUVELLE FONCTION: Déconnexion
  Future<void> _logout(BuildContext context) async {
    final apiService = ApiService();
    await apiService.clearToken();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    AuthState.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          toggleTheme: toggleTheme,
          themeMode: themeMode,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text('Mon compte',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    AuthState.userName.isEmpty
                        ? 'U'
                        : AuthState.userName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AuthState.userName.isEmpty
                          ? 'Utilisateur'
                          : AuthState.userName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Porte-monnaie: 0 FCFA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(Icons.list_alt,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Mes annonces',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyAdsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.money,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Transactions',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.beach_access,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Réservations de vacances',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
            onTap: () {},
          ),
          Divider(color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Paramètres',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Informations personnelles',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.notifications,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Notifications',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.payment,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Moyens de paiement',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Mobile Money, Orange Money',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.palette,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Apparence',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (value) => toggleTheme(),
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: Icon(Icons.lock,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Sécurité',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
            onTap: () {},
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// PAGE MES ANNONCES
// ====================================================================

class MyAdsPage extends StatefulWidget {
  const MyAdsPage({Key? key}) : super(key: key);

  @override
  State<MyAdsPage> createState() => _MyAdsPageState();
}

class _MyAdsPageState extends State<MyAdsPage> {
  late ApiService apiService;
  List userListings = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    loadUserListings();
  }

  Future<void> loadUserListings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final listings = await apiService.getUserListings();

      setState(() {
        userListings = listings;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      setState(() {
        errorMessage = 'Erreur: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text('Mes annonces'),
        actions: [
          // Bouton pour rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadUserListings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 100,
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.5)),
                      const SizedBox(height: 20),
                      Text(
                        'Erreur',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: loadUserListings,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : userListings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 100,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3)),
                          const SizedBox(height: 20),
                          Text(
                            'Aucune annonce',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Vos annonces publiées apparaîtront ici',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: userListings.length,
                      itemBuilder: (context, index) {
                        final listing = userListings[index];
                        final photoUrl = listing['photoUrl'] ??
                            'https://via.placeholder.com/400';
                        final title = listing['title'] ?? 'Sans titre';
                        final price = listing['price'] ?? 0;
                        final isDonation = listing['isDonation'] ?? false;
                        final status = listing['status'] ?? 'active';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photoUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                            ),
                            title: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  isDonation ? 'Don' : '$price FCFA',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    status == 'active'
                                        ? '✅ Publiée'
                                        : status == 'sold'
                                            ? '❌ Vendue'
                                            : status == 'pending'
                                                ? '⏳ En attente'
                                                : status,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: status == 'active'
                                      ? Colors.green[100]
                                      : status == 'sold'
                                          ? Colors.red[100]
                                          : Colors.orange[100],
                                )
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Modifier'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18),
                                      SizedBox(width: 8),
                                      Text('Supprimer'),
                                    ],
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
