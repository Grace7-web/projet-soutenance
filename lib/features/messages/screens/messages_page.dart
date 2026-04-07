import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'conversation_page.dart';
import '../../../services/api_service.dart';

class MessagesPage extends StatelessWidget {
  final ApiService _api = ApiService();

  MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'local';
    final stream = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        var docs = snapshot.data?.docs ?? [];
        docs.sort((a, b) {
          final ta = a.data()['lastMessageAt'];
          final tb = b.data()['lastMessageAt'];
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          try {
            return (tb as Timestamp).compareTo(ta as Timestamp);
          } catch (_) {
            return 0;
          }
        });
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: const Text('Messages',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: snapshot.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Erreur de chargement des messages',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                )
              : docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline,
                              size: 100,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune conversation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final c = {'id': doc.id, ...doc.data()};

                        // ✅ CORRECTION LOGIQUE : Détecter l'autre participant
                        // Si je suis l'acheteur (buyerUid), l'autre est le vendeur (sellerName)
                        // Si je suis le vendeur (sellerUid), l'autre est l'acheteur (buyerName)
                        final isBuyer = c['buyerUid'] == myUid;
                        
                        final otherName = isBuyer 
                            ? (c['sellerName'] ?? 'Vendeur')
                            : (c['buyerName'] ?? 'Acheteur');

                        final title = otherName.toString().trim().isNotEmpty
                            ? otherName.toString()
                            : 'Conversation';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF00897B),
                            child: Text(
                              title[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            (c['lastMessageText'] as String?) ?? 'Aucun message',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatLastMessageTime(c['lastMessageAt']),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ConversationPage(conversation: c),
                              ),
                            );
                          },
                          onLongPress: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Supprimer la conversation'),
                                content: const Text('Voulez-vous vraiment supprimer cette conversation et tous ses messages ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                               await _api.deleteConversation(doc.id);
                             }
                          },
                        );
                      },
                    ),
        );
      },
    );
  }

  String _formatLastMessageTime(dynamic at) {
    if (at == null) return '';
    DateTime dt;
    if (at is Timestamp) {
      dt = at.toDate();
    } else if (at is String) {
      dt = DateTime.parse(at);
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}
