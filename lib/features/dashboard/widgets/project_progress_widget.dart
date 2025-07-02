// lib/features/dashboard/widgets/project_progress_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../main.dart'; // Pour AppTheme, themeNotifier, AppColors
import '../../projects/models/project_models.dart';
import '../../projects/services/project_service.dart';
import '../../tasks/models/custom_task_model.dart';

class ProjectProgressWidget extends StatefulWidget {
  const ProjectProgressWidget({Key? key}) : super(key: key);

  @override
  _ProjectProgressWidgetState createState() => _ProjectProgressWidgetState();
}

class _ProjectProgressWidgetState extends State<ProjectProgressWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProjectService _projectService = ProjectService();

  StreamSubscription<List<Project>>? _projectsSub;
  List<_ProjectData> _projectsData = [];
  bool _isLoading = false;
  bool _initialized = false;

  /// Conserve l’état d’expansion pour chaque projet
  final Set<String> _expandedProjectIds = {};

  @override
  void initState() {
    super.initState();
    _subscribeToProjects();
  }

  void _subscribeToProjects() {
    _projectsSub = _projectService.getProjectsStream().listen(
          (projectList) async {
        await _loadAllTasks(projectList);
      },
      onError: (error) {
        debugPrint('Erreur stream projets : $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _loadAllTasks(List<Project> projects) async {
    setState(() {
      _initialized = true;
      _projectsData = [];
      _isLoading = projects.isNotEmpty;
    });

    if (projects.isEmpty) return;

    final List<_ProjectData> temp = [];
    final List<Future<void>> futures = [];

    for (final project in projects) {
      futures.add(
        _fetchTasksForProject(project).then((pd) {
          if (pd != null) temp.add(pd);
        }),
      );
    }

    await Future.wait(futures);
    temp.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    if (mounted) {
      setState(() {
        _projectsData = temp;
        _isLoading = false;
      });
    }
  }

  Future<_ProjectData?> _fetchTasksForProject(Project project) async {
    try {
      final snap = await _firestore
          .collection('projects')
          .doc(project.id)
          .collection('tasks')
          .get();

      final tasks = snap.docs
          .map((doc) => CustomTask.fromMap(doc.data(), doc.id))
          .toList();

      return _ProjectData(
        projectId: project.id,
        title: project.name,
        tasks: tasks,
      );
    } catch (e) {
      debugPrint('Erreur chargement tâches pour ${project.id}: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _projectsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = themeNotifier.value == AppTheme.light;
    final Color glassBg = isLight
        ? AppColors.whiteGlassBackground
        : AppColors.glassBackground;
    final Color headerBg = isLight
        ? AppColors.whiteGlassHeader
        : AppColors.glassHeader;

    if (!_initialized || (!_isLoading && _projectsData.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      color: glassBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entête "PROJETS EN COURS"
          Container(
            width: double.infinity,
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'PROJETS EN COURS',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: _projectsData.length,
              itemBuilder: (context, index) {
                final pd = _projectsData[index];
                return _buildProjectCard(pd, context, glassBg, headerBg);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
      _ProjectData pd,
      BuildContext context,
      Color canvasBg,
      Color headerBg,
      ) {
    final tasks = pd.tasks;
    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((t) => _isTaskCompleted(t)).length;

    final progressValue =
    (totalTasks > 0) ? (completedTasks / totalTasks) : 0.0;
    final progressPct =
        (progressValue * 100).toStringAsFixed(0) + '% achevé';

    final bool isExpanded =
    _expandedProjectIds.contains(pd.projectId);
    final bool isSequoia = themeNotifier.value == AppTheme.sequoia;
    final Color cardBg = isSequoia
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).cardColor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isSequoia ? 0 : 4,
      color: cardBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER + FLÈCHE D’EXPANSION
          InkWell(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedProjectIds.remove(pd.projectId);
                } else {
                  _expandedProjectIds.add(pd.projectId);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pd.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    progressPct,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // BARRE DE PROGRESSION
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.1),
                valueColor:
                AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // LISTE DES TÂCHES
          if (isExpanded && totalTasks > 0) ...[
            const Padding(
              padding:
              EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: Colors.transparent,
                height: 1,
                thickness: 1,
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _buildTaskList(
                    tasks, 0, canvasBg, context),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  bool _isTaskCompleted(CustomTask task) {
    final lower = task.status.toLowerCase();
    if (task.subTasks.isEmpty) {
      return lower == 'completed' ||
          lower == 'terminé' ||
          lower == 'terminée';
    } else {
      return task.subTasks.every(_isTaskCompleted);
    }
  }

  List<Widget> _buildTaskList(
      List<CustomTask> tasks,
      int indent,
      Color canvasBg,
      BuildContext context,
      ) {
    final List<Widget> widgets = [];

    for (final task in tasks) {
      final hasSubtasks = task.subTasks.isNotEmpty;
      final int totalSub =
      hasSubtasks ? task.subTasks.length : 0;
      final int completedSub = hasSubtasks
          ? _countCompletedImmediateSubtasks(task)
          : 0;
      final int percentSub = totalSub > 0
          ? ((completedSub / totalSub) * 100).round()
          : 0;

      final bool isCompleted = _isTaskCompleted(task);
      final icon = isCompleted
          ? Icons.check_circle
          : Icons.radio_button_unchecked;
      final textStyle = isCompleted
          ? Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(
          decoration:
          TextDecoration.lineThrough)
          : Theme.of(context).textTheme.bodyLarge;

      if (hasSubtasks) {
        // Tâche avec sous-tâches
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
                left: indent * 12.0, right: 0),
            child: Theme(
              data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent),
              child: ExpansionTile(
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor:
                Colors.transparent,
                tilePadding: EdgeInsets.zero,
                childrenPadding:
                EdgeInsets.only(
                    left: (indent + 1) * 12.0,
                    right: 0),
                title: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isCompleted
                          ? Theme.of(context)
                          .colorScheme
                          .primary
                          : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.name,
                        style: textStyle,
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$percentSub %',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                    ),
                  ],
                ),
                children: _buildTaskList(
                    task.subTasks,
                    indent + 1,
                    canvasBg,
                    context),
              ),
            ),
          ),
        );
      } else {
        // Tâche simple
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
                left: indent * 12.0,
                right: 0,
                bottom: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: canvasBg,
                borderRadius:
                BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(
                    horizontal: 8.0),
                tileColor: Colors.transparent,
                leading: Icon(
                  icon,
                  size: 20,
                  color: isCompleted
                      ? Theme.of(context)
                      .colorScheme
                      .primary
                      : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
                title: Text(
                  task.name,
                  style: textStyle,
                ),
              ),
            ),
          ),
        );
      }

      // Séparateur transparent
      if (task != tasks.last) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 0.0),
            child: Divider(
              color: Colors.transparent,
              height: 1,
              thickness: 1,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  int _countCompletedImmediateSubtasks(CustomTask task) {
    int count = 0;
    for (final sub in task.subTasks) {
      if (_isTaskCompleted(sub)) count++;
    }
    return count;
  }
}

/// Structure interne pour stocker un projet + ses tâches.
class _ProjectData {
  final String projectId;
  final String title;
  final List<CustomTask> tasks;

  _ProjectData({
    required this.projectId,
    required this.title,
    required this.tasks,
  });
}
