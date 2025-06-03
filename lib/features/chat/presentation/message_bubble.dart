// lib/features/chat/presentation/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final QueryDocumentSnapshot messageDoc;
  final String conversationId;

  const MessageBubble({
    Key? key,
    required this.messageDoc,
    required this.conversationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = messageDoc.data()! as Map<String, dynamic>;
    final String senderId = data['senderId'] as String? ?? '';
    final String messageText = data['text'] as String? ?? '';

    // on supporte à la fois 'timestamp' et 'createdAt'
    final rawTs = data['timestamp'] ?? data['createdAt'];
    Timestamp? ts;
    if (rawTs is Timestamp) {
      ts = rawTs;
    }
    final String timeString = ts != null
        ? DateFormat('HH:mm').format(ts.toDate())
        : '';

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnap.data!.data()!;
        final String username = userData['username'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bulle ronde à gauche
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 12),

              // Colonne : nom+heure, puis message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne nom + heure
                    Row(
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (timeString.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Texte du message
                    Text(
                      messageText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
