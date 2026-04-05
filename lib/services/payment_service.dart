import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/payments_config.dart';

class PaymentService {
  Future<Map<String, dynamic>> startMtnPayment({
    required String phone,
    required double amount,
    required String currency,
    required String reference,
  }) async {
    if (paymentBaseUrl.startsWith('REPLACE')) {
      throw Exception('Configurer paymentBaseUrl');
    }
    final uri = Uri.parse('$paymentBaseUrl/momoCollect');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'amount': amount,
        'currency': currency,
        'reference': reference,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Paiement MTN échoué: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> startOrangePayment({
    required String phone,
    required double amount,
    required String currency,
    required String reference,
  }) async {
    if (paymentBaseUrl.startsWith('REPLACE')) {
      throw Exception('Configurer paymentBaseUrl');
    }
    final uri = Uri.parse('$paymentBaseUrl/orangeCollect');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'amount': amount,
        'currency': currency,
        'reference': reference,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Paiement Orange échoué: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getPaymentStatus(String reference) async {
    if (paymentBaseUrl.startsWith('REPLACE')) {
      throw Exception('Configurer paymentBaseUrl');
    }
    final uri = Uri.parse('$paymentBaseUrl/paymentStatus?ref=$reference');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Statut paiement indisponible: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> startCinetPayPayment({
    required String phone,
    required double amount,
    required String currency,
    required String reference,
    String? channel,
  }) async {
    if (paymentBaseUrl.startsWith('REPLACE')) {
      throw Exception('Configurer paymentBaseUrl');
    }
    final uri = Uri.parse('$paymentBaseUrl/cinetpayInit');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'amount': amount,
        'currency': currency,
        'reference': reference,
        'channel': channel,
        'description': 'marketmboa',
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Paiement CinetPay échoué: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> startNotchPayPayment({
    required double amount,
    required String currency,
    required String email,
    required String reference,
    String? name,
    String? phone,
    String? description,
  }) async {
    // ✅ MODIFICATION: Utilisation de la clé de test NotchPay correcte
    final uri = Uri.parse('https://api.notchpay.co/payments/initialize');
    const publicKey =
        'pk_test.scDIlmLZpBHVNDmoRfq5oq5bpa89f7XWuOnHnqhTjtGD0XEazNSNoLFo2BGNnwj86k8dG9RxwW96B3blRIDTTww4eRQIGT5YJi3hr0l9o6L9MpBYlyMOJAuu9rC4Z';

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-public-key': publicKey,
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'email': email,
        'reference': reference,
        'customer': {
          'name': name ?? 'Client',
          'email': email,
          'phone': phone,
        },
        'description': description ?? 'Achat sur MarketMboa',
        'callback': 'https://marketmboa.web.app/payment-callback',
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      return {
        'paymentUrl': data['authorization_url'],
        'reference': reference,
        'message': 'Paiement NotchPay initié'
      };
    }
    
    final errorData = jsonDecode(res.body);
    throw Exception('Erreur NotchPay (${res.statusCode}): ${errorData['message'] ?? res.body}');
  }

  Future<Map<String, dynamic>> getNotchPayStatus(String reference) async {
    if (paymentBaseUrl.startsWith('REPLACE')) {
      throw Exception('Configurer paymentBaseUrl');
    }
    final uri = Uri.parse('$paymentBaseUrl/notchpayStatus?ref=$reference');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Statut NotchPay indisponible: ${res.statusCode}');
  }
}
