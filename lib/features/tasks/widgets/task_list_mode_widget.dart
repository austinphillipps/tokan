// lib/features/tasks/views/widgets/task_list_mode_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../main.dart'; // Pour accéder à AppColors
import 'dart:ui';

import '../../tasks/models/custom_task_model.dart';

class TasksListView extends StatelessWidget {
  final List<CustomTask> tasks;
  final Function(CustomTask) onToggleStatus;
  final Function(CustomTask, String?) onCollaboratorChanged;
  final Function(CustomTask, String?) onProjectChanged;
  final Function(CustomTask, DateTime?) onDeadlineChanged;
  final Function(CustomTask) onOpenDetail;
  final VoidCallback onAddTask;
  final Function(CustomTask) onDeleteTask;

  // ← Paramètres pour la sélection multiple
  final bool multiSelectMode;
  final Set<String> selectedTaskIds;
  final Function(CustomTask, bool) onTaskSelectToggle;
  final VoidCallback onToggleMultiSelectMode;

  const TasksListView({
    Key? key,
    required this.tasks,
    required this.onToggleStatus,
    required this.onCollaboratorChanged,
    required this.onProjectChanged,
    required this.onDeadlineChanged,
    required this.onOpenDetail,
    required this.onAddTask,
    required this.onDeleteTask,

    // ← Nouveaux paramètres :
    required this.multiSelectMode,
    required this.selectedTaskIds,
    required this.onTaskSelectToggle,
    required this.onToggleMultiSelectMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si aucune tâche, on propose d'en ajouter une
    if (tasks.isEmpty) {
      return Center(
        child: Card(
          color: AppColors.glassBackground,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: onAddTask,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.purple,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Ajouter une tâche',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final enCours = tasks.where((t) => t.status != 'completed').toList();
    final terminees = tasks.where((t) => t.status == 'completed').toList();

    // On enveloppe le Column principal dans un GestureDetector transparent :
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (multiSelectMode) {
          onToggleMultiSelectMode();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                // Section "En cours"
                if (enCours.isNotEmpty) ...[
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      "En cours",
                      style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...enCours.map((task) => Column(
                    children: [
                      _TaskRow(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: onToggleStatus,
                        onCollaboratorChanged: onCollaboratorChanged,
                        onProjectChanged: onProjectChanged,
                        onDeadlineChanged: onDeadlineChanged,
                        onOpenDetail: onOpenDetail,
                        onDelete: onDeleteTask,

                        // ← Paramètres multi-sélection
                        multiSelectMode: multiSelectMode,
                        isSelected: selectedTaskIds.contains(task.id),
                        onTaskSelectToggle: onTaskSelectToggle,
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.3),
                      ),
                    ],
                  )),
                ],
                // Section "Terminées"
                if (terminees.isNotEmpty) ...[
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      "Terminées",
                      style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...terminees.map((task) => Column(
                    children: [
                      _TaskRow(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: onToggleStatus,
                        onCollaboratorChanged: onCollaboratorChanged,
                        onProjectChanged: onProjectChanged,
                        onDeadlineChanged: onDeadlineChanged,
                        onOpenDetail: onOpenDetail,
                        onDelete: onDeleteTask,

                        // ← Paramètres multi-sélection
                        multiSelectMode: multiSelectMode,
                        isSelected: selectedTaskIds.contains(task.id),
                        onTaskSelectToggle: onTaskSelectToggle,
                      ),
                      Divider(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.3),
                      ),
                    ],
                  )),
                ],
                // Boutons pour ajouter une tâche ou un dossier
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(
                            "Ajouter une tâche...",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.7),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                          onPressed: onAddTask,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildHeader(BuildContext context) {
    final bool isLight = themeNotifier.value == AppTheme.light;
    final Color headerColor =
        isLight ? AppColors.whiteGlassHeader : AppColors.glassHeader;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
          const SizedBox(width: 40), // Pour la colonne statut (cercle)
          _vDiv(context),
          Expanded(
            flex: 3,
            child: Text(
              "Nom",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _vDiv(context),
          Expanded(
            flex: 2,
            child: Text(
              "Échéance",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _vDiv(context),
          Expanded(
            flex: 2,
            child: Text(
              "Responsable",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _vDiv(context),
          Expanded(
            flex: 2,
            child: Text(
              "Projet",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _vDiv(context),

          // ← Zone réservée à l'icône checkbox ou corbeille (40px de large)
          SizedBox(
            width: 50,
            child: multiSelectMode
            // Si on est en mode multi-sélection, afficher la corbeille rouge
                ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Supprimer les tâches sélectionnées',
                onPressed: selectedTaskIds.isEmpty
                    ? null
                    : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmation'),
                      content: Text(
                        'Souhaitez-vous supprimer '
                            '${selectedTaskIds.length} tâche(s) sélectionnée(s) ?',
                      ),
                      backgroundColor:
                      Theme.of(ctx).colorScheme.surface,
                      titleTextStyle: Theme.of(ctx)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface),
                      contentTextStyle: Theme.of(ctx)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(ctx).pop(false),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurface),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(ctx).pop(true),
                          child: Text(
                            'Supprimer',
                            style: TextStyle(
                                color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    // 1) On récupère d'abord la liste complète des CustomTask à supprimer
                    final tasksToRemove = tasks
                        .where((t) =>
                        selectedTaskIds.contains(t.id))
                        .toList();

                    // 2) On supprime chaque tâche
                    for (var task in tasksToRemove) {
                      onDeleteTask(task);
                    }

                    // 3) On désélectionne chaque tâche (sans passer par tasks.firstWhere)
                    for (var task in tasksToRemove) {
                      onTaskSelectToggle(task, false);
                    }

                    // 4) On quitte le mode multi-sélection
                    onToggleMultiSelectMode();
                  }
                },
              ),
            )
            // Sinon, afficher l'icône pour entrer en mode sélection multiple
                : IconButton(
              icon: const Icon(Icons.check_box),
              tooltip: 'Sélectionner plusieurs',
              onPressed: onToggleMultiSelectMode,
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _vDiv(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _TaskRow extends StatefulWidget {
  final CustomTask task;
  final Function(CustomTask) onToggle;
  final Function(CustomTask, String?) onCollaboratorChanged;
  final Function(CustomTask, String?) onProjectChanged;
  final Function(CustomTask, DateTime?) onDeadlineChanged;
  final Function(CustomTask) onOpenDetail;
  final Function(CustomTask) onDelete;

  // ← Nouveaux paramètres pour la sélection multiple
  final bool multiSelectMode;
  final bool isSelected;
  final Function(CustomTask, bool) onTaskSelectToggle;

  const _TaskRow({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onCollaboratorChanged,
    required this.onProjectChanged,
    required this.onDeadlineChanged,
    required this.onOpenDetail,
    required this.onDelete,

    required this.multiSelectMode,
    required this.isSelected,
    required this.onTaskSelectToggle,
  }) : super(key: key);

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _hoverRow = false;
  String? _collaboratorName;
  bool _loadingCollaborator = true;
  String? _projectName;
  bool _loadingProject = true;

  @override
  void initState() {
    super.initState();
    _loadCollaboratorName();
    _loadProjectName();
  }

  Future<void> _loadCollaboratorName() async {
    final uid = widget.task.responsable;
    if (uid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (mounted) {
        setState(() {
          _collaboratorName =
              (doc.data()?['displayName'] as String?) ?? 'Utilisateur';
          _loadingCollaborator = false;
        });
      }
    } else {
      setState(() => _loadingCollaborator = false);
    }
  }

  Future<void> _loadProjectName() async {
    final projId = widget.task.project;
    if (projId != null && projId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projId)
          .get();
      if (mounted) {
        setState(() {
          _projectName = (doc.data()?['name'] as String?) ?? 'Sans nom';
          _loadingProject = false;
        });
      }
    } else {
      setState(() => _loadingProject = false);
    }
  }

  Widget _vDiv(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.task.deadline ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme(
            brightness: Theme.of(ctx).brightness,
            primary: AppColors.blue, // jour sélectionné en bleu
            onPrimary: Colors.white,
            secondary: AppColors.blue,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            background: Theme.of(ctx).scaffoldBackgroundColor,
            onBackground: Theme.of(ctx).colorScheme.onBackground,
            surface: Theme.of(ctx).colorScheme.surface,
            onSurface: Theme.of(ctx).colorScheme.onBackground,
          ),
          dialogBackgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        ),
        child: child!,
      ),
    );
    if (selected != null) {
      widget.onDeadlineChanged(widget.task, selected);
    }
  }

  Future<void> _showCollaboratorDialog() async {
    String search = '';
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sélectionner un responsable'),
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
                      color:
                      Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.blue),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => search = v.trim().toLowerCase()),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('collaborations')
                      .where('status', isEqualTo: 'accepted')
                      .snapshots(),
                  builder: (ctx2, snap) {
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.green),
                        ),
                      );
                    }
                    final user = FirebaseAuth.instance.currentUser!;
                    final docs = snap.data!.docs;
                    return FutureBuilder<List<Map<String, String>>>(
                      future: Future.wait(docs.map((d) async {
                        final data = d.data() as Map<String, dynamic>;
                        final other = (data['from'] as String) == user.uid
                            ? (data['to'] as String)
                            : (data['from'] as String);
                        final docUser = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(other)
                            .get();
                        final displayName = docUser.exists
                            ? (docUser.data()?['displayName'] as String)
                            : 'Utilisateur';
                        return {'uid': other, 'displayName': displayName};
                      }).toList()),
                      builder: (ctx3, snap2) {
                        if (!snap2.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.green),
                            ),
                          );
                        }
                        final list = snap2.data!
                            .where((u) => u['displayName']!
                            .toLowerCase()
                            .contains(search))
                            .toList();
                        if (list.isEmpty) {
                          return Text(
                            'Aucun ami trouvé',
                            style: TextStyle(
                                color: Theme.of(ctx3).colorScheme.onSurface),
                          );
                        }
                        return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (ctx4, i) {
                            final u = list[i];
                            return ListTile(
                              title: Text(
                                u['displayName']!,
                                style: TextStyle(
                                    color:
                                    Theme.of(ctx4).colorScheme.onSurface),
                              ),
                              onTap: () {
                                widget.onCollaboratorChanged(
                                    widget.task, u['uid']!);
                                Navigator.pop(ctx);
                                setState(() {
                                  _collaboratorName = u['displayName'];
                                });
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProjectDialog() async {
    String search = '';
    final ctrl = TextEditingController();
    final snap = await FirebaseFirestore.instance.collection('projects').get();
    final projects = snap.docs
        .map((d) => {
      'id': d.id,
      'name': (d.data()['name'] as String?) ?? 'Sans nom',
    })
        .toList();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sélectionner un projet'),
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
                      color:
                      Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.blue),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => search = v.trim().toLowerCase()),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView(
                  children: projects
                      .where((p) =>
                      p['name']!.toLowerCase().contains(search))
                      .map((p) => ListTile(
                    title: Text(
                      p['name']!,
                      style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    onTap: () {
                      widget.onProjectChanged(
                          widget.task, p['id']!);
                      Navigator.pop(ctx);
                      setState(() {
                        _projectName = p['name'];
                      });
                    },
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deadlineStr = widget.task.deadline != null
        ? DateFormat('yyyy-MM-dd').format(widget.task.deadline!)
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverRow = true),
      onExit: (_) => setState(() => _hoverRow = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? (_hoverRow ? AppColors.glassHeader : AppColors.glassBackground)
              : (_hoverRow ? AppColors.whiteGlassBackground : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1) Point de statut (cercle vert si terminé, gris clair sinon)
            SizedBox(
              width: 40,
              child: InkWell(
                onTap: () => widget.onToggle(widget.task),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: widget.task.status == 'completed'
                      ? AppColors.green
                      : (isDark
                      ? Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.2)
                      : Colors.grey[300]),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: isDark
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.black,
                  ),
                ),
              ),
            ),
            _vDiv(context),
            // 2) Nom de la tâche → ouvre le panneau de détails
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () => widget.onOpenDetail(widget.task),
                child: Text(
                  widget.task.name,
                  style: TextStyle(
                    color: isDark
                        ? Theme.of(context).colorScheme.onBackground
                        : Colors.black87,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            _vDiv(context),
            // 3) Échéance → ouvre date picker
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDeadline,
                      child: Text(
                        deadlineStr ?? 'Ajouter',
                        style: TextStyle(
                          color: deadlineStr != null
                              ? (isDark
                              ? Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7)
                              : Colors.black54)
                              : AppColors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (deadlineStr != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Retirer l\'\u00e9ch\u00e9ance',
                      onPressed: () {
                        widget.onDeadlineChanged(widget.task, null);
                        setState(() {});
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            _vDiv(context),
            // 4) Responsable → ouvre dialog de sélection
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showCollaboratorDialog,
                      child: Text(
                        _loadingCollaborator
                            ? '...'
                            : (_collaboratorName ?? 'Ajouter'),
                        style: TextStyle(
                          color: _collaboratorName != null
                              ? (isDark
                              ? Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7)
                              : Colors.black54)
                              : AppColors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (!_loadingCollaborator && _collaboratorName != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Retirer le responsable',
                      onPressed: () {
                        widget.onCollaboratorChanged(widget.task, null);
                        setState(() {
                          _collaboratorName = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            _vDiv(context),
            // 5) Projet → ouvre dialog de sélection
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showProjectDialog,
                      child: Text(
                        _loadingProject ? '...' : (_projectName ?? 'Ajouter'),
                        style: TextStyle(
                          color: _projectName != null
                              ? (isDark
                              ? Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7)
                              : Colors.black54)
                              : AppColors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (!_loadingProject && _projectName != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Retirer le projet',
                      onPressed: () {
                        widget.onProjectChanged(widget.task, null);
                        setState(() {
                          _projectName = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            _vDiv(context),
            // 6) Zone de droite (checkbox ou bouton de suppression individuelle)
            SizedBox(
              width: 40,
              child: widget.multiSelectMode
              // Mode multi-sélection : afficher la checkbox
                  ? Checkbox(
                value: widget.isSelected,
                onChanged: (v) {
                  widget.onTaskSelectToggle(widget.task, v!);
                },
              )
                  : (_hoverRow
              // Mode normal + survol : afficher la croix de suppression
                  ? IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Supprimer cette tâche',
                onPressed: () => widget.onDelete(widget.task),
                padding: const EdgeInsets.all(8),
                constraints:
                const BoxConstraints(), // pour ne pas ajouter de padding supplémentaire
              )
              // Mode normal + pas de survol : espace vide
                  : Container()),
            ),
          ],
        ),
      ),
    );
  }
}