// lib/features/projects/widgets/project_detail_panel_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../main.dart'; // pour AppColors
import '../models/project_models.dart';
import '../../tasks/views/tasks_screen.dart';
import '../views/project_settings_screen.dart';
import 'discussion_screen.dart';

import '../../../plugins/crm/services/crm_plugin.dart'; // CrmPlugin

class ProjectDetailPanel extends StatefulWidget {
  final Project project;
  final void Function(Project) onSave;
  final VoidCallback onClose;
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
  late final TextEditingController _nameCtrl, _descCtrl, _objCtrl;
  late final TextEditingController _collabSearchCtrl;
  late List<Collaborator> _collaborators;
  late Color _selectedColor;
  bool _isEditingName = false;
  late FocusNode _nameFocus;

  late Stream<List<Map<String, String>>> _friendsStream;
  final Map<String, String> _collabNames = {};
  String _collabSearch = '';

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.project.name)
      ..addListener(_autoSave);
    _descCtrl = TextEditingController(text: widget.project.description)
      ..addListener(_autoSave);
    _objCtrl = TextEditingController(text: widget.project.objective ?? '')
      ..addListener(_autoSave);
    _collabSearchCtrl = TextEditingController();

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

    _friendsStream = _loadFriends();
    _loadCollaboratorNames();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _objCtrl.dispose();
    _collabSearchCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _autoSave() {
    final raw = _nameCtrl.text.trim();
    final name = raw.isNotEmpty
        ? '${raw[0].toUpperCase()}${raw.substring(1)}'
        : raw;
    widget.onSave(widget.project.copyWith(
      name: name,
      description: _descCtrl.text.trim(),
      objective:
      _objCtrl.text.trim().isNotEmpty ? _objCtrl.text.trim() : null,
      collaborators: _collaborators,
      color: _selectedColor.value.toRadixString(16),
      plugins: widget.project.plugins,
    ));
  }

  Stream<List<Map<String, String>>> _loadFriends() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('collaborations')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snap) async {
      final out = <Map<String, String>>[];
      for (var d in snap.docs) {
        final data = d.data();
        final from = data['from'] as String?;
        final to = data['to'] as String?;
        final other = (from == user.uid)
            ? to
            : (to == user.uid ? from : null);
        if (other == null) continue;
        final udoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(other)
            .get();
        if (!udoc.exists) continue;
        final ud = udoc.data()!;
        out.add({
          'uid': other,
          'displayName': ud['displayName'] as String? ?? 'Utilisateur',
        });
      }
      return out;
    });
  }

  Future<void> _loadCollaboratorNames() async {
    for (var c in _collaborators) {
      if (_collabNames.containsKey(c.uid)) continue;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(c.uid)
          .get();
      _collabNames[c.uid] = doc.exists
          ? (doc.data()!['displayName'] as String? ?? c.uid)
          : c.uid;
    }
    setState(() {});
  }

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
              decoration:
              BoxDecoration(color: c, shape: BoxShape.circle),
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

  Future<void> _showAddCollaboratorDialog() async {
    String search = '';
    final ctrl = TextEditingController();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Ajouter un collaborateur'),
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          titleTextStyle: Theme.of(ctx)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(ctx).colorScheme.onSurface),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Rechercher…',
                    hintStyle: TextStyle(
                      color:
                      Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.blue),
                    ),
                  ),
                  onChanged: (v) => setSt(() => search = v.trim().toLowerCase()),
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: StreamBuilder<List<Map<String, String>>>(
                    stream: _friendsStream,
                    builder: (ctx2, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final list = snap.data!
                          .where((u) => u['displayName']!
                          .toLowerCase()
                          .contains(search))
                          .toList();
                      if (list.isEmpty) {
                        return Text(
                          'Aucun ami trouvé',
                          style: TextStyle(
                              color: Theme.of(ctx2).colorScheme.onSurface),
                        );
                      }
                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx3, i) {
                          final u = list[i];
                          return ListTile(
                            title: Text(
                              u['displayName']!,
                              style: TextStyle(
                                  color: Theme.of(ctx3).colorScheme.onSurface),
                            ),
                            onTap: () => Navigator.pop(ctx, u['uid']),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
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
        ),
      ),
    );
    if (selected != null &&
        !_collaborators.any((c) => c.uid == selected)) {
      setState(() {
        _collaborators.add(Collaborator(uid: selected, role: 'viewer'));
      });
      await _loadCollaboratorNames();
      _autoSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final headerBg = AppColors.glassHeader;
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.project.id)
          .snapshots(),
      builder: (ctx, snap) {
        final live = snap.hasData && snap.data!.exists
            ? (snap.data!.data()!['plugins'] as List<dynamic>?)
            ?.cast<String>() ??
            []
            : widget.project.plugins ?? [];

        // Définit les onglets et leurs vues
        final tabs = <String>[
          'Informations',
          'Tâches',
          'Discussion générale',
        ];
        final views = <Widget>[
          _buildInfoTab(onSurface, isDark),
          TasksPage(projectId: widget.project.id),
          ProjectDiscussionScreen(projectId: widget.project.id),
        ];

        if (live.contains('crm')) {
          tabs.add('CRM');
          views.add(CrmPlugin().buildContent(context));
        }

        return Container(
          color: AppColors.darkBackground,
          child: DefaultTabController(
            length: tabs.length,
            initialIndex:
            widget.initialTab < tabs.length ? widget.initialTab : 0,
            child: Builder(
              builder: (context) {
                final tabController = DefaultTabController.of(context)!;

                return Column(
                  children: [
                    // En-tête with back button, project name, and settings button
                    Container(
                      color: headerBg,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 56,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: onSurface),
                            onPressed: widget.onClose,
                          ),
                          Expanded(
                            child: _isEditingName
                                ? TextField(
                              controller: _nameCtrl,
                              focusNode: _nameFocus,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: onSurface, fontSize: 20),
                              decoration: const InputDecoration(
                                  border: InputBorder.none),
                              autofocus: true,
                              onSubmitted: (_) =>
                                  _nameFocus.unfocus(),
                            )
                                : GestureDetector(
                              onTap: () {
                                setState(() => _isEditingName = true);
                                _nameFocus.requestFocus();
                              },
                              child: Text(
                                widget.project.name,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(color: onSurface),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.person_add, color: onSurface),
                            tooltip: 'Ajouter un collaborateur',
                            onPressed: _showAddCollaboratorDialog,
                          ),
                          IconButton(
                            icon: Icon(Icons.settings, color: onSurface),
                            tooltip: 'Paramètres du projet',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjectSettingsScreen(
                                    projectId: widget.project.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Row(
                        children: [
                          // NavigationRail without purple background
                          AnimatedBuilder(
                            animation: tabController,
                            builder: (context, _) => NavigationRail(
                              backgroundColor: headerBg,
                              selectedIndex: tabController.index,
                              onDestinationSelected: (idx) {
                                tabController.animateTo(idx);
                              },
                              labelType: NavigationRailLabelType.all,
                              indicatorColor: Colors.transparent,
                              destinations: tabs.map((label) {
                                IconData icon;
                                switch (label) {
                                  case 'Informations':
                                    icon = Icons.info_outline;
                                    break;
                                  case 'Tâches':
                                    icon = Icons.check_circle_outline;
                                    break;
                                  case 'Discussion générale':
                                    icon = Icons.forum_outlined;
                                    break;
                                  case 'CRM':
                                    icon = Icons.business_center_outlined;
                                    break;
                                  default:
                                    icon = Icons.circle;
                                }
                                return NavigationRailDestination(
                                  icon: Icon(icon,
                                      color: onSurface.withOpacity(0.6)),
                                  selectedIcon: Icon(icon,
                                      color: theme.colorScheme.primary),
                                  label: Text(label),
                                );
                              }).toList(),
                            ),
                          ),

                          // Vertical divider
                          const VerticalDivider(width: 1, thickness: 1),

                          // Tab content
                          Expanded(
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: views,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(Color onSurface, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor:
                    isDark ? AppColors.darkGreyBackground : Colors.grey[100],
                  ),
                  onChanged: (_) => _autoSave(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _objCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Objectif',
                    filled: true,
                    fillColor:
                    isDark ? AppColors.darkGreyBackground : Colors.grey[100],
                  ),
                  onChanged: (_) => _autoSave(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Couleur du libellé',
                  style: TextStyle(color: _selectedColor),
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
      ),
    );
  }
}