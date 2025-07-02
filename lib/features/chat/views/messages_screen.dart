// lib/pages/messages_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../collaborators/views/collaborators_screen.dart'; // pour _getAcceptedCollaborators
import '../../../features/chat/data/chat_repository.dart';
import '../../../features/chat/views/chat_screen.dart';
import '../../../main.dart'; // pour AppColors

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with TickerProviderStateMixin {
  String? selectedConversationId;
  String? selectedFriendName;

  late final TabController _leftTabController;
  final _chatRepo = ChatRepository();

  @override
  void initState() {
    super.initState();
    _leftTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _leftTabController.dispose();
    super.dispose();
  }

  /// Récupère la liste des collaborateurs acceptés (amis)
  Stream<List<Map<String, dynamic>>> _getAcceptedCollaborators(String meUid) {
    return FirebaseFirestore.instance
        .collection('collaborations')
        .where(
      Filter.or(
        Filter('from', isEqualTo: meUid),
        Filter('to', isEqualTo: meUid),
      ),
    )
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snap) async {
      final list = <Map<String, dynamic>>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        final from = data['from'] as String?;
        final to = data['to'] as String?;
        if (from == null || to == null) continue;
        if (from == meUid || to == meUid) {
          final other = (from == meUid ? to : from)!;
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(other)
              .get();
          if (!userDoc.exists) continue;
          final ud = userDoc.data()!;
          list.add({
            'uid': other,
            'displayName': ud['displayName'] ?? 'Utilisateur',
            'isOnline': ud['isOnline'] ?? false,
          });
        }
      }
      return list;
    });
  }

  Future<void> _openConversationWith(String friendUid, String friendName) async {
    final convId = await _chatRepo.createOrGetConversation(friendUid);
    setState(() {
      selectedConversationId = convId;
      selectedFriendName = friendName;
    });
    // Bascule sur l'onglet "Discussions"
    _leftTabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      return const Center(child: Text('Non connecté'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // On remplace le fond du panneau gauche par un verre sombre
    final leftPanelColor = AppColors.glassBackground;

    // Couleur du texte dans la liste
    final primaryTextColor = Theme.of(context).colorScheme.onBackground;
    final secondaryTextColor = primaryTextColor.withOpacity(0.7);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            // ─── Panneau de gauche ───
            Container(
              width: 280,
              color: leftPanelColor,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Onglets « Amis » / « Discussions »
                  Container(
                    color: AppColors.glassHeader,
                    child: TabBar(
                      controller: _leftTabController,
                      indicatorColor: AppColors.blue,
                      labelColor: primaryTextColor,
                      unselectedLabelColor: primaryTextColor.withOpacity(0.6),
                      tabs: const [
                        Tab(icon: Icon(Icons.group), text: 'Amis'),
                        Tab(icon: Icon(Icons.chat), text: 'Discussions'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Contenu des onglets
                  Expanded(
                    child: TabBarView(
                      controller: _leftTabController,
                      children: [
                        // ─── Onglet Amis ───
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _getAcceptedCollaborators(me.uid),
                          builder: (ctx, snap) {
                            if (!snap.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(AppColors.blue),
                                ),
                              );
                            }
                            final friends = snap.data!;
                            if (friends.isEmpty) {
                              return Center(
                                child: Text(
                                  'Aucun collaborateur trouvé',
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: friends.length,
                              itemBuilder: (ctx, i) {
                                final f = friends[i];
                                return ListTile(
                                  leading: Icon(
                                    Icons.person,
                                    color: f['isOnline'] == true
                                        ? Colors.greenAccent
                                        : primaryTextColor,
                                  ),
                                  title: Text(
                                    f['displayName'],
                                    style: TextStyle(color: primaryTextColor),
                                  ),
                                  onTap: () => _openConversationWith(
                                    f['uid'] as String,
                                    f['displayName'] as String,
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // ─── Onglet Discussions ───
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('conversations')
                              .where('participants', arrayContains: me.uid)
                              .snapshots(),
                          builder: (ctx, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(AppColors.blue),
                                ),
                              );
                            }
                            if (snap.hasError) {
                              return Center(
                                child: Text(
                                  'Erreur : ${snap.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }
                            final docs = snap.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'Aucune conversation',
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                              );
                            }
                            // Tri descendant par lastMessageTime
                            docs.sort((a, b) {
                              final ta = (a.data() as Map)['lastMessageTime'] as Timestamp?;
                              final tb = (b.data() as Map)['lastMessageTime'] as Timestamp?;
                              final da = ta?.toDate() ?? DateTime(0);
                              final db = tb?.toDate() ?? DateTime(0);
                              return db.compareTo(da);
                            });
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (ctx, i) {
                                final doc = docs[i];
                                final data = doc.data()! as Map<String, dynamic>;
                                final convId = doc.id;
                                final parts = List<String>.from(data['participants'] ?? []);
                                final otherUid = parts.firstWhere(
                                      (u) => u != me.uid,
                                  orElse: () => me.uid,
                                );
                                final lastMsg = data['lastMessage'] as String? ?? '';
                                final ts = data['lastMessageTime'] as Timestamp?;
                                final timeLabel = ts != null
                                    ? TimeOfDay.fromDateTime(ts.toDate()).format(context)
                                    : '';

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(otherUid)
                                      .get(),
                                  builder: (ctx, userSnap) {
                                    if (!userSnap.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    final udata = userSnap.data!.data()! as Map<String, dynamic>;
                                    final friendName = udata['displayName'] as String? ?? 'Utilisateur';

                                    return ListTile(
                                      selected: convId == selectedConversationId,
                                      selectedTileColor: isDark
                                          ? AppColors.darkGreyBackground
                                          : Colors.grey.shade200,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.blue,
                                        child: Text(
                                          friendName.isNotEmpty
                                              ? friendName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(
                                        friendName,
                                        style: TextStyle(color: primaryTextColor),
                                      ),
                                      subtitle: Text(
                                        lastMsg,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: secondaryTextColor),
                                      ),
                                      trailing: Text(
                                        timeLabel,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap: () => setState(() {
                                        selectedConversationId = convId;
                                        selectedFriendName = friendName;
                                      }),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Séparateur ───
            VerticalDivider(
              width: 1,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
            ),

            // ─── Zone de chat ───
            Expanded(
              child: selectedConversationId != null
                  ? ChatScreen(
                conversationId: selectedConversationId!,
                friendName: selectedFriendName!,
              )
                  : Center(
                child: Text(
                  'Sélectionnez une conversation',
                  style: TextStyle(color: secondaryTextColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}