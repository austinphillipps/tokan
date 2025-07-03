// lib/features/tasks/views/tasks_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../main.dart'; // Pour AppTheme, AppColors, themeNotifier

// Import des vues « Liste » et « Calendrier »
import '../widgets/task_list_mode_widget.dart';
import '../widgets/task_calendar_mode_widget.dart';

// Import du panneau de détails de tâche
import '../../../shared/widgets/task_details_panel_widget.dart';

import '../../tasks/models/custom_task_model.dart';

enum TaskViewMode { list, calendar }

class TasksPage extends StatefulWidget {
  /// Si non-null : affiche uniquement les tâches du projet {projectId}
  /// Sinon : affiche toutes les tâches de l’application pour l’utilisateur
  final String? projectId;

  const TasksPage({Key? key, this.projectId}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool showTaskPanel = false;
  CustomTask? activeTask;
  TaskViewMode _viewMode = TaskViewMode.list;
  String? filterCollaborator;
  DateTime? filterDate;

  bool _multiSelectMode = false;
  final Set<String> _selectedTaskIds = {};

  final ValueNotifier<int> _calendarRefreshNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = themeNotifier.value == AppTheme.light;

    return Scaffold(
      backgroundColor: isLight
          ? AppColors.whiteGlassBackground
          : theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (_multiSelectMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() {
                    _selectedTaskIds.clear();
                    _multiSelectMode = false;
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          StreamBuilder<List<CustomTask>>(
            stream: _getTasksStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Erreur : ${snap.error}',
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                  ),
                );
              }
              final tasks = snap.data!;

              return Column(
                children: [
                  // Menu horizontal avec fond "glass header"
                  Container(
                    color:
                        isLight ? Colors.transparent : AppColors.glassHeader,
                    child: _buildHorizontalMenu(tasks),
                  ),
                  Expanded(child: _buildView(tasks)),
                ],
              );
            },
          ),

          if (showTaskPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() => showTaskPanel = false);
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          if (showTaskPanel && activeTask != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width / 3,
                color: theme.colorScheme.surface,
                child: TaskDetailPanel(
                  task: activeTask!,
                  onSave: (updated) async {
                    await _saveTask(updated);
                    setState(() => showTaskPanel = false);
                    _calendarRefreshNotifier.value++;
                  },
                  onClose: () => setState(() => showTaskPanel = false),
                  onMarkAsDone: () {
                    if (activeTask != null) _toggleStatus(activeTask!);
                  },
                  onCalendarRefresh: () {
                    _calendarRefreshNotifier.value++;
                  },
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: showTaskPanel
          ? null
          : FloatingActionButton(
        onPressed: () {
          setState(() {
            activeTask = CustomTask(
              id: '',
              name: '',
              description: '',
              status: '',
              responsable: '',
              deadline: null,
              startTime: null,
              endTime: null,
              duration: null,
              client: null,
              project: widget.projectId,
              originalProjectId: null,
              recurrenceType: null,
              recurrenceDays: null,
              recurrenceIncludePast: null,
              subTasks: [],
            );
            showTaskPanel = true;
          });
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildView(List<CustomTask> tasks) {
    if (_viewMode == TaskViewMode.calendar) {
      return TasksCalendarView(
        refreshNotifier: _calendarRefreshNotifier,
        projectId: widget.projectId,
      );
    } else {
      return TasksListView(
        tasks: tasks,
        onToggleStatus: _toggleStatus,
        onCollaboratorChanged: (t, uid) async {
          t.responsable = uid ?? '';
          await _saveTask(t);
          setState(() {});
        },
        onProjectChanged: (t, id) async {
          t.project = id;
          await _saveTask(t);
          setState(() {});
        },
        onDeadlineChanged: (t, date) async {
          t.deadline = date;
          await _saveTask(t);
          setState(() {});
        },
        onOpenDetail: (t) => setState(() {
          activeTask = t;
          showTaskPanel = true;
        }),
        onAddTask: () => setState(() {
          activeTask = CustomTask(
            id: '',
            name: '',
            description: '',
            status: '',
            responsable: '',
            deadline: null,
            startTime: null,
            endTime: null,
            duration: null,
            client: null,
            project: widget.projectId,
            originalProjectId: null,
            recurrenceType: null,
            recurrenceDays: null,
            recurrenceIncludePast: null,
            subTasks: [],
          );
          showTaskPanel = true;
        }),
        onDeleteTask: _deleteTask,
        multiSelectMode: _multiSelectMode,
        selectedTaskIds: _selectedTaskIds,
        onTaskSelectToggle: (task, isSelected) {
          setState(() {
            if (isSelected) _selectedTaskIds.add(task.id);
            else _selectedTaskIds.remove(task.id);
          });
        },
        onToggleMultiSelectMode: () {
          setState(() {
            if (_multiSelectMode) _selectedTaskIds.clear();
            _multiSelectMode = !_multiSelectMode;
          });
        },
      );
    }
  }

  Widget _buildHorizontalMenu(List<CustomTask> tasks) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        children: [
          ToggleButtons(
            isSelected: [
              _viewMode == TaskViewMode.list,
              _viewMode == TaskViewMode.calendar
            ],
            onPressed: (index) {
              setState(() {
                _viewMode = TaskViewMode.values[index];
                _multiSelectMode = false;
                _selectedTaskIds.clear();
              });
            },
            color: theme.colorScheme.onBackground,
            selectedColor: AppColors.blue,
            fillColor: AppColors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Liste'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Calendrier'),
              ),
            ],
          ),
          const SizedBox(width: 24),
          if (_viewMode == TaskViewMode.list) ...[
            DropdownButton<String>(
              hint: const Text('Filtrer par collaborateur'),
              value: filterCollaborator,
              items: ['Alice', 'Bob', 'Charlie']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => filterCollaborator = val),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: filterDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          background: theme.scaffoldBackgroundColor,
                          onBackground: theme.colorScheme.onBackground,
                        ),
                        dialogBackgroundColor: theme.scaffoldBackgroundColor,
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) setState(() => filterDate = picked);
              },
              child: Text(
                filterDate == null
                    ? 'Filtrer par date'
                    : DateFormat('yyyy-MM-dd').format(filterDate!),
              ),
            ),
            if (filterDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => filterDate = null),
              ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Stream<List<CustomTask>> _getTasksStream() {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    var query = db.collection('tasks').where('createdBy', isEqualTo: user.uid);
    if (widget.projectId?.isNotEmpty == true) {
      query = query.where('project', isEqualTo: widget.projectId);
    }

    return query.snapshots().map((snap) {
      var list = snap.docs
          .map((d) =>
          CustomTask.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();

      if (widget.projectId == null) {
        if (filterCollaborator?.isNotEmpty == true) {
          list = list.where((t) => t.responsable == filterCollaborator).toList();
        }
        if (filterDate != null) {
          list = list
              .where((t) =>
          t.deadline != null && _sameDay(t.deadline!, filterDate!))
              .toList();
        }
      }

      list.sort((a, b) =>
          (a.deadline ?? DateTime(1970)).compareTo(b.deadline ?? DateTime(1970)));
      return list;
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _saveTask(CustomTask task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final db = FirebaseFirestore.instance;

    final data = task.toMap(user.uid)
      ..['project'] = task.project
      ..['updatedBy'] = user.uid
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (task.id.isEmpty) {
      if (task.status.isEmpty) task.status = 'à venir';
      final docRef = await db.collection('tasks').add(data);
      task.id = docRef.id;
    } else {
      await db.collection('tasks').doc(task.id).update(data);
    }
  }

  void _toggleStatus(CustomTask task) async {
    final nextStatus = (task.status.toLowerCase() == 'completed' ||
        task.status.toLowerCase().startsWith('termin'))
        ? 'pending'
        : 'completed';
    task.status = nextStatus;
    await _saveTask(task);
    _calendarRefreshNotifier.value++;
  }

  Future<void> _deleteTask(CustomTask task) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
    _calendarRefreshNotifier.value++;
  }
}
