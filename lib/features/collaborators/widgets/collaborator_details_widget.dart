// lib/features/collaborators/widgets/collaborator_details_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../main.dart'; // Pour AppColors

class CollaboratorDetailPanel extends StatefulWidget {
  final String collaboratorId;
  final String displayName;
  final VoidCallback onClose; // callback pour fermer le panneau

  const CollaboratorDetailPanel({
    Key? key,
    required this.collaboratorId,
    required this.displayName,
    required this.onClose,
  }) : super(key: key);

  @override
  _CollaboratorDetailPanelState createState() =>
      _CollaboratorDetailPanelState();
}

class _CollaboratorDetailPanelState extends State<CollaboratorDetailPanel> {
  Map<String, dynamic>? collaboratorData;
  List<Map<String, dynamic>> commonProjects = [];
  String? currentUserId;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchCollaboratorData();
    _fetchCommonProjects();
  }

  Future<void> _fetchCollaboratorData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.collaboratorId)
        .get();
    setState(() {
      collaboratorData = doc.data();
    });
  }

  Future<void> _fetchCommonProjects() async {
    if (currentUserId == null) return;
    final snapshot =
    await FirebaseFirestore.instance.collection('projects').get();

    final projects = snapshot.docs
        .map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      final collaborators = List<String>.from(data['collaborators'] ?? []);
      final ownerId = (data['ownerId'] as String?) ?? '';
      final isCol = collaborators.contains(widget.collaboratorId) ||
          ownerId == widget.collaboratorId;
      final isMe = collaborators.contains(currentUserId) ||
          ownerId == currentUserId;
      if (isCol && isMe) {
        data['id'] = doc.id;
        return data;
      }
      return null;
    })
        .where((e) => e != null)
        .cast<Map<String, dynamic>>()
        .toList();

    projects.sort((a, b) {
      final na = (a['name'] as String?) ?? '';
      final nb = (b['name'] as String?) ?? '';
      return na.compareTo(nb);
    });

    setState(() {
      commonProjects = projects;
    });
  }

  Future<void> _removeCollaborator() async {
    if (currentUserId == null) return;
    final me = currentUserId!;
    final them = widget.collaboratorId;

    setState(() {
      _removing = true;
    });

    // Supprimer tous les docs "accepted" entre me et them
    final batch = FirebaseFirestore.instance.batch();
    final snap1 = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('from', isEqualTo: me)
        .where('to', isEqualTo: them)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (var doc in snap1.docs) batch.delete(doc.reference);

    final snap2 = await FirebaseFirestore.instance
        .collection('collaborations')
        .where('from', isEqualTo: them)
        .where('to', isEqualTo: me)
        .where('status', isEqualTo: 'accepted')
        .get();
    for (var doc in snap2.docs) batch.delete(doc.reference);

    await batch.commit();

    setState(() {
      _removing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Collaborateur supprimé.'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Couleurs dynamiques
    final backgroundColor = AppColors.glassBackground;
    final onBackground = isLight ? Colors.white : theme.colorScheme.onBackground;
    final onSurface = isLight ? Colors.white : theme.colorScheme.onSurface;
    final dividerColor = onBackground.withOpacity(0.24);
    final iconColor = onBackground.withOpacity(0.7);
    final buttonColor = theme.colorScheme.error; // couleur d’erreur pour bouton
    final buttonTextColor = onSurface;
    final glassHeaderColor = AppColors.glassHeader;

    if (collaboratorData == null) {
      return Container(
        color: backgroundColor,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.blue),
          ),
        ),
      );
    }

    Widget _buildItemContainer(Widget child) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: glassHeaderColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
    }

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête : nom + bouton fermer
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: onBackground),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  Divider(color: dividerColor),
                  const SizedBox(height: 8),

                  // Avatar (dans container arrondi)
                  if (collaboratorData!['photoURL'] != null)
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                        NetworkImage(collaboratorData!['photoURL'] as String),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Détails utilisateur
                  Text(
                    'Détails',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: onBackground.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),

                  if (collaboratorData!['email'] != null)
                    _buildItemContainer(
                      Row(
                        children: [
                          Icon(Icons.email, color: iconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              collaboratorData!['email'] as String,
                              style: TextStyle(color: onBackground),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (collaboratorData!['username'] != null)
                    _buildItemContainer(
                      Row(
                        children: [
                          Icon(Icons.person, color: iconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              collaboratorData!['username'] as String,
                              style: TextStyle(color: onBackground),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (collaboratorData!['phoneNumber'] != null)
                    _buildItemContainer(
                      Row(
                        children: [
                          Icon(Icons.phone, color: iconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              collaboratorData!['phoneNumber'] as String,
                              style: TextStyle(color: onBackground),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (collaboratorData!['createdAt'] != null)
                    _buildItemContainer(
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: iconColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (collaboratorData!['createdAt'] as Timestamp)
                                  .toDate()
                                  .toLocal()
                                  .toString(),
                              style: TextStyle(color: onBackground),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  Text(
                    'Projets en commun',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: onBackground.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),

                  if (commonProjects.isEmpty)
                    _buildItemContainer(
                      Text(
                        'Aucun projet en commun',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: onBackground.withOpacity(0.7)),
                      ),
                    )
                  else
                    ...commonProjects.map((project) {
                      return _buildItemContainer(
                        Row(
                          children: [
                            Icon(Icons.work, color: iconColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                project['name'] as String? ?? 'Sans nom',
                                style: TextStyle(color: onBackground),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          // Bouton Supprimer ami
          Divider(color: dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _removing
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: buttonTextColor,
                  ),
                )
                    : Icon(Icons.person_remove, color: buttonTextColor),
                label: Text(
                  _removing ? 'Suppression...' : 'Supprimer cet ami',
                  style: TextStyle(color: buttonTextColor),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _removing
                    ? null
                    : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        backgroundColor: backgroundColor,
                        title: Text(
                          'Confirmer la suppression',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: onBackground),
                        ),
                        content: Text(
                          'Voulez-vous vraiment supprimer ${widget.displayName} ?',
                          style: TextStyle(color: onBackground),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(
                              'Annuler',
                              style:
                              TextStyle(color: onBackground),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              'Oui',
                              style: TextStyle(color: buttonColor),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await _removeCollaborator();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
