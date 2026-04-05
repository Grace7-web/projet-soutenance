import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String phone;
  final String? fcmToken;
  final String role; // 'user' ou 'admin'

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.fcmToken,
    this.role = 'user',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      fcmToken: data['fcmToken'],
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'fcmToken': fcmToken,
      'role': role,
    };
  }
}
