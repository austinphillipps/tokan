// lib/services/notification_service.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
  FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _incomingReqSub;
  StreamSubscription<QuerySnapshot>? _acceptedReqSub;
  StreamSubscription<QuerySnapshot>? _messageConvSub;

  Future<void> init() async {
    // Initialisation des notifications locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const windowsSettings = WindowsInitializationSettings(
      appName: 'tokan',
      appUserModelId: 'com.tokan.tokan',
      guid: '00000000-0000-0000-0000-000000000000',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      windows: windowsSettings,
    );

    await _localNotif.initialize(initSettings);

    // Enregistrement du token FCM pour Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
      }
    }

    _listenFriendRequests();
    _listenFriendAcceptances();
    _listenMessages();
  }

  void _listenFriendRequests() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _incomingReqSub = _firestore
        .collection('collaborations')
        .where('to', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          final fromUid = data?['from'] as String?;
          if (fromUid == null) continue;

          _firestore.collection('users').doc(fromUid).get().then((userDoc) {
            final name = userDoc.data()?['displayName'] as String? ?? 'Un utilisateur';

            // Enregistrer en base
            _firestore.collection('notifications').add({
              'recipientId': uid,
              'type': 'friend_request',
              'title': 'Nouvelle demande d’ami',
              'body': '$name vous a envoyé une demande d’ami.',
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
            });

            // Afficher notification locale
            _localNotif.show(
              0,
              'Nouvelle demande d’ami',
              '$name vous a envoyé une demande d’ami.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'friend_request_channel',
                  'Demandes d’amis',
                  channelDescription: 'Nouvelles demandes d’ami',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                windows: WindowsNotificationDetails(),
              ),
            );
          });
        }
      }
    });
  }

  void _listenFriendAcceptances() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _acceptedReqSub = _firestore
        .collection('collaborations')
        .where('from', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          final toUid = data?['to'] as String?;
          if (toUid == null) continue;

          _firestore.collection('users').doc(toUid).get().then((userDoc) {
            final name = userDoc.data()?['displayName'] as String? ?? 'Un utilisateur';

            _firestore.collection('notifications').add({
              'recipientId': uid,
              'type': 'friend_accepted',
              'title': 'Demande d’ami acceptée',
              'body': '$name a accepté votre demande d’ami.',
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
            });

            _localNotif.show(
              1,
              'Demande d’ami acceptée',
              '$name a accepté votre demande d’ami.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'friend_accept_channel',
                  'Acceptations d’amis',
                  channelDescription: 'Acceptations de demandes d’ami',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                windows: WindowsNotificationDetails(),
              ),
            );
          });
        }
      }
    });
  }

  void _listenMessages() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _messageConvSub = _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          final sender = data?['lastSenderId'] as String?;
          final msg = data?['lastMessage'] as String? ?? '';
          if (sender == null || sender == uid) continue;

          _firestore.collection('notifications').add({
            'recipientId': uid,
            'type': 'message',
            'title': 'Nouveau message',
            'body': msg,
            'conversationId': change.doc.id,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });

          _localNotif.show(
            2,
            'Nouveau message',
            msg,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'message_channel',
                'Messages',
                channelDescription: 'Nouveaux messages',
                importance: Importance.max,
                priority: Priority.high,
              ),
              windows: WindowsNotificationDetails(),
            ),
          );
        }
      }
    });
  }

  /// Affiche une notification personnalisée depuis l'extérieur (ex : mise à jour)
  Future<void> showCustomNotification(String title, String body) async {
    await _localNotif.show(
      999,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'update_channel',
          'Mises à jour',
          channelDescription: 'Notifications de mise à jour logicielle',
          importance: Importance.high,
          priority: Priority.high,
        ),
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  void dispose() {
    _incomingReqSub?.cancel();
    _acceptedReqSub?.cancel();
    _messageConvSub?.cancel();
  }
}
