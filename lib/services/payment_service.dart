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
}
