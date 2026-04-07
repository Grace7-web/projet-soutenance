import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';

class ConversationPage extends StatefulWidget {
  final Map<String, dynamic> conversation;
  const ConversationPage({super.key, required this.conversation});

  String get conversationId => conversation['id'].toString();

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _api.sendMessage(widget.conversation['id'].toString(), text);
    _controller.clear();
  }

  Future<void> _callSeller() async {
    final phone = widget.conversation['sellerPhone'] as String?;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversation['id'].toString())
        .collection('messages')
        .orderBy('at')
        .snapshots();

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    // ✅ CORRECTION LOGIQUE : Détecter l'autre participant
    // Si je suis l'acheteur (buyerUid), l'autre est le vendeur (sellerName)
    // Si je suis le vendeur (sellerUid), l'autre est l'acheteur (buyerName)
    final isBuyer = widget.conversation['buyerUid'] == myUid;
    
    final otherName = isBuyer 
        ? (widget.conversation['sellerName'] ?? 'Vendeur')
        : (widget.conversation['buyerName'] ?? 'Acheteur');

    final title = otherName.toString().trim().isNotEmpty
        ? otherName.toString()
        : 'Conversation';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if ((widget.conversation['sellerPhone'] as String?) != null)
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: _callSeller,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                // Marquer les messages reçus comme lus
                final myUid = FirebaseAuth.instance.currentUser?.uid;
                for (var doc in docs) {
                  final data = doc.data();
                  if (data['receiverId'] == myUid && data['read'] == false) {
                    doc.reference.update({'read': true});
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data();
                    final myUid = FirebaseAuth.instance.currentUser?.uid;
                    final isMine = m['senderUid'] == myUid;
                    return GestureDetector(
                      onLongPress: isMine
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer le message'),
                                  content: const Text(
                                      'Voulez-vous vraiment supprimer ce message ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Supprimer',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _api.deleteMessage(
                                    widget.conversation['id'].toString(),
                                    docs[index].id);
                              }
                            }
                          : null,
                      child: Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFF00897B)
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['text'] ?? '',
                                style: TextStyle(
                                  color: isMine ? Colors.white : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(m['at']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMine
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Votre message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                    ),
                    child: const Text('Envoyer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic at) {
    if (at == null) return '';
    DateTime dt;
    if (at is Timestamp) {
      dt = at.toDate();
    } else if (at is String) {
      dt = DateTime.parse(at);
    } else {
      return '';
    }
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
