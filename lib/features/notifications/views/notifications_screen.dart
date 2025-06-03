// lib/features/notifications/views/notifications_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      return Center(
        child: Text(
          'Non connecté',
          style: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.7)),
        ),
      );
    }

    // Stream des demandes d'ami en attente
    final pendingReqsStream = FirebaseFirestore.instance
        .collection('collaborations')
        .where('to', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    // Stream des notifications déjà créées
    final notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: me.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Couleurs dynamiques basées sur le thème
    final bgColor = theme.scaffoldBackgroundColor;
    final sectionTitleColor = theme.colorScheme.onBackground.withOpacity(0.7);
    final textPrimaryColor = theme.colorScheme.onSurface;
    final textSecondaryColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final textTertiaryColor = theme.colorScheme.onSurface.withOpacity(0.5);
    final dividerColor = theme.colorScheme.onBackground.withOpacity(0.3);

    // Couleurs des tuiles : on alterne surface / surfaceVariant du ColorScheme s’il existe
    final tileUnreadColor = theme.colorScheme.surfaceVariant ??
        (isDark ? Colors.grey[850]! : Colors.grey[200]!);
    final tileReadColor = theme.colorScheme.surface ??
        (isDark ? Colors.grey[800]! : Colors.grey[100]!);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        // On laisse AppBar prendre la couleur par défaut du thème
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pendingReqsStream,
        builder: (ctx, snapReq) {
          if (snapReq.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pendingDocs = snapReq.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: notificationsStream,
            builder: (ctx2, snapNotif) {
              if (snapNotif.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final notifDocs = snapNotif.data?.docs ?? [];

              final List<Widget> items = [];

              // --- Section "Demandes d'ami" ---
              if (pendingDocs.isNotEmpty) {
                items.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                    child: Text(
                      'Demandes d\'ami',
                      style: TextStyle(
                        color: sectionTitleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
                for (var doc in pendingDocs) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final fromUid = data['from'] as String? ?? '';
                  final timestamp = data['timestamp'] as Timestamp?;
                  final time = timestamp != null
                      ? DateFormat('HH:mm').format(timestamp.toDate())
                      : '';

                  items.add(
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(fromUid)
                          .get(),
                      builder: (ctx3, userSnap) {
                        if (!userSnap.hasData) return const SizedBox.shrink();
                        final udata =
                            userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        final name =
                            udata['displayName'] as String? ?? 'Utilisateur';

                        return Container(
                          color: tileUnreadColor,
                          child: ListTile(
                            leading: Icon(Icons.person_add,
                                color: theme.colorScheme.primary),
                            title: Text(
                              '$name vous a envoyé une demande',
                              style: TextStyle(color: textPrimaryColor),
                            ),
                            subtitle: Text(
                              time,
                              style: TextStyle(color: textSecondaryColor, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: theme.colorScheme.secondary),
                                  onPressed: () async {
                                    // Accepter la demande
                                    await doc.reference.update({'status': 'accepted'});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Vous êtes maintenant ami avec $name.',
                                          style: TextStyle(color: theme.colorScheme.onSecondary),
                                        ),
                                        backgroundColor: theme.colorScheme.secondary,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                                  onPressed: () async {
                                    // Refuser la demande
                                    await doc.reference.update({'status': 'refused'});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Demande d’ami de $name refusée.',
                                          style: TextStyle(color: theme.colorScheme.onError),
                                        ),
                                        backgroundColor: theme.colorScheme.error,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                items.add(Divider(color: dividerColor));
              }

              // --- Section "Autres notifications" ---
              if (notifDocs.isNotEmpty) {
                items.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
                    child: Text(
                      'Autres notifications',
                      style: TextStyle(
                        color: sectionTitleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
                for (var doc in notifDocs) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final title = data['title'] as String? ?? '';
                  final body = data['body'] as String? ?? '';
                  final ts = data['timestamp'] as Timestamp?;
                  final time = ts != null
                      ? DateFormat('HH:mm').format(ts.toDate())
                      : '';
                  final type = data['type'] as String? ?? '';
                  final read = data['read'] as bool? ?? false;

                  Icon leadingIcon;
                  switch (type) {
                    case 'friend_request':
                      leadingIcon = Icon(
                        Icons.person_add,
                        color: theme.colorScheme.primary,
                      );
                      break;
                    case 'friend_accepted':
                      leadingIcon = Icon(
                        Icons.person,
                        color: theme.colorScheme.secondary,
                      );
                      break;
                    default:
                      leadingIcon = Icon(
                        Icons.notifications,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      );
                  }

                  items.add(
                    Container(
                      color: read ? tileReadColor : tileUnreadColor,
                      child: ListTile(
                        leading: leadingIcon,
                        title: Text(
                          title,
                          style: TextStyle(color: textPrimaryColor),
                        ),
                        subtitle: Text(
                          body,
                          style: TextStyle(color: textSecondaryColor),
                        ),
                        trailing: Text(
                          time,
                          style: TextStyle(color: textTertiaryColor),
                        ),
                        onTap: () {
                          doc.reference.update({'read': true});
                        },
                      ),
                    ),
                  );
                }
              }

              // Si aucun élément à afficher
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'Aucune notification',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                );
              }

              return ListView(children: items);
            },
          );
        },
      ),
    );
  }
}
