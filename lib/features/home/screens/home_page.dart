import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'product_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allAds = [];
  List<Map<String, dynamic>> _filteredAds = [];
  bool _isLoading = true;
  List<int> _favoriteIds = [];
  bool _loadingFavorites = false;

  // Filtres
  String _selectedCategory = 'Toutes';
  double? _minPrice;
  double? _maxPrice;

  final List<String> _categories = [
    'Toutes',
    'Immo',
    'Auto',
    'Vacances',
    'Smartphone',
    'Maison',
    'Sport',
    'Informatique',
    'Audio',
    'Gaming',
    'Autres'
  ];

  @override
  void initState() {
    super.initState();
    _loadAds();
    _loadFavoriteIds();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final ids = await _api.getFavoriteIds();
      setState(() => _favoriteIds = ids);
    } catch (e) {
      print('Erreur chargement favoris: $e');
    }
  }

  Future<void> _toggleFavorite(int listingId) async {
    if (_loadingFavorites) return;
    setState(() => _loadingFavorites = true);
    try {
      if (_favoriteIds.contains(listingId)) {
        await _api.removeFavorite(listingId);
        setState(() => _favoriteIds.remove(listingId));
      } else {
        await _api.addFavorite(listingId);
        setState(() => _favoriteIds.add(listingId));
      }
    } catch (e) {
      print('Erreur toggle favoris: $e');
    } finally {
      setState(() => _loadingFavorites = false);
    }
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    try {
      final listings = await _api.getAllListings();
      setState(() {
        _allAds = listings
            .where((l) => l['status'] == 'active')
            .map<Map<String, dynamic>>((listing) {
          var photoUrl =
              listing['photoUrl'] ?? 'https://via.placeholder.com/400';
          return {
            ...Map<String, dynamic>.from(listing),
            'id': listing['id'],
            'title': listing['title'] ?? 'Sans titre',
            'price': listing['price'] ?? 0,
            'image': photoUrl,
            'category': listing['category'] ?? 'général',
            'location': 'Yaoundé',
            'description': listing['description'] ?? '',
          };
        }).toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAds = _allAds.where((ad) {
        // Filtre par texte (titre, catégorie, description)
        final matchesText = query.isEmpty ||
            ad['title'].toString().toLowerCase().contains(query) ||
            ad['category'].toString().toLowerCase().contains(query) ||
            ad['description'].toString().toLowerCase().contains(query);

        // Filtre par catégorie
        final matchesCategory = _selectedCategory == 'Toutes' ||
            ad['category'].toString().toLowerCase() ==
                _selectedCategory.toLowerCase();

        // Filtre par prix
        final price = (ad['price'] as num).toDouble();
        final matchesMinPrice = _minPrice == null || price >= _minPrice!;
        final matchesMaxPrice = _maxPrice == null || price <= _maxPrice!;

        return matchesText &&
            matchesCategory &&
            matchesMinPrice &&
            matchesMaxPrice;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrer par prix',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix Min (FCFA)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              _minPrice = double.tryParse(val);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prix Max (FCFA)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              _maxPrice = double.tryParse(val);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Appliquer les filtres',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_isLoading)
              const Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00897B))))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAds,
                  color: const Color(0xFF00897B),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        _buildCategoriesScroll(),
                        const SizedBox(height: 25),
                        _buildPromoBanner(),
                        const SizedBox(height: 25),
                        _buildSectionTitle(context),
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
                offset: const Offset(0, 2))
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('marketmboa',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35))),
          Icon(Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurface, size: 24),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesScroll() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          IconData icon;
          switch (cat) {
            case 'Immo':
              icon = Icons.home_outlined;
              break;
            case 'Auto':
              icon = Icons.directions_car_outlined;
              break;
            case 'Vacances':
              icon = Icons.beach_access_outlined;
              break;
            case 'Smartphone':
              icon = Icons.smartphone;
              break;
            case 'Maison':
              icon = Icons.weekend;
              break;
            case 'Sport':
              icon = Icons.sports_basketball;
              break;
            case 'Informatique':
              icon = Icons.laptop;
              break;
            case 'Audio':
              icon = Icons.headset;
              break;
            case 'Gaming':
              icon = Icons.videogame_asset;
              break;
            case 'Autres':
              icon = Icons.more_horiz;
              break;
            default:
              icon = Icons.apps;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _applyFilters();
                });
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor:
                        isSelected ? const Color(0xFF00897B) : Colors.grey[100],
                    child: Icon(icon,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF00897B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected ? const Color(0xFF00897B) : Colors.black,
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

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C5A)])),
      child: const Center(
          child: Text('Annonces du moment',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text('Annonces récentes',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground)),
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
            mainAxisSpacing: 12),
        itemCount: _filteredAds.length,
        itemBuilder: (context, index) {
          final ad = _filteredAds[index];
          return InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProductDetailPage(ad: ad))),
            child: _buildAdCard(ad),
          );
        },
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final isFavorite = _favoriteIds.contains(ad['id']);
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(ad['image'],
                    height: 120, width: double.infinity, fit: BoxFit.cover)),
            Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                    onTap: () => _toggleFavorite(ad['id']),
                    child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey))),
          ]),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ad['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('${ad['price']} FCFA',
                  style: const TextStyle(
                      color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(child: Text('Aucun résultat'));
  }
}
