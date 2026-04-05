import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String photoUrl;
  final List<String> photos;
  final String sellerUid;
  final String sellerName;
  final DateTime? createdAt;

  ListingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.photoUrl,
    required this.photos,
    required this.sellerUid,
    required this.sellerName,
    this.createdAt,
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final photosList = (data['photos'] as List?)?.map((p) => p['url'] as String).toList() ?? [];
    
    return ListingModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'général',
      photoUrl: data['photoUrl'] ?? 'https://via.placeholder.com/400',
      photos: photosList,
      sellerUid: data['sellerUid'] ?? '',
      sellerName: '${data['sellerFirstName'] ?? ''} ${data['sellerLastName'] ?? ''}'.trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
