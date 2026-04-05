import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:async';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<QuerySnapshot>? _messageSubscription;

  static void listenToMessages(String userId) {
    _messageSubscription?.cancel();
    _messageSubscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          _showLocalNotification(
            title: 'Nouveau message',
            body: data['text'] ?? 'Vous avez reçu un message',
          );
        }
      }
    });
  }

  static Future<void> _showLocalNotification(
      {required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'Notifications Importantes',
      channelDescription:
          'Ce canal est utilisé pour les notifications de messages.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> init() async {
    // 1. Demander les permissions (iOS/Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Utilisateur a autorisé les notifications');
    }

    // 2. Configurer les notifications locales pour le premier plan
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Gérer le clic sur la notification ici si besoin
      },
    );

    // 3. Créer un canal Android (requis pour Android 8+)
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notifications Importantes',
        description: 'Ce canal est utilisé pour les notifications de messages.',
        importance: Importance.max,
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    // 4. Écouter les messages au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _showLocalNotification(
          title: notification.title ?? 'Nouveau message',
          body: notification.body ?? '',
        );
      }
    });

    // 5. Gérer le clic sur une notification quand l'app est en arrière-plan ou fermée
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App ouverte via une notification: ${message.data}');
    });

    // 6. Récupérer et enregistrer le jeton FCM
    await saveTokenToFirestore();
  }

  static Future<void> saveTokenToFirestore() async {
    try {
      String? token = await _messaging.getToken();
      User? user = FirebaseAuth.instance.currentUser;

      if (token != null && user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Token FCM enregistré: $token');
      }
    } catch (e) {
      print('Erreur lors de l\'enregistrement du token FCM: $e');
    }
  }
}
