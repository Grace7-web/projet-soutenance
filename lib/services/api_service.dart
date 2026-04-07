import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/api';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  List<Map<String, dynamic>> _defaultListings() {
    return [
      {
        'id': 1,
        'title': 'Samsung Galaxy A54',
        'price': 120000,
        'category': 'smartphone',
        'description': 'Téléphone en très bon état, vendu avec accessoires',
        'photoUrl':
            'https://images.unsplash.com/photo-1510557880182-3d4d3d4e56c3?w=600'
      },
      {
        'id': 2,
        'title': 'Chaise de bureau ergonomique',
        'price': 45000,
        'category': 'maison',
        'description': 'Chaise confortable, idéale pour le télétravail',
        'photoUrl':
            'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=600'
      },
      {
        'id': 3,
        'title': 'Vélo tout terrain',
        'price': 80000,
        'category': 'sport',
        'description': 'VTT en bon état, pneus neufs',
        'photoUrl':
            'https://images.unsplash.com/photo-1516442719524-a603408c90cb?w=600'
      },
      {
        'id': 4,
        'title': 'Ordinateur portable Dell',
        'price': 250000,
        'category': 'informatique',
        'description': 'i5, 8Go RAM, SSD 256Go',
        'photoUrl':
            'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600'
      },
      {
        'id': 5,
        'title': 'Appartement 2 pièces à Yaoundé',
        'price': 150000,
        'category': 'immobilier',
        'description': 'Quartier calme, proche commerces',
        'photoUrl':
            'https://images.unsplash.com/photo-1505691723518-36a5ac3b2b8b?w=600'
      },
      {
        'id': 6,
        'title': 'Casque audio Bluetooth',
        'price': 20000,
        'category': 'audio',
        'description': 'Autonomie 20h, réduction de bruit',
        'photoUrl':
            'https://images.unsplash.com/photo-1518444028785-8f1e4e1b2d7b?w=600'
      },
      {
        'id': 7,
        'title': 'Console de jeux',
        'price': 180000,
        'category': 'gaming',
        'description': 'Avec manette et 3 jeux inclus',
        'photoUrl':
            'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=600'
      },
      {
        'id': 8,
        'title': 'Table basse en bois',
        'price': 30000,
        'category': 'maison',
        'description': 'Style moderne, très bon état',
        'photoUrl':
            'https://images.unsplash.com/photo-1493666438817-866a91353ca9?w=600'
      },
    ];
  }

  Future<String?> getToken() async {
    final prefs = await _prefs();
    return prefs.getString('jwt_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await _prefs();
    await prefs.setString('jwt_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await _prefs();
    await prefs.remove('jwt_token');
  }

  Future<Map<String, dynamic>> register(String email) async {
    final prefs = await _prefs();
    final userId = prefs.getInt('current_user_id') ?? 1;
    await prefs.setString('current_user_email', email);
    await prefs.setInt('current_user_id', userId);
    return {'success': true, 'userId': userId};
  }

  Future<Map<String, dynamic>> verifyEmail(int userId, String code) async {
    return {'success': true};
  }

  Future<Map<String, dynamic>> addPhone(int userId, String phone) async {
    final prefs = await _prefs();
    await prefs.setString('current_user_phone', phone);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'phone': phone}, SetOptions(merge: true));
      }
    } catch (_) {}
    return {'success': true};
  }

  Future<Map<String, dynamic>> updateAccountType(
      int userId, String accountType) async {
    final prefs = await _prefs();
    await prefs.setString('current_user_account_type', accountType);
    return {'success': true};
  }

  Future<Map<String, dynamic>> completeRegistration({
    required int userId,
    required String username,
    String? firstName,
    String? lastName,
    bool receiveNotifications = true,
    bool receivePartnerComms = false,
  }) async {
    final prefs = await _prefs();
    await prefs.setString('current_user_username', username);
    await prefs.setString('current_user_first_name', firstName ?? '');
    await prefs.setString('current_user_last_name', lastName ?? '');
    await prefs.setBool(
        'current_user_receive_notifications', receiveNotifications);
    await prefs.setBool(
        'current_user_receive_partner_comms', receivePartnerComms);

    // Sauvegarde dans Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'receiveNotifications': receiveNotifications,
        'receivePartnerComms': receivePartnerComms,
      }, SetOptions(merge: true));
    }

    final token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
    await saveToken(token);
    return {'success': true, 'token': token};
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final prefs = await _prefs();
    final id = prefs.getInt('current_user_id') ?? 1;
    final username = prefs.getString('current_user_username') ?? 'Utilisateur';
    final firstName = prefs.getString('current_user_first_name') ?? '';
    final lastName = prefs.getString('current_user_last_name') ?? '';
    final phone = prefs.getString('current_user_phone') ?? '';
    final role = prefs.getString('current_user_role') ?? 'user';
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role,
    };
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final me = await getCurrentUser();
    if ((me['id'] as int) == userId) return me;
    return {
      'id': userId,
      'username': 'Vendeur',
      'firstName': 'Vendeur',
      'lastName': '',
      'phone': '',
    };
  }

  Future<Map<String, dynamic>> login(String email) async {
    final prefs = await _prefs();
    await prefs.setString('current_user_email', email);

    // Tentative de récupération depuis Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('username')) {
          await prefs.setString('current_user_username', data['username']);
          await prefs.setString(
              'current_user_first_name', data['firstName'] ?? '');
          await prefs.setString(
              'current_user_last_name', data['lastName'] ?? '');
          await prefs.setString('current_user_phone', data['phone'] ?? '');
          final role = data['role'] ?? 'user';
          await prefs.setString('current_user_role', role);
          final isBlocked = data['isBlocked'] ?? false;
          if (isBlocked) {
            return {
              'success': false,
              'message': 'Votre compte a été bloqué par l\'administrateur.'
            };
          }
          final token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
          await saveToken(token);
          return {
            'success': true,
            'token': token,
            'isComplete': true,
            'username': data['username']
          };
        }
      }
    }

    final token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
    await saveToken(token);
    return {'success': true, 'token': token, 'isComplete': false};
  }

  Future<Map<String, dynamic>> createListing({
    required String title,
    required String description,
    required double price,
    required String color,
    required String condition,
    required int conditionPercentage,
    String? uniqueId,
    required String category,
    required List<File> photos,
    String? firstName,
    String? lastName,
  }) async {
    final prefs = await _prefs();
    final nextId = (prefs.getInt('next_listing_id') ?? 1000) + 1;
    await prefs.setInt('next_listing_id', nextId);

    final currentUser = await getCurrentUser();
    final sellerId = (currentUser['id'] as int);
    final sellerFirst = (currentUser['firstName'] as String);
    final sellerLast = (currentUser['lastName'] as String);
    final sellerUid = FirebaseAuth.instance.currentUser?.uid ?? 'local';

    List<String> photoUrls = [];
    for (var i = 0; i < photos.length; i++) {
      final file = photos[i];
      final url = await _uploadToCloudinary(file);
      photoUrls.add(url);
    }

    final listing = {
      'id': nextId,
      'title': title,
      'description': description,
      'price': price,
      'color': color,
      'condition': condition,
      'conditionPercentage': conditionPercentage,
      'uniqueId': uniqueId,
      'category': category,
      'isDonation': price == 0,
      'status': 'active',
      'photos': photoUrls.map((u) => {'url': u}).toList(),
      'sellerFirstName': (firstName ?? sellerFirst),
      'sellerLastName': (lastName ?? sellerLast),
      'sellerUserId': sellerId,
      'sellerUid': sellerUid,
      'photoUrl': photoUrls.isNotEmpty ? photoUrls.first : null,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(nextId.toString())
          .set(listing);
    } catch (_) {}

    final listingForPrefs = {
      ...listing,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final existingUserListings = prefs.getString('user_listings');
    List<dynamic> parsed =
        existingUserListings != null ? jsonDecode(existingUserListings) : [];
    parsed.add(listingForPrefs);
    await prefs.setString('user_listings', jsonEncode(parsed));

    final allListingsStr = prefs.getString('all_listings');
    List<dynamic> allParsed = allListingsStr != null
        ? jsonDecode(allListingsStr)
        : _defaultListings();
    allParsed.add(listingForPrefs);
    await prefs.setString('all_listings', jsonEncode(allParsed));

    return {'success': true, 'listing': listing};
  }

  Future<String> _uploadToCloudinary(File file) async {
    if (cloudinaryCloudName.isEmpty || cloudinaryUploadPreset.isEmpty) {
      throw Exception('Cloudinary config manquante');
    }
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = cloudinaryUploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary ${response.statusCode}: $body');
    }
    final data = jsonDecode(body);
    final url = data['secure_url'] ?? data['url'];
    if (url == null) {
      throw Exception('URL Cloudinary manquante');
    }
    return url;
  }

  Future<List> getAllListings() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();
      final docs = snap.docs.map((d) {
        final data = d.data();
        return {
          'id': data['id'] ?? int.tryParse(d.id) ?? d.id,
          'title': data['title'],
          'description': data['description'],
          'price': data['price'],
          'color': data['color'],
          'condition': data['condition'],
          'conditionPercentage': data['conditionPercentage'],
          'uniqueId': data['uniqueId'],
          'category': data['category'],
          'isDonation': data['isDonation'] ?? false,
          'status': data['status'] ?? 'active',
          'photos': data['photos'] ?? [],
          'photoUrl': data['photoUrl'],
        };
      }).toList();
      if (docs.isNotEmpty) return docs;
    } catch (_) {}
    final prefs = await _prefs();
    final stored = prefs.getString('all_listings');
    final listings = stored != null
        ? List<Map<String, dynamic>>.from(jsonDecode(stored))
        : _defaultListings();
    return listings;
  }

  Future<Map<String, dynamic>> getOrCreateConversation({
    required int sellerUserId,
    required int listingId,
  }) async {
    final me = await getCurrentUser();
    String? buyerUid = FirebaseAuth.instance.currentUser?.uid;
    String? sellerUid;
    String? sellerPhone;
    String? sellerName;
    try {
      final listingDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId.toString())
          .get();
      if (listingDoc.exists) {
        final data = listingDoc.data()!;
        sellerUid = data['sellerUid'] as String?;
        final uid = sellerUid;
        if (uid != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          if (userDoc.exists) {
            sellerPhone = (userDoc.data() ?? {})['phone'] as String?;
          }
        }
        final sf = (data['sellerFirstName'] as String?) ?? '';
        final sl = (data['sellerLastName'] as String?) ?? '';
        final name = ('$sf $sl').trim();
        sellerName =
            name.isNotEmpty ? name : (data['username'] as String?) ?? 'Vendeur';
      }
    } catch (_) {}
    sellerUid ??= 'local_$sellerUserId';
    buyerUid ??= 'local_${me['id']}';
    final convQuery = await FirebaseFirestore.instance
        .collection('conversations')
        .where('listingId', isEqualTo: listingId)
        .where('participants', arrayContains: buyerUid)
        .limit(1)
        .get();
    Map<String, dynamic>? convData;
    if (convQuery.docs.isNotEmpty) {
      final doc = convQuery.docs.first;
      final data = doc.data();
      if ((data['participants'] as List).contains(sellerUid)) {
        convData = {'id': doc.id, ...data};
        if ((convData['sellerName'] as String?) == null && sellerName != null) {
          convData['sellerName'] = sellerName;
        }
      }
    }
    if (convData == null) {
      final newDoc =
          await FirebaseFirestore.instance.collection('conversations').add({
        'listingId': listingId,
        'participants': [buyerUid, sellerUid],
        'buyerUserId': me['id'],
        'sellerUserId': sellerUserId,
        'sellerPhone': sellerPhone,
        'sellerName': sellerName ?? 'Vendeur',
        'buyerName': me['username'] ?? 'Acheteur',
        'buyerPhone': me['phone'],
        'lastMessageText': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      final created = await newDoc.get();
      convData = {'id': newDoc.id, ...created.data()!};
    }
    return convData;
  }

  Future<void> sendMessage(String conversationId, String text,
      {String? senderUid}) async {
    final uid = senderUid ?? FirebaseAuth.instance.currentUser?.uid ?? 'local';

    // Récupérer les participants pour trouver le destinataire
    final convDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get();
    final participants =
        List<String>.from(convDoc.data()?['participants'] ?? []);
    final receiverId =
        participants.firstWhere((id) => id != uid, orElse: () => '');

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderUid': uid,
      'receiverId': receiverId,
      'text': text,
      'at': FieldValue.serverTimestamp(),
      'read': false,
    });

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .set({
      'lastMessageText': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('at')
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'senderUid': data['senderUid'],
          'text': data['text'],
          'at': data['at'],
        };
      }).toList();
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getConversationsForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'local';
    try {
      final snap = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .orderBy('lastMessageAt', descending: true)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {'id': d.id, ...data};
      }).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> addFavorite(int listingId) async {
    final prefs = await _prefs();
    final idsStr = prefs.getString('favorite_ids');
    List<dynamic> ids = idsStr != null ? jsonDecode(idsStr) : [];
    if (!ids.contains(listingId)) {
      ids.add(listingId);
      await prefs.setString('favorite_ids', jsonEncode(ids));
    }
    return {'success': true};
  }

  Future<void> removeFavorite(int listingId) async {
    final prefs = await _prefs();
    final idsStr = prefs.getString('favorite_ids');
    List<dynamic> ids = idsStr != null ? jsonDecode(idsStr) : [];
    ids.removeWhere((id) => id == listingId);
    await prefs.setString('favorite_ids', jsonEncode(ids));
  }

  Future<List> getUserFavorites() async {
    final prefs = await _prefs();
    final idsStr = prefs.getString('favorite_ids');
    List<dynamic> ids = idsStr != null ? jsonDecode(idsStr) : [];
    final listings = await getAllListings();
    final byId = {for (var l in listings) l['id']: l};
    return ids.map((id) {
      final listing = byId[id] ?? {};
      final photoUrl = listing['photoUrl'] ?? 'https://via.placeholder.com/400';
      return {
        'id': listing['id'] ?? id,
        'title': listing['title'] ?? 'Sans titre',
        'price': '${listing['price'] ?? 0} FCFA',
        'image': photoUrl,
        'category': listing['category'] ?? 'général',
        'description': listing['description'] ?? '',
        'condition': listing['condition'],
        'conditionPercentage': listing['conditionPercentage'],
        'uniqueId': listing['uniqueId'],
      };
    }).toList();
  }

  Future<List<int>> getFavoriteIds() async {
    final prefs = await _prefs();
    final idsStr = prefs.getString('favorite_ids');
    List<dynamic> ids = idsStr != null ? jsonDecode(idsStr) : [];
    return ids.map((e) => (e as num).toInt()).toList();
  }

  Future<List> getUserListings() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('listings')
            .where('sellerUid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs.map((d) {
          final data = d.data();
          final photoUrl =
              data['photoUrl'] ?? 'https://via.placeholder.com/400';
          return {
            ...data,
            'photoUrl': photoUrl,
            'conditionPercentage': data['conditionPercentage'],
            'uniqueId': data['uniqueId'],
          };
        }).toList();
      }
    } catch (_) {}
    final prefs = await _prefs();
    final stored = prefs.getString('user_listings');
    final listings = stored != null
        ? List<Map<String, dynamic>>.from(jsonDecode(stored))
        : [];
    return listings.map((listing) {
      final photoUrl = listing['photoUrl'] ?? 'https://via.placeholder.com/400';
      return {...listing, 'photoUrl': photoUrl};
    }).toList();
  }

  Future<Map<String, dynamic>> createManualOrder({
    required int listingId,
    required double amount,
    required String provider, // 'orange' | 'mtn'
    required String reference,
    String? sellerPhone,
  }) async {
    String? buyerUid = FirebaseAuth.instance.currentUser?.uid ?? 'local';
    String? sellerUid;
    try {
      final listingDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId.toString())
          .get();
      if (listingDoc.exists) {
        final data = listingDoc.data()!;
        sellerUid = data['sellerUid'] as String?;
      }
    } catch (_) {}
    sellerUid ??= 'unknown';
    final order = {
      'listingId': listingId,
      'amount': amount,
      'currency': 'XAF',
      'provider': provider,
      'reference': reference,
      'sellerPhone': sellerPhone,
      'buyerUid': buyerUid,
      'sellerUid': sellerUid,
      'status': 'manual_pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      final doc =
          await FirebaseFirestore.instance.collection('orders').add(order);
      return {'id': doc.id, ...order};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<bool> deleteListing(int listingId) async {
    try {
      // 1. Supprimer de Firestore
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId.toString())
          .delete();

      // 2. Supprimer du cache local SharedPreferences
      final prefs = await _prefs();

      // Supprimer de user_listings
      final userListingsStr = prefs.getString('user_listings');
      if (userListingsStr != null) {
        List<dynamic> userListings = jsonDecode(userListingsStr);
        userListings.removeWhere((l) => l['id'] == listingId);
        await prefs.setString('user_listings', jsonEncode(userListings));
      }

      // Supprimer de all_listings
      final allListingsStr = prefs.getString('all_listings');
      if (allListingsStr != null) {
        List<dynamic> allListings = jsonDecode(allListingsStr);
        allListings.removeWhere((l) => l['id'] == listingId);
        await prefs.setString('all_listings', jsonEncode(allListings));
      }

      // Supprimer des favoris si présent
      final favoriteIdsStr = prefs.getString('favorite_ids');
      if (favoriteIdsStr != null) {
        List<dynamic> favoriteIds = jsonDecode(favoriteIdsStr);
        favoriteIds.removeWhere((id) => id == listingId);
        await prefs.setString('favorite_ids', jsonEncode(favoriteIds));
      }

      return true;
    } catch (e) {
      print('Erreur lors de la suppression : $e');
      return false;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      final convRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId);

      // Supprimer les messages d'abord
      final messages = await convRef.collection('messages').get();
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Supprimer la conversation
      await convRef.delete();
      return true;
    } catch (e) {
      print('Erreur deleteConversation: $e');
      return false;
    }
  }

  Future<bool> deleteMessage(String conversationId, String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      print('Erreur deleteMessage: $e');
      return false;
    }
  }

  // --- Fonctions Admin ---

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
    } catch (e) {
      print('Erreur getAllUsers: $e');
      return [];
    }
  }

  Future<bool> updateUserStatus(String uid, bool isBlocked) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'isBlocked': isBlocked});
      return true;
    } catch (e) {
      print('Erreur updateUserStatus: $e');
      return false;
    }
  }

  Future<bool> updateListingStatus(int listingId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId.toString())
          .update({'status': status});

      // Mettre à jour le cache local également si nécessaire
      final prefs = await _prefs();
      final allListingsStr = prefs.getString('all_listings');
      if (allListingsStr != null) {
        List<dynamic> allParsed = jsonDecode(allListingsStr);
        for (var l in allParsed) {
          if (l['id'] == listingId) {
            l['status'] = status;
          }
        }
        await prefs.setString('all_listings', jsonEncode(allParsed));
      }

      return true;
    } catch (e) {
      print('Erreur updateListingStatus: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getListingsByStatus(String status) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('listings')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id': data['id'] ?? int.tryParse(d.id) ?? d.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Erreur getListingsByStatus: $e');
      return [];
    }
  }
}
