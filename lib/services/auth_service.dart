import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static bool _isLoggedIn = false;
  static String _userName = '';

  static bool get isLoggedIn => _isLoggedIn;
  static String get userName => _userName;

  Future<void> initAuthState() async {
    final prefs = await _prefs();
    final token = prefs.getString('jwt_token');
    if (token != null && token.isNotEmpty) {
      final username = prefs.getString('current_user_username') ?? 'Utilisateur';
      _isLoggedIn = true;
      _userName = username;
      
      await NotificationService.saveTokenToFirestore();
      final id = prefs.getInt('current_user_id');
      if (id != null) {
        NotificationService.listenToMessages(id.toString());
      }
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
      
      final prefs = await _prefs();
      await prefs.setString('jwt_token', 'local_token_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString('current_user_email', email);

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final username = data['username'] ?? 'Utilisateur';
        _isLoggedIn = true;
        _userName = username;
        await prefs.setString('current_user_username', username);
        return {'success': true, 'isComplete': true, 'username': username};
      }
      return {'success': true, 'isComplete': false};
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    final prefs = await _prefs();
    await prefs.remove('jwt_token');
    await _auth.signOut();
  }

  static void setLoggedIn(String name) {
    _isLoggedIn = true;
    _userName = name;
  }
}
