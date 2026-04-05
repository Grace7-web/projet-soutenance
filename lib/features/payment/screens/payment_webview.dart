import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../services/payment_service.dart';

class PaymentWebView extends StatefulWidget {
  final String initialUrl;
  final String reference;
  const PaymentWebView(
      {super.key, required this.initialUrl, required this.reference});
  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  final PaymentService _payments = PaymentService();
  late final WebViewController _controller;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.initialUrl));
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_done) return;
    try {
      final res = await _payments.getPaymentStatus(widget.reference);
      final s = (res['status'] ?? '').toString().toLowerCase();
      if (s.isEmpty) return;
      if (s.contains('success') ||
          s.contains('complete') ||
          s.contains('paid')) {
        _done = true;
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement réussi')),
        );
      } else if (s.contains('fail') ||
          s.contains('cancel') ||
          s.contains('refus')) {
        _done = true;
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement non abouti')),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
