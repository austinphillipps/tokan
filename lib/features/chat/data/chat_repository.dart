// lib/features/chat/data/chat_repository.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  /// Stream paginé de messages d'une conversation.
  /// [limit] = nombre de messages chargés par batch.
  /// [startAfter] = dernier DocumentSnapshot reçu (pour pagination).
  Stream<List<QueryDocumentSnapshot>> messagesStream({
    required String conversationId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snap) => snap.docs);
  }

  /// Envoie un message texte.
  Future<void> sendText({
    required String conversationId,
    required String text,
  }) async {
    final now = FieldValue.serverTimestamp();

    // Référence au document de conversation
    final convRef = _firestore.collection('conversations').doc(conversationId);

    // Nouvelle référence de message auto-générée
    final msgRef = convRef.collection('messages').doc();

    // Batch pour atomiser la création/création de conversation + ajout de message
    final batch = _firestore.batch();

    // 1) Ajout du message
    batch.set(msgRef, {
      'senderId': currentUid,
      'type': 'text',
      'text': text,
      'sentAt': now,
      'status': 'sent',
    });

    // 2) Mise à jour ou création du doc conversation avec merge
    final convSnap = await convRef.get();
    final participants =
    List<String>.from(convSnap.data()?['participants'] ?? []);
    final others = participants.where((u) => u != currentUid).toList();

    batch.set(
      convRef,
      {
        'projectId': conversationId,
        'lastMessage': text,
        'lastMessageTime': now,
        'lastSenderId': currentUid,
        'unreadBy': FieldValue.arrayUnion(others),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Upload d'un fichier (image, audio, doc), renvoie l'URL publique.
  Future<String> uploadFile(File file, String conversationId) async {
    final ext = file.path.split('.').last;
    final ref = _storage
        .ref('conversations/$conversationId/${DateTime.now().millisecondsSinceEpoch}.$ext');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  /// Envoi d'un message avec pièce jointe.
  Future<void> sendFile({
    required String conversationId,
    required File file,
    required String type, // 'image', 'audio', 'file'
  }) async {
    final url = await uploadFile(file, conversationId);
    final now = FieldValue.serverTimestamp();

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final msgRef = convRef.collection('messages').doc();

    final batch = _firestore.batch();

    // 1) Ajout du message fichier
    batch.set(msgRef, {
      'senderId': currentUid,
      'type': type,
      'url': url,
      'sentAt': now,
      'status': 'sent',
    });

    // 2) Mise à jour ou création du doc conversation avec merge
    final convSnap = await convRef.get();
    final participants =
    List<String>.from(convSnap.data()?['participants'] ?? []);
    final others = participants.where((u) => u != currentUid).toList();

    batch.set(
      convRef,
      {
        'projectId': conversationId,
        'lastMessage': '[${type.toUpperCase()}]',
        'lastMessageTime': now,
        'lastSenderId': currentUid,
        'unreadBy': FieldValue.arrayUnion(others),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Met à jour le status de frappe (typing indicator).
  Future<void> setTyping(String conversationId, bool typing) {
    return _firestore
        .collection('typing')
        .doc(conversationId)
        .collection('users')
        .doc(currentUid)
        .set({'typing': typing});
  }

  /// Stream des typing statuses des autres.
  Stream<Map<String, bool>> typingStream(String conversationId) {
    return _firestore
        .collection('typing')
        .doc(conversationId)
        .collection('users')
        .snapshots()
        .map((snap) {
      final map = <String, bool>{};
      for (var doc in snap.docs) {
        if (doc.id == currentUid) continue;
        map[doc.id] = (doc.data()['typing'] as bool? ?? false);
      }
      return map;
    });
  }

  /// Envoie d'une réaction (emoji) à un message.
  Future<void> sendReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .collection('reactions')
        .doc(currentUid)
        .set({'emoji': emoji});
  }

  /// Stream des réactions d'un message.
  Stream<Map<String, String>> reactionsStream({
    required String conversationId,
    required String messageId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .collection('reactions')
        .snapshots()
        .map((snap) {
      final map = <String, String>{};
      for (var doc in snap.docs) {
        map[doc.id] = (doc.data()['emoji'] as String? ?? '');
      }
      return map;
    });
  }

  /// Marque une conversation comme lue par l'utilisateur courant.
  Future<void> markConversationRead(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .update({
      'unreadBy': FieldValue.arrayRemove([currentUid])
    });
  }

  /// Crée ou récupère l'ID d'une conversation entre deux utilisateurs.
  Future<String> createOrGetConversation(String otherUid) async {
    // 1) Cherche une conversation existante où currentUid est participant
    final existing = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .get();

    for (var doc in existing.docs) {
      final parts = List<String>.from(doc.data()['participants'] ?? []);
      if (parts.contains(otherUid)) return doc.id;
    }

    // 2) Sinon, on crée la conversation
    final ref = await _firestore.collection('conversations').add({
      'participants': [currentUid, otherUid],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'unreadBy': [],
    });
    return ref.id;
  }
}