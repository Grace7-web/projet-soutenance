import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_service.dart';
import 'product_detail_page.dart';

class ArchivesPage extends StatefulWidget {
  final bool isUserOnly; // Si vrai, affiche uniquement les ventes de l'utilisateur actuel

  const ArchivesPage({super.key, required this.isUserOnly});

  @override
  State<ArchivesPage> createState() => _ArchivesPageState();
}

class _ArchivesPageState extends State<ArchivesPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _soldListings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSold();
  }

  Future<void> _loadSold() async {
    try {
      final sold = await _api.getListingsByStatus('sold');
      final uid = FirebaseAuth.instance.currentUser?.uid;

      setState(() {
        if (widget.isUserOnly && uid != null) {
          _soldListings = sold.where((l) => l['sellerUid'] == uid).toList();
        } else {
          _soldListings = sold;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_soldListings.isEmpty) {
      return const Center(child: Text('Aucun produit vendu archivé.'));
    }

    return Scaffold(
      appBar: widget.isUserOnly 
        ? AppBar(title: const Text('Mes produits vendus'))
        : null, // Pas de AppBar si c'est un onglet du dashboard admin
      body: ListView.builder(
        itemCount: _soldListings.length,
        itemBuilder: (context, index) {
          final ad = _soldListings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Image.network(
                ad['photoUrl'] ?? 'https://via.placeholder.com/150',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              ),
              title: Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${ad['price']} FCFA - Vendu'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailPage(ad: ad)),
              ),
            ),
          );
        },
      ),
    );
  }
}
