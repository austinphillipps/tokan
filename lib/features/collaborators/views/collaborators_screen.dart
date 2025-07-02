// lib/features/collaborators/views/collaborators_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import du repository et de l’écran de chat pour démarrer une conversation
import '../../chat/data/chat_repository.dart';
import '../../chat/views/chat_screen.dart';

import '../widgets/collaborator_details_widget.dart';
import '../../../main.dart'; // Pour AppColors

class CollaboratorsPage extends StatefulWidget {
  const CollaboratorsPage({Key? key}) : super(key: key);

  @override
  State<CollaboratorsPage> createState() => _CollaboratorsPageState();
}

class _CollaboratorsPageState extends State<CollaboratorsPage> {
  String? selectedCollaboratorId;
  String? selectedCollaboratorName;

  // Controllers & filtres par onglet
  final _friendsSearchController = TextEditingController();
  String friendsSearch = '';

  final _allSearchController = TextEditingController();
  String allSearch = '';

  final _pendingSearchController = TextEditingController();
  String pendingSearch = '';

  List<String> acceptedIds = [];
  List<String> pendingIds = [];
  List<String> incomingIds = [];

  final _chatRepo = ChatRepository();

  @override
  void initState() {
    super.initState();
    _fetchCollaboratorStatuses();
  }

  @override
  void dispose() {
    _friendsSearchController.dispose();
    _allSearchController.dispose();
    _pendingSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCollaboratorStatuses() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    final acc = <String>[];
    final pend = <String>[];
    final inPend = <String>[];

    // — demandes acceptées où je suis "from"
    final outAcc = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('from', isEqualTo: me.uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (var doc in outAcc.docs) {
      final to = doc.data()['to'] as String?;
      if (to != null) acc.add(to);
    }

    // — demandes acceptées où je suis "to"
    final inAcc = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('to', isEqualTo: me.uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (var doc in inAcc.docs) {
      final from = doc.data()['from'] as String?;
      if (from != null) acc.add(from);
    }

    // — demandes pending où je suis "from"
    final outPend = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('from', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    for (var doc in outPend.docs) {
      final to = doc.data()['to'] as String?;
      if (to != null) pend.add(to);
    }

    // — demandes pending où je suis "to"
    final inPendSnap = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('to', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    for (var doc in inPendSnap.docs) {
      final from = doc.data()['from'] as String?;
      if (from != null) inPend.add(from);
    }

    setState(() {
      acceptedIds = acc;
      pendingIds = pend;
      incomingIds = inPend;
    });
  }

  Future<void> _sendCollabRequest(String targetUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || me.uid == targetUid) return;

    if (acceptedIds.contains(targetUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous êtes déjà collaborateurs.')),
      );
      return;
    }
    if (pendingIds.contains(targetUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre demande est déjà en attente.')),
      );
      return;
    }
    if (incomingIds.contains(targetUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cet utilisateur vous a déjà envoyé une demande.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('collaborations').add({
      'from': me.uid,
      'to': targetUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _fetchCollaboratorStatuses();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Demande envoyée.')));
  }

  Future<void> _acceptIncomingRequest(String fromUid) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('from', isEqualTo: fromUid)
        .where('to', isEqualTo: me.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({'status': 'accepted'});
    }
    await _fetchCollaboratorStatuses();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Demande acceptée.')));
  }

  Future<void> _respondToRequest(String docId, bool accept) async {
    await FirebaseFirestore.instance
        .collection('collaborations')
        .doc(docId)
        .update({'status': accept ? 'accepted' : 'refused'});
    await _fetchCollaboratorStatuses();
  }

  /// Ouvre (ou crée) la conversation avec [friendUid], puis navigue vers ChatScreen
  Future<void> _openChat(String friendUid, String friendName) async {
    final convId = await _chatRepo.createOrGetConversation(friendUid);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convId,
          friendName: friendName,
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getAcceptedCollaborators(
      String currentUid) {
    return FirebaseFirestore.instance
        .collection('collaborations')
        .where(
      Filter.or(
        Filter('from', isEqualTo: currentUid),
        Filter('to', isEqualTo: currentUid),
      ),
    )
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
      final list = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final from = data['from'] as String?;
        final to = data['to'] as String?;
        if (from == null || to == null) continue;
        if (from == currentUid || to == currentUid) {
          final other = (from == currentUid ? to : from)!;
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

  void _showAddCollaboratorDialog() {
    final _addController = TextEditingController();
    String addSearch = '';
    final meUid = FirebaseAuth.instance.currentUser!.uid;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Ajouter un collaborateur'),
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          titleTextStyle: Theme.of(ctx)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(ctx).colorScheme.onSurface),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── TextField arrondi ───
              TextField(
                controller: _addController,
                decoration: InputDecoration(
                  hintText: 'Chercher par nom ou username',
                  prefixIcon: const Icon(Icons.search),
                  hintStyle: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: Theme.of(ctx).colorScheme.background,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                      Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                      Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.blue),
                  ),
                ),
                onChanged: (v) => setSt(() {
                  addSearch = v.trim().toLowerCase();
                }),
                style:
                TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('displayName')
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.blue),
                        ),
                      );
                    }

                    final results = snap.data!.docs.where((doc) {
                      if (doc.id == meUid) return false;
                      final d = doc.data()! as Map<String, dynamic>;
                      final name =
                      (d['displayName'] ?? '').toString().toLowerCase();
                      final username =
                      (d['username'] ?? '').toString().toLowerCase();
                      return name.contains(addSearch) ||
                          username.contains(addSearch);
                    }).toList();

                    if (addSearch.isEmpty) {
                      return Center(
                        child: Text(
                          'Tapez un nom ou username…',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }
                    if (results.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun résultat',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (ctx, i) {
                        final doc = results[i];
                        final d = doc.data()! as Map<String, dynamic>;
                        final uid = doc.id;
                        final name = d['displayName'] ?? 'Utilisateur';
                        final username = d['username'] ?? '';
                        final already = acceptedIds.contains(uid);
                        final out = pendingIds.contains(uid);
                        final inc = incomingIds.contains(uid);

                        late Widget trailing;
                        if (already) {
                          trailing = const Text(
                            'Déjà',
                            style: TextStyle(color: Colors.green),
                          );
                        } else if (inc) {
                          trailing = IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () {
                              _acceptIncomingRequest(uid);
                              Navigator.of(ctx).pop();
                            },
                          );
                        } else if (out) {
                          trailing = const Text(
                            'En attente',
                            style: TextStyle(color: Colors.orange),
                          );
                        } else {
                          trailing = ElevatedButton(
                            onPressed: () {
                              _sendCollabRequest(uid);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              foregroundColor: Colors.white,
                            ),
                          );
                        }

                        return ListTile(
                          title: Text(
                            name,
                            style: TextStyle(
                                color: Theme.of(ctx).colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            '@$username',
                            style: TextStyle(
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7)),
                          ),
                          trailing: trailing,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Fermer',
                style:
                TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Non connecté'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Couleur des labels non sélectionnés
    final unselectedColor = isDark ? Colors.white70 : Colors.black54;
    // Couleur des labels sélectionnés
    final selectedColor = AppColors.blue;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.glassBackground,
        appBar: AppBar(
          backgroundColor: AppColors.glassHeader,
          elevation: 0,
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: AppColors.glassHeader,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      isScrollable: true,
                      indicatorColor: selectedColor,
                      labelColor: selectedColor,
                      unselectedLabelColor: unselectedColor,
                      tabs: const [
                        Tab(text: 'Amis'),
                        Tab(text: 'En ligne'),
                        Tab(text: 'Tous'),
                        Tab(text: 'En attente'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    onPressed: _showAddCollaboratorDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Row(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // ─── Amis ───
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _friendsSearchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher parmi vos amis',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: AppColors.glassBackground,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.blue),
                            ),
                          ),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground),
                          onChanged: (v) => setState(
                                  () => friendsSearch = v.trim().toLowerCase()),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _getAcceptedCollaborators(user.uid),
                          builder: (ctx, snap) {
                            if (!snap.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.blue),
                                ),
                              );
                            }
                            final list = snap.data!
                                .where((c) => (c['displayName'] as String)
                                .toLowerCase()
                                .contains(friendsSearch))
                                .toList();
                            if (list.isEmpty) {
                              return Center(
                                child: Text(
                                  'Aucun ami trouvé',
                                  style: TextStyle(color: unselectedColor),
                                ),
                              );
                            }
                            return ListView.builder(
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              itemCount: list.length,
                              itemBuilder: (ctx, i) {
                                final c = list[i];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassHeader,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    tileColor: Colors.transparent,
                                    leading: Icon(
                                      Icons.person,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                    ),
                                    title: Text(
                                      c['displayName'] as String,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.message_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground),
                                      onPressed: () => _openChat(
                                        c['uid'] as String,
                                        c['displayName'] as String,
                                      ),
                                    ),
                                    onTap: () => setState(() {
                                      selectedCollaboratorId =
                                      c['uid'] as String;
                                      selectedCollaboratorName =
                                      c['displayName'] as String;
                                    }),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // ─── En ligne ───
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _friendsSearchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher amis en ligne',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: AppColors.glassBackground,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.blue),
                            ),
                          ),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground),
                          onChanged: (v) => setState(
                                  () => friendsSearch = v.trim().toLowerCase()),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _getAcceptedCollaborators(user.uid),
                          builder: (ctx, snap) {
                            if (!snap.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.blue),
                                ),
                              );
                            }
                            final list = snap.data!
                                .where((c) =>
                            c['isOnline'] == true &&
                                (c['displayName'] as String)
                                    .toLowerCase()
                                    .contains(friendsSearch))
                                .toList();
                            if (list.isEmpty) {
                              return Center(
                                child: Text(
                                  'Aucun ami en ligne',
                                  style: TextStyle(color: unselectedColor),
                                ),
                              );
                            }
                            return ListView.builder(
                              padding:
                              const EdgeInsets.symmetric(vertical: 8),
                              itemCount: list.length,
                              itemBuilder: (ctx, i) {
                                final c = list[i];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassHeader,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    tileColor: Colors.transparent,
                                    leading: const Icon(Icons.circle,
                                        color: Colors.greenAccent),
                                    title: Text(
                                      c['displayName'] as String,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.message_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground),
                                      onPressed: () => _openChat(
                                        c['uid'] as String,
                                        c['displayName'] as String,
                                      ),
                                    ),
                                    onTap: () => setState(() {
                                      selectedCollaboratorId =
                                      c['uid'] as String;
                                      selectedCollaboratorName =
                                      c['displayName'] as String;
                                    }),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // ─── Tous ───
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _allSearchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher tous les utilisateurs',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: AppColors.glassBackground,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.blue),
                            ),
                          ),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground),
                          onChanged: (v) =>
                              setState(() => allSearch = v.trim().toLowerCase()),
                        ),
                      ),
                      Expanded(child: _buildAllUsersList(user.uid)),
                    ],
                  ),

                  // ─── En attente ───
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _pendingSearchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher demandes en attente',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: AppColors.glassBackground,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.blue),
                            ),
                          ),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground),
                          onChanged: (v) =>
                              setState(() => pendingSearch = v.trim().toLowerCase()),
                        ),
                      ),
                      Expanded(child: _buildPendingList(user.uid)),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Panneau détail ───
            if (selectedCollaboratorId != null)
              Container(
                width: 300,
                color: isDark ? AppColors.darkBackground : Colors.white,
                child: CollaboratorDetailPanel(
                  collaboratorId: selectedCollaboratorId!,
                  displayName: selectedCollaboratorName!,
                  onClose: () => setState(() {
                    selectedCollaboratorId = null;
                    selectedCollaboratorName = null;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllUsersList(String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedTxtColor = isDark ? Colors.white70 : Colors.black54;
    final onBgColor = Theme.of(context).colorScheme.onBackground;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('displayName')
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs.where((doc) {
          if (doc.id == uid) return false;
          final d = doc.data()! as Map<String, dynamic>;
          final name = (d['displayName'] ?? '').toString().toLowerCase();
          final username = (d['username'] ?? '').toString().toLowerCase();
          return name.contains(allSearch) || username.contains(allSearch);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(color: unselectedTxtColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final d = doc.data()! as Map<String, dynamic>;
            final target = doc.id;
            final name = d['displayName'] ?? 'Utilisateur';
            final username = d['username'] ?? '';
            final already = acceptedIds.contains(target);
            final pend = pendingIds.contains(target);
            final inc = incomingIds.contains(target);

            late Widget trailing;
            if (already) {
              trailing = Text('Déjà',
                  style: TextStyle(color: Colors.greenAccent));
            } else if (inc) {
              trailing = IconButton(
                icon: const Icon(Icons.check, color: Colors.greenAccent),
                onPressed: () => _acceptIncomingRequest(target),
              );
            } else if (pend) {
              trailing = Text('En attente',
                  style: TextStyle(color: Colors.orangeAccent));
            } else {
              trailing = ElevatedButton(
                onPressed: () => _sendCollabRequest(target),
                child: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassHeader,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                tileColor: Colors.transparent,
                title: Text(
                  name,
                  style: TextStyle(color: onBgColor),
                ),
                subtitle: Text(
                  '@$username',
                  style: TextStyle(color: unselectedTxtColor),
                ),
                trailing: trailing,
                onTap: () => setState(() {
                  selectedCollaboratorId = target;
                  selectedCollaboratorName = name;
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingList(String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedTxtColor = isDark ? Colors.white70 : Colors.black54;
    final onBgColor = Theme.of(context).colorScheme.onBackground;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('collaborations')
          .where('to', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final reqs = snap.data!.docs;
        if (reqs.isEmpty) {
          return Center(
            child: Text(
              'Aucune demande en attente',
              style: TextStyle(color: unselectedTxtColor),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: reqs.length,
          itemBuilder: (ctx, i) {
            final docReq = reqs[i];
            final fromId = (docReq.data()! as Map<String, dynamic>)['from'] as String;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(fromId).get(),
              builder: (ctx, userSnap) {
                if (!userSnap.hasData) return const SizedBox.shrink();
                final ud = userSnap.data!.data()! as Map<String, dynamic>;
                final name = ud['displayName'] ?? 'Utilisateur';
                if (!name.toLowerCase().contains(pendingSearch)) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.glassHeader,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    tileColor: Colors.transparent,
                    leading: Icon(Icons.mail, color: onBgColor.withOpacity(0.7)),
                    title: Text(name, style: TextStyle(color: onBgColor)),
                    subtitle: Text('Souhaite collaborer',
                        style: TextStyle(color: onBgColor.withOpacity(0.7))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _respondToRequest(docReq.id, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _respondToRequest(docReq.id, false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}