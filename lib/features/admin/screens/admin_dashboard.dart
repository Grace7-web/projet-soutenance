import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/api_service.dart';
import '../../home/screens/product_detail_page.dart';
import '../../home/screens/archives_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administration'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Modération'),
              Tab(text: 'Archives'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserManagementTab(),
            ListingModerationTab(),
            ArchivesPage(isUserOnly: false),
          ],
        ),
      ),
    );
  }
}

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _api.getAllUsers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isBlocked = user['isBlocked'] ?? false;
        final role = user['role'] ?? 'user';

        return ListTile(
          leading: CircleAvatar(
            child: Text(user['username']?[0]?.toUpperCase() ?? 'U'),
          ),
          title: Text(user['username'] ?? 'Utilisateur'),
          subtitle: Text('${user['email'] ?? ""} - $role'),
          trailing: role == 'admin' 
            ? const Chip(label: Text('Admin'))
            : IconButton(
                icon: Icon(
                  isBlocked ? Icons.lock : Icons.lock_open,
                  color: isBlocked ? Colors.red : Colors.green,
                ),
                onPressed: () async {
                  final success = await _api.updateUserStatus(user['uid'], !isBlocked);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isBlocked ? 'Compte débloqué' : 'Compte bloqué'))
                    );
                    _loadUsers();
                  }
                },
              ),
        );
      },
    );
  }
}

class ListingModerationTab extends StatefulWidget {
  const ListingModerationTab({super.key});

  @override
  State<ListingModerationTab> createState() => _ListingModerationTabState();
}

class _ListingModerationTabState extends State<ListingModerationTab> {
  List<Map<String, dynamic>> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    // On récupère toutes les annonces
    try {
      // Note: Retrait du orderBy pour éviter que les docs sans createdAt ne fassent échouer la requête
      final snap = await FirebaseFirestore.instance
          .collection('listings')
          .get();
      
      final listings = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': data['id'] ?? int.tryParse(d.id) ?? d.id,
          ...data,
        };
      }).toList();

      // Tri manuel pour éviter les erreurs Firestore si createdAt est manquant
      listings.sort((a, b) {
        final dateA = a['createdAt'];
        final dateB = b['createdAt'];
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        try {
          final timeA = dateA is DateTime ? dateA : dateA.toDate();
          final timeB = dateB is DateTime ? dateB : dateB.toDate();
          return timeB.compareTo(timeA);
        } catch (_) {
          return 0;
        }
      });

      setState(() {
        _listings = listings;
        _loading = false;
      });
    } catch (e) {
      print('Erreur _loadListings Admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_listings.isEmpty) return const Center(child: Text('Aucune annonce à modérer'));

    return ListView.builder(
      itemCount: _listings.length,
      itemBuilder: (context, index) {
        final ad = _listings[index];
        final createdAt = ad['createdAt'];
        String dateStr = 'Date inconnue';
        if (createdAt is DateTime) {
          dateStr =
              '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}';
        } else if (createdAt != null) {
          try {
            final date = createdAt.toDate();
            dateStr =
                '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
          } catch (_) {
            dateStr = createdAt.toString();
          }
        }

        final sellerName = ad['sellerFirstName'] != null 
            ? '${ad['sellerFirstName']} ${ad['sellerLastName'] ?? ""}'
            : 'Vendeur inconnu';
        
        final uniqueId = ad['uniqueId']?.toString();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ad['photoUrl'] ?? 'https://via.placeholder.com/150',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
              ),
            ),
            title: Text(ad['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Par: $sellerName', style: const TextStyle(fontSize: 12)),
                Text('Le: $dateStr', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                if (uniqueId != null && uniqueId.isNotEmpty)
                  Text('ID Unique: $uniqueId', style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Text('${ad['price']} F', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailPage(ad: ad)),
              );
              if (result == true) _loadListings();
            },
          ),
        );
      },
    );
  }
}
