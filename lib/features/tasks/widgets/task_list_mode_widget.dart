// lib/features/tasks/views/widgets/task_list_mode_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../tasks/models/custom_task_model.dart';

// Import de AppColors (défini dans main.dart)
import '../../../main.dart';

class TasksListView extends StatelessWidget {
  final List<CustomTask> tasks;
  final Function(CustomTask) onToggleStatus;
  final Function(CustomTask, String) onCollaboratorChanged;
  final Function(CustomTask, String) onProjectChanged;
  final Function(CustomTask, DateTime) onDeadlineChanged;
  final Function(CustomTask) onOpenDetail;
  final VoidCallback onAddTask;

  const TasksListView({
    Key? key,
    required this.tasks,
    required this.onToggleStatus,
    required this.onCollaboratorChanged,
    required this.onProjectChanged,
    required this.onDeadlineChanged,
    required this.onOpenDetail,
    required this.onAddTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si aucune tâche, on propose d'en ajouter une
    if (tasks.isEmpty) {
      return Center(
        child: Card(
          color: Theme.of(context).colorScheme.surface, // Utilise la couleur surface
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: TextButton.icon(
              onPressed: onAddTask,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.purple, // violet pour le bouton
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
          ),
        ),
      );
    }

    // Séparer les tâches "En cours" et "Terminées" selon le statut 'completed'
    final enCours = tasks.where((t) => t.status != 'completed').toList();
    final terminees = tasks.where((t) => t.status == 'completed').toList();

    return Column(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    "En cours",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                    ),
                  ],
                )),
              ],
              // Section "Terminées"
              if (terminees.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    "Terminées",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                    ),
                  ],
                )),
              ],
              // Bouton pour ajouter une nouvelle tâche
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(
                      "Ajouter une tâche...",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onPressed: onAddTask,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ts = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onBackground,
      fontWeight: FontWeight.bold,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark
        ? AppColors.darkGreyBackground
        : AppColors.lightGreyBackground;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          _vDiv(context),
          Expanded(flex: 3, child: Text("Nom", style: ts)),
          _vDiv(context),
          Expanded(flex: 2, child: Text("Échéance", style: ts)),
          _vDiv(context),
          Expanded(flex: 2, child: Text("Responsable", style: ts)),
          _vDiv(context),
          Expanded(flex: 2, child: Text("Projet", style: ts)),
        ],
      ),
    );
  }

  Widget _vDiv(BuildContext context) => Container(
    width: 1,
    height: 24,
    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _TaskRow extends StatefulWidget {
  final CustomTask task;
  final Function(CustomTask) onToggle;
  final Function(CustomTask, String) onCollaboratorChanged;
  final Function(CustomTask, String) onProjectChanged;
  final Function(CustomTask, DateTime) onDeadlineChanged;
  final Function(CustomTask) onOpenDetail;

  const _TaskRow({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onCollaboratorChanged,
    required this.onProjectChanged,
    required this.onDeadlineChanged,
    required this.onOpenDetail,
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
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
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
                onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
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
                                style: TextStyle(color: Theme.of(ctx4).colorScheme.onSurface),
                              ),
                              onTap: () {
                                widget.onCollaboratorChanged(widget.task, u['uid']!);
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
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.blue),
                  ),
                ),
                onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView(
                  children: projects
                      .where(
                        (p) => p['name']!.toLowerCase().contains(search),
                  )
                      .map((p) => ListTile(
                    title: Text(
                      p['name']!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                    ),
                    onTap: () {
                      widget.onProjectChanged(widget.task, p['id']!);
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
          color: _hoverRow
              ? AppColors.blue.withOpacity(0.1)
              : (isDark
              ? AppColors.darkGreyBackground
              : Colors.white),
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
            // Point de statut (cercle vert si terminé, gris clair sinon)
            SizedBox(
              width: 40,
              child: InkWell(
                onTap: () => widget.onToggle(widget.task),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: widget.task.status == 'completed'
                      ? AppColors.green
                      : (isDark
                      ? Theme.of(context).colorScheme.onBackground.withOpacity(0.2)
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
            // Nom de la tâche → ouvre le panneau de détails
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
            // Échéance → ouvre date picker
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _pickDeadline,
                child: Text(
                  deadlineStr ?? 'Ajouter',
                  style: TextStyle(
                    color: deadlineStr != null
                        ? (isDark
                        ? Theme.of(context).colorScheme.onBackground.withOpacity(0.7)
                        : Colors.black54)
                        : AppColors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            _vDiv(context),
            // Responsable → ouvre dialog de sélection
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _showCollaboratorDialog,
                child: Text(
                  _loadingCollaborator ? '...' : (_collaboratorName ?? 'Ajouter'),
                  style: TextStyle(
                    color: _collaboratorName != null
                        ? (isDark
                        ? Theme.of(context).colorScheme.onBackground.withOpacity(0.7)
                        : Colors.black54)
                        : AppColors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            _vDiv(context),
            // Projet → ouvre dialog de sélection
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _showProjectDialog,
                child: Text(
                  _loadingProject ? '...' : (_projectName ?? 'Ajouter'),
                  style: TextStyle(
                    color: _projectName != null
                        ? (isDark
                        ? Theme.of(context).colorScheme.onBackground.withOpacity(0.7)
                        : Colors.black54)
                        : AppColors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
