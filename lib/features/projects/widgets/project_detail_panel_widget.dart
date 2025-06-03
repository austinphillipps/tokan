// lib/features/projects/widgets/project_detail_panel_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/providers/plugin_provider.dart';
import '../../../plugins/stock/views/stock_screen.dart';
import '../../../plugins/stock/views/commande_screen.dart'; // IMPORTER l’écran Commandes
import '../models/project_models.dart';
import '../../tasks/views/tasks_screen.dart';
import 'discussion_screen.dart';
import '../../../main.dart'; // pour AppColors
import '../views/project_settings_screen.dart';

class ProjectDetailPanel extends StatefulWidget {
  final Project project;
  final void Function(Project) onSave;
  final VoidCallback onClose;
  /// 0 = Informations, 1 = Tâches, 2 = Discussion générale, 3 = Stock (si activé), 4 = Commandes (si activé)
  final int initialTab;

  const ProjectDetailPanel({
    Key? key,
    required this.project,
    required this.onSave,
    required this.onClose,
    this.initialTab = 1,
  }) : super(key: key);

  @override
  _ProjectDetailPanelState createState() => _ProjectDetailPanelState();
}

class _ProjectDetailPanelState extends State<ProjectDetailPanel> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController
  _nameCtrl,
      _descCtrl,
      _objCtrl,
      _collaboratorSearchController;
  late List<Collaborator> _collaborators;
  late Color _selectedColor;
  bool _isEditingName = false;
  late FocusNode _nameFocus;

  /// Flux de vos amis “accepted”
  late Stream<List<Map<String, String>>> _friendsStream;
  String collaboratorSearch = '';

  /// Pour stocker les displayName de chaque collaborateur
  final Map<String, String> _collaboratorNames = {};

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.project.name)
      ..addListener(_autoSave);
    _descCtrl = TextEditingController(text: widget.project.description)
      ..addListener(_autoSave);
    _objCtrl = TextEditingController(text: widget.project.objective ?? '')
      ..addListener(_autoSave);

    _collaboratorSearchController = TextEditingController();
    _collaborators = List.from(widget.project.collaborators);
    _selectedColor = widget.project.color != null
        ? Color(int.parse(widget.project.color!, radix: 16))
        : AppColors.blue;

    _nameFocus = FocusNode()
      ..addListener(() {
        if (!_nameFocus.hasFocus && _isEditingName) {
          setState(() => _isEditingName = false);
        }
      });

    _friendsStream = _getFriends();
    _loadCollaboratorNames();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _objCtrl.dispose();
    _collaboratorSearchController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  /// Met à jour automatiquement le projet parent
  void _autoSave() {
    final raw = _nameCtrl.text.trim();
    final name = raw.isNotEmpty
        ? '${raw[0].toUpperCase()}${raw.substring(1)}'
        : raw;

    final updated = widget.project.copyWith(
      name: name,
      description: _descCtrl.text.trim(),
      objective:
      _objCtrl.text.trim().isNotEmpty ? _objCtrl.text.trim() : null,
      collaborators: _collaborators,
      color: _selectedColor.value.toRadixString(16),
      plugins: widget.project.plugins, // inchangé ici
    );
    widget.onSave(updated);
  }

  /// Récupère la liste de vos « amis » Firestore (status == accepted)
  Stream<List<Map<String, String>>> _getFriends() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('collaborations')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snap) async {
      final List<Map<String, String>> list = [];
      for (var d in snap.docs) {
        final data = d.data();
        final from = data['from'] as String?;
        final to = data['to'] as String?;
        if (from == null || to == null) continue;
        final other = (from == user.uid) ? to : (to == user.uid ? from : null);
        if (other == null) continue;
        final udoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(other)
            .get();
        if (!udoc.exists) continue;
        final ud = udoc.data()!;
        list.add({
          'uid': other,
          'displayName': ud['displayName'] as String? ?? 'Utilisateur',
        });
      }
      return list;
    });
  }

  /// Charge en batch les displayName de tous les collaborateurs initiaux
  Future<void> _loadCollaboratorNames() async {
    for (var c in _collaborators) {
      if (!_collaboratorNames.containsKey(c.uid)) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(c.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          _collaboratorNames[c.uid] =
              (data['displayName'] as String?)?.trim() ?? c.uid;
        } else {
          _collaboratorNames[c.uid] = c.uid;
        }
      }
    }
    setState(() {});
  }

  /// Affiche le dialogue de recherche / ajout d’ami
  void _showAddCollaboratorDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctxDialog, setStateDialog) {
          final theme = Theme.of(context);
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: Text('Ajouter un collaborateur',
                style: TextStyle(color: theme.colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _collaboratorSearchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    prefixIcon: const Icon(Icons.search),
                    hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setStateDialog(
                          () => collaboratorSearch = v.trim().toLowerCase()),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: StreamBuilder<List<Map<String, String>>>(
                    stream: _friendsStream,
                    builder: (_, snap) {
                      if (!snap.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary),
                          ),
                        );
                      }
                      final results = snap.data!
                          .where((f) =>
                          f['displayName']!
                              .toLowerCase()
                              .contains(collaboratorSearch))
                          .where((f) =>
                      !_collaborators.any((c) => c.uid == f['uid']))
                          .toList();
                      if (results.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucun utilisateur trouvé',
                            style:
                            TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final f = results[i];
                          return ListTile(
                            title: Text(
                              f['displayName']!,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface),
                            ),
                            onTap: () {
                              setState(() {
                                _collaborators.add(
                                    Collaborator(uid: f['uid']!, role: 'viewer'));
                              });
                              _autoSave();
                              Navigator.of(ctx).pop();
                            },
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
                  'Annuler',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Ouvre un sélecteur de couleur et _autoSave
  Future<void> _pickColor() async {
    const options = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: Wrap(
          spacing: 8,
          children: options
              .map((c) => GestureDetector(
            onTap: () => Navigator.of(context).pop(c),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
              ),
            ),
          ))
              .toList(),
        ),
      ),
    );
    if (chosen != null) {
      setState(() => _selectedColor = chosen);
      _autoSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerBg =
    isDark ? AppColors.darkGreyBackground : theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    // PluginProvider (pour vérifier si Stock & Commandes est installé globalement)
    final isStockInstalled =
    Provider.of<PluginProvider>(context).isInstalled('stock');

    // On écoute en direct la collection “projects” pour le document courant
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.project.id)
          .snapshots(),
      builder: (context, snapshot) {
        // Si pas encore de données, on se base sur widget.project.plugins
        List<String> livePlugins = widget.project.plugins ?? [];
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          livePlugins = (data['plugins'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
              [];
        }

        // 1. Construire la liste d’onglets selon l’état en direct
        final baseTabs = <Tab>[
          const Tab(text: 'Informations'),
          const Tab(text: 'Tâches'),
          const Tab(text: 'Discussion générale'),
        ];
        final baseViews = <Widget>[
          // Onglet “Informations”
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nom du projet
                  TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(color: onSurface),
                    decoration: InputDecoration(
                      labelText: 'Nom du projet',
                      labelStyle: TextStyle(color: onSurface.withOpacity(0.7)),
                      border: UnderlineInputBorder(
                        borderSide:
                        BorderSide(color: onSurface.withOpacity(0.3)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                        BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                    cursorColor: theme.colorScheme.primary,
                    onChanged: (_) => _autoSave(),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  // Description
                  TextFormField(
                    controller: _descCtrl,
                    style: TextStyle(color: onSurface),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle:
                      TextStyle(color: onSurface.withOpacity(0.7)),
                      filled: true,
                      fillColor:
                      isDark ? AppColors.darkGreyBackground : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: onSurface.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                        BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _autoSave(),
                  ),
                  const SizedBox(height: 16),
                  // Couleur du libellé
                  Text(
                    'Couleur du libellé',
                    style: TextStyle(color: onSurface),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickColor,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Onglet “Tâches”
          TasksPage(projectId: widget.project.id),

          // Onglet “Discussion générale”
          ProjectDiscussionScreen(projectId: widget.project.id),
        ];

        // 2. Si le plugin Stock est installé ET 'stock' dans livePlugins, on ajoute “Stock”
        final hasStockActivated =
            isStockInstalled && livePlugins.contains('stock');
        if (hasStockActivated) {
          baseTabs.add(const Tab(text: 'Stock'));
          baseViews.add(const StockScreen());
        }

        // 3. Si le plugin Stock est installé ET 'commande' dans livePlugins, on ajoute “Commandes”
        final hasCommandeActivated =
            isStockInstalled && livePlugins.contains('commande');
        if (hasCommandeActivated) {
          baseTabs.add(const Tab(text: 'Commandes'));
          baseViews.add(const CommandeScreen());
        }

        // 4. On enveloppe la partie onglets dans un DefaultTabController
        return DefaultTabController(
          length: baseTabs.length,
          initialIndex:
          (widget.initialTab < baseTabs.length) ? widget.initialTab : 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── EN-TÊTE ───────────────────────────────────────────
              Container(
                color: headerBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bouton Fermer (à gauche)
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: onSurface),
                        onPressed: widget.onClose,
                      ),
                    ),
                    // TITRE du projet (centré)
                    Center(
                      child: _isEditingName
                          ? SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          textAlign: TextAlign.center,
                          style:
                          TextStyle(color: onSurface, fontSize: 20),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Nom du projet',
                            hintStyle: TextStyle(
                                color: onSurface.withOpacity(0.6)),
                          ),
                          autofocus: true,
                          onSubmitted: (_) => _nameFocus.unfocus(),
                        ),
                      )
                          : GestureDetector(
                        onTap: () {
                          setState(() => _isEditingName = true);
                          _nameFocus.requestFocus();
                        },
                        child: Text(
                          _nameCtrl.text,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: onSurface),
                        ),
                      ),
                    ),
                    // Bulles d’initiales + bouton ajouter + bouton settings
                    Positioned(
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Initiales des collaborateurs
                          ..._collaborators.map((col) {
                            final display =
                                _collaboratorNames[col.uid] ?? col.uid;
                            final parts = display.split(' ');
                            final initials = parts.length > 1
                                ? '${parts[0][0]}${parts[1][0]}'
                                : display.substring(0, 1);
                            return Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor:
                                isDark ? Colors.white24 : Colors.grey[200],
                                child: Text(
                                  initials.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          // Bouton “Ajouter un collaborateur”
                          IconButton(
                            icon: Icon(Icons.person_add, color: onSurface),
                            tooltip: 'Ajouter un collaborateur',
                            onPressed: _showAddCollaboratorDialog,
                          ),
                          const SizedBox(width: 8),
                          // Bouton “Paramètres du projet”
                          IconButton(
                            icon: Icon(Icons.settings, color: onSurface),
                            tooltip: 'Paramètres du projet',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProjectSettingsScreen(
                                    project: widget.project,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ─── ONGLETS ───────────────────────────────────────────
              TabBar(
                labelColor: onSurface,
                unselectedLabelColor: onSurface.withOpacity(0.6),
                indicatorColor: theme.colorScheme.primary,
                tabs: baseTabs,
              ),

              // ─── CONTENU DES ONGLETS ─────────────────────────────────
              Expanded(
                child: TabBarView(children: baseViews),
              ),
            ],
          ),
        );
      },
    );
  }
}
