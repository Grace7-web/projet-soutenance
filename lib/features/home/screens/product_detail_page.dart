import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import '../../../services/payment_service.dart';
import '../../messages/screens/conversation_page.dart';
import '../../payment/screens/payment_webview.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> ad;
  const ProductDetailPage({super.key, required this.ad});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _api = ApiService();
  final PaymentService _payments = PaymentService();
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  Map<String, dynamic>? _seller;
  Map<String, dynamic>? _currentUser;

  List<String> get _photos {
    final raw = widget.ad['photos'];
    if (raw is List && raw.isNotEmpty) {
      if (raw.first is Map && (raw.first as Map).containsKey('url')) {
        return raw.map((e) => (e as Map)['url'].toString()).toList();
      }
      if (raw.first is String) {
        return raw.cast<String>();
      }
    }
    final cover = widget.ad['image'] ?? widget.ad['photoUrl'];
    if (cover is String) return [cover];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _initFavorite();
    _loadSeller();
  }

  Future<void> _initFavorite() async {
    final ids = await _api.getFavoriteIds();
    setState(() {
      _isFavorite = ids.contains(widget.ad['id']);
    });
  }

  Future<void> _loadSeller() async {
    final me = await _api.getCurrentUser();
    final sellerId = widget.ad['sellerUserId'] is int
        ? widget.ad['sellerUserId'] as int
        : null;
    Map<String, dynamic> seller;
    if (sellerId != null) {
      seller = await _api.getUserById(sellerId);
    } else {
      seller = me;
    }
    setState(() {
      _seller = seller;
      _currentUser = me;
    });
  }

  void _toggleFavorite() async {
    final id = widget.ad['id'] as int;
    if (_isFavorite) {
      await _api.removeFavorite(id);
    } else {
      await _api.addFavorite(id);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _deleteAd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Voulez-vous vraiment supprimer cette annonce ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _api.deleteListing(widget.ad['id'] as int);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce supprimée avec succès')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _markAsSold() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marquer comme vendu'),
        content: const Text('Cette annonce sera déplacée dans les archives.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await _api.updateListingStatus(widget.ad['id'] as int, 'sold');
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce marquée comme vendue')),
          );
          Navigator.pop(context, true);
        }
      }
    }
  }

  void _openInbox() async {
    final sellerUserId = widget.ad['sellerUserId'] as int?;
    if (_currentUser != null && sellerUserId == _currentUser!['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous ne pouvez pas discuter avec vous-même')),
      );
      return;
    }
    final sellerId = sellerUserId ?? (_seller != null ? _seller!['id'] as int : 1);
    final conv = await _api.getOrCreateConversation(
      sellerUserId: sellerId,
      listingId: widget.ad['id'] as int,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(conversation: conv),
      ),
    );
  }

  Future<void> _pay(String provider, double amount) async {
    final controller = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Entrer le numéro mobile'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Ex: 6XXXXXXXX'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dCtx).pop(controller.text.trim()),
              child: const Text('Valider'),
            )
          ],
        );
      },
    );
    if (phone == null || phone.isEmpty) return;
    final ref =
        'ad_${widget.ad['id']}_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await _payments.startCinetPayPayment(
        phone: phone,
        amount: amount,
        currency: 'XAF',
        reference: ref,
        channel: provider,
      );
      if (!mounted) return;
      final url = res['paymentUrl']?.toString();
      if (url != null && url.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(initialUrl: url, reference: ref),
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message']?.toString() ?? 'Paiement initié')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur paiement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _payNotchPay(double amount) async {
    final me = await _api.getCurrentUser();
    final email = (me['email'] as String?) ?? 'client@marketmboa.com';
    final name = (me['username'] as String?) ?? 'Client MarketMboa';
    final phone = (me['phone'] as String?) ?? '';

    final ref =
        'ad_${widget.ad['id']}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final res = await _payments.startNotchPayPayment(
        amount: amount,
        currency: 'XAF',
        email: email,
        reference: ref,
        name: name,
        phone: phone,
        description: 'Achat: ${widget.ad['title']}',
      );

      if (!mounted) return;
      final url = res['paymentUrl']?.toString();
      if (url != null && url.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebView(initialUrl: url, reference: ref),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur NotchPay: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openPaymentSheet() async {
    final amount = (widget.ad['price'] is num)
        ? (widget.ad['price'] as num).toDouble()
        : double.tryParse(widget.ad['price']?.toString() ?? '') ?? 0.0;
    Future<void> launchUSSD(String encoded) async {
      final uri = Uri.parse('tel:$encoded');
      await launchUrl(uri);
    }

    Future<void> confirmUssdPayment(String provider) async {
      final ref =
          'ussd_${widget.ad['id']}_${DateTime.now().millisecondsSinceEpoch}';
      final res = await _api.createManualOrder(
        listingId: widget.ad['id'] as int,
        amount: amount,
        provider: provider,
        reference: ref,
        sellerPhone: _seller?['phone'] as String?,
      );
      if (!mounted) return;
      if (res['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${res['error']}'),
          backgroundColor: Colors.red,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Commande enregistrée. Paiement à confirmer.'),
          backgroundColor: Colors.green,
        ));
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisir le moyen de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Montant: ${amount.toStringAsFixed(0)} FCFA',
                style: TextStyle(color: Theme.of(ctx).hintColor),
              ),
              const SizedBox(height: 16),
              // Nouveau bouton NotchPay mis en avant
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _payNotchPay(amount);
                  },
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  label: const Text('Payer avec NotchPay (Recommandé)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Autres options de paiement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).hintColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _pay('orange', amount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7900),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.white),
                            SizedBox(height: 6),
                            Text('Orange Money',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _pay('mtn', amount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDD00),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.black),
                            SizedBox(height: 6),
                            Text('MTN Mobile Money',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mode soutenance (USSD sur votre téléphone)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await launchUSSD('%23150%23');
                      },
                      icon: const Icon(Icons.phone_in_talk),
                      label: const Text('USSD Orange'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await launchUSSD('*126%23');
                      },
                      icon: const Icon(Icons.phone_in_talk),
                      label: const Text('USSD MTN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => confirmUssdPayment('orange_ussd'),
                    child: const Text('J’ai payé (OM)'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => confirmUssdPayment('mtn_ussd'),
                    child: const Text('J’ai payé (MTN)'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.ad['title']?.toString() ?? 'Sans titre';
    final priceText = widget.ad['price']?.toString() ?? '';
    final priceDisplay =
        priceText.contains('FCFA') ? priceText : '$priceText FCFA';
    final description = widget.ad['description']?.toString() ?? '';
    final category = widget.ad['category']?.toString() ?? 'général';
    final condition = widget.ad['condition']?.toString() ?? 'Bon état';
    final conditionPercentage = widget.ad['conditionPercentage']?.toString();
    final uniqueId = widget.ad['uniqueId']?.toString();
    final color = widget.ad['color']?.toString() ?? 'Non spécifié';
    final location = widget.ad['location']?.toString() ?? 'Cameroun';
    final sellerFirst = widget.ad['sellerFirstName']?.toString() ?? '';
    final sellerLast = widget.ad['sellerLastName']?.toString() ?? '';
    String sellerName = ('$sellerFirst $sellerLast').trim().isEmpty
        ? 'Utilisateur'
        : ('$sellerFirst $sellerLast').trim();
    if (_seller != null) {
      final sFirst = (_seller!['firstName'] as String?) ?? '';
      final sLast = (_seller!['lastName'] as String?) ?? '';
      final sUser = (_seller!['username'] as String?) ?? '';
      final computed = ('$sFirst $sLast').trim();
      sellerName = computed.isNotEmpty ? computed : sUser;
    }

    final sellerUserId = widget.ad['sellerUserId'] as int?;
    final isOwner =
        _currentUser != null && (sellerUserId == _currentUser!['id']);
    final isAdmin = _currentUser != null && _currentUser!['role'] == 'admin';
    final status = widget.ad['status']?.toString() ?? 'active';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isOwner && status == 'active')
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Marquer comme vendu',
              onPressed: _markAsSold,
            ),
          if (isOwner || isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Supprimer l\'annonce',
              onPressed: _deleteAd,
            ),
          IconButton(
            icon: Icon(Icons.share,
                color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage à venir')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite
                  ? Colors.red
                  : Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _photos.length,
                  onPageChanged: (i) => setState(() {
                    _currentImageIndex = i;
                  }),
                  itemBuilder: (context, index) {
                    final src = _photos[index];
                    String url = src;
                    if (src.contains('/upload/')) {
                      url = src.replaceFirst(
                          '/upload/', '/upload/f_auto,q_auto,w_1000/');
                    }
                    if (url.startsWith('http')) {
                      return Image.network(url, fit: BoxFit.cover);
                    } else {
                      return Image.file(File(src), fit: BoxFit.cover);
                    }
                  },
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${_photos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          priceDisplay,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.verified_user,
                            size: 18,
                            color:
                                Theme.of(context).hintColor.withOpacity(0.9)),
                        const SizedBox(width: 6),
                        Text(
                          'Transaction sécurisée',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.location_on,
                              size: 18, color: Color(0xFF00897B)),
                          label: Text(location),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Informations clés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(Icons.category, 'Catégorie', category),
                    _infoRow(Icons.color_lens, 'Couleur', color),
                    _infoRow(Icons.verified, 'État',
                        '$condition ${conditionPercentage != null ? "($conditionPercentage%)" : ""}'),
                    if (uniqueId != null && uniqueId.isNotEmpty)
                      _infoRow(
                          Icons.fingerprint,
                          category == 'Auto'
                              ? 'Châssis'
                              : category == 'Smartphone'
                                  ? 'IMEI/Série'
                                  : 'Série',
                          uniqueId),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.isEmpty ? 'Aucune description' : description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            sellerName.isEmpty
                                ? 'U'
                                : sellerName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(sellerName),
                        subtitle: Text(
                          _seller != null &&
                                  (_seller!['phone'] as String?) != null &&
                                  (_seller!['phone'] as String).isNotEmpty
                              ? 'Téléphone: ${_seller!['phone']}'
                              : 'Téléphone non renseigné',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _openInbox,
                child: const Text('Inbox'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (isOwner || status == 'sold') ? null : _openPaymentSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isOwner || status == 'sold')
                      ? Colors.grey
                      : const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(status == 'sold'
                    ? 'Déjà vendu'
                    : (isOwner ? 'Votre annonce' : 'Acheter')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).hintColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
