// lib/pages/project_tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../features/tasks/models/custom_task_model.dart';
import '../models/project_models.dart';
import '../../../shared/widgets/task_details_panel_widget.dart';
import '../../../main.dart'; // Pour AppColors

enum TaskViewMode { list, board, calendar }

class ProjectTasksPage extends StatefulWidget {
  final Project project;
  const ProjectTasksPage({Key? key, required this.project}) : super(key: key);

  @override
  _ProjectTasksPageState createState() => _ProjectTasksPageState();
}

class _ProjectTasksPageState extends State<ProjectTasksPage> {
  TaskViewMode _viewMode = TaskViewMode.board;
  String _searchQuery = '';
  String _selectedStatus = '';
  final List<String> _statusOptions = [
    '',
    'En cours',
    'Terminée',
  ];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CustomTask? activeTask;
  bool showTaskPanel = false;

  Stream<List<CustomTask>> getTasksStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('createdBy', isEqualTo: currentUser.uid)
    // On filtre désormais par l’ID du projet (widget.project.id) au lieu du nom
        .where('project', isEqualTo: widget.project.id)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return CustomTask.fromMap(data, doc.id);
    }).toList());
  }

  Widget _buildListHeader(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.glassHeader,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Nom",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "Échéance",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<CustomTask> tasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.glassBackground;
    final titleColor = Theme.of(context).colorScheme.onBackground;
    final subtitleColor = titleColor.withOpacity(0.7);
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          "Aucune tâche",
          style: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6)),
        ),
      );
    }
    return Column(
      children: [
        if (!isMobile) _buildListHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              if (isMobile) {
                return Card(
                  color: cardBg,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _toggleStatus(task),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor:
                            task.status == 'completed' || task.status == 'terminée'
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                activeTask = task;
                                showTaskPanel = true;
                              });
                            },
                            child: Text(
                              task.name,
                              style: TextStyle(color: titleColor, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: Theme.of(context).iconTheme.color),
                          onSelected: (action) {
                            switch (action) {
                              case 'select':
                                setState(() {
                                  activeTask = task;
                                  showTaskPanel = true;
                                });
                                break;
                              case 'edit':
                                setState(() {
                                  activeTask = task;
                                  showTaskPanel = true;
                                });
                                break;
                              case 'delete':
                                _deleteTask(task);
                                break;
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'select',
                              child: Text('Sélectionner'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifier'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final deadlineStr = task.deadline != null
                    ? DateFormat('dd MMM yyyy').format(task.deadline!)
                    : '-';
                return Card(
                  color: cardBg,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(task.name, style: TextStyle(color: titleColor)),
                    trailing: Text(deadlineStr, style: TextStyle(color: subtitleColor)),
                    onTap: () {
                      setState(() {
                        activeTask = task;
                        showTaskPanel = true;
                      });
                    },
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoardView(BuildContext context, List<CustomTask> tasks) {
    final columnBg = AppColors.glassHeader;
    final cardBg = AppColors.glassBackground;
    final titleColor = Theme.of(context).colorScheme.onBackground;
    final subtitleColor = titleColor.withOpacity(0.7);

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          "Aucune tâche",
          style: TextStyle(color: subtitleColor),
        ),
      );
    }
    final ongoingTasks =
    tasks.where((t) => t.status.toLowerCase() != "terminée").toList();
    final doneTasks =
    tasks.where((t) => t.status.toLowerCase() == "terminée").toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildBoardColumn(
              context, "En cours", ongoingTasks, columnBg, cardBg, titleColor, subtitleColor),
          const SizedBox(width: 16),
          _buildBoardColumn(
              context, "Terminées", doneTasks, columnBg, cardBg, titleColor, subtitleColor),
        ],
      ),
    );
  }

  Widget _buildBoardColumn(
      BuildContext context,
      String title,
      List<CustomTask> tasks,
      Color columnBg,
      Color cardBg,
      Color titleColor,
      Color subtitleColor,
      ) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: columnBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...tasks.map((task) {
            final deadlineStr = task.deadline != null
                ? DateFormat('dd MMM yyyy').format(task.deadline!)
                : '-';
            return Card(
              color: cardBg,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(task.name, style: TextStyle(color: titleColor)),
                subtitle: Text(deadlineStr, style: TextStyle(color: subtitleColor)),
                onTap: () {
                  setState(() {
                    activeTask = task;
                    showTaskPanel = true;
                  });
                },
              ),
            );
          }).toList(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                activeTask = CustomTask(
                  name: "",
                  description: "",
                  project: widget.project.id, // on lie la tâche à l'ID du projet
                );
                showTaskPanel = true;
              });
            },
            icon: Icon(Icons.add, color: subtitleColor),
            label: Text("Ajouter une tâche", style: TextStyle(color: subtitleColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, List<CustomTask> tasks) {
    final calendarHeaderBg = AppColors.glassHeader;
    final titleColor = Theme.of(context).colorScheme.onBackground;
    final subtitleColor = titleColor.withOpacity(0.7);
    final selectedColor = AppColors.blue;
    final todayColor = AppColors.green;

    List<CustomTask> dayTasks = tasks.where((t) {
      if (t.deadline == null) return false;
      return t.deadline!.year == _selectedDay.year &&
          t.deadline!.month == _selectedDay.month &&
          t.deadline!.day == _selectedDay.day;
    }).toList();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: todayColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: selectedColor,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: TextStyle(color: titleColor),
            weekendTextStyle: TextStyle(color: titleColor),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            headerPadding: const EdgeInsets.symmetric(vertical: 8),
            titleTextStyle: TextStyle(
                color: titleColor, fontSize: 16, fontWeight: FontWeight.bold),
            leftChevronIcon: Icon(Icons.chevron_left, color: titleColor),
            rightChevronIcon: Icon(Icons.chevron_right, color: titleColor),
            formatButtonDecoration: BoxDecoration(
              color: calendarHeaderBg,
              borderRadius: BorderRadius.circular(4),
            ),
            formatButtonTextStyle: TextStyle(color: titleColor),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: titleColor),
            weekendStyle: TextStyle(color: titleColor),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return Center(
                  child: Text('${day.day}',
                      style: TextStyle(color: titleColor)));
            },
            outsideBuilder: (context, day, focusedDay) {
              return Center(
                  child: Text('${day.day}',
                      style:
                      TextStyle(color: titleColor.withOpacity(0.4))));
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dayTasks.isEmpty
              ? Center(
            child: Text(
              "Aucune tâche pour ce jour",
              style: TextStyle(color: subtitleColor),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dayTasks.length,
            itemBuilder: (context, index) {
              final task = dayTasks[index];
              final deadlineStr = task.deadline != null
                  ? DateFormat('dd MMM yyyy').format(task.deadline!)
                  : '-';
              final cardBg = AppColors.glassBackground;

              return Card(
                color: cardBg,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title:
                  Text(task.name, style: TextStyle(color: titleColor)),
                  trailing:
                  Text(deadlineStr, style: TextStyle(color: subtitleColor)),
                  onTap: () {
                    setState(() {
                      activeTask = task;
                      showTaskPanel = true;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildTasksContent() {
    return StreamBuilder<List<CustomTask>>(
      stream: getTasksStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.blue),
            ),
          );
        }
        List<CustomTask> tasks = snapshot.data!;
        final filteredTasks = tasks.where((task) {
          final matchesSearch =
          task.name.toLowerCase().contains(_searchQuery);
          final matchesStatus = _selectedStatus.isEmpty ||
              (task.status.toLowerCase() ==
                  _selectedStatus.toLowerCase());
          return matchesSearch && matchesStatus;
        }).toList();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final searchBg = AppColors.glassBackground;
        final searchTextColor = Theme.of(context).colorScheme.onBackground;
        final iconColor = searchTextColor.withOpacity(0.7);

        return Column(
          children: [
            // Barre de filtre en haut
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: searchTextColor),
                      decoration: InputDecoration(
                        hintText: "Rechercher une tâche",
                        hintStyle:
                        TextStyle(color: searchTextColor.withOpacity(0.6)),
                        filled: true,
                        fillColor: searchBg,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.search, color: iconColor),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      dropdownColor: searchBg,
                      style: TextStyle(color: searchTextColor),
                      underline: const SizedBox(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedStatus = newValue ?? '';
                        });
                      },
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status.isEmpty ? 'Tous' : status),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Barre verticale de sélection de vue
                  Container(
                    width: 70,
                    color: AppColors.glassHeader,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildViewButton(
                          context: context,
                          icon: Icons.view_list,
                          label: "Liste",
                          selected: _viewMode == TaskViewMode.list,
                          onTap: () => setState(() => _viewMode = TaskViewMode.list),
                        ),
                        const SizedBox(height: 8),
                        _buildViewButton(
                          context: context,
                          icon: Icons.view_module,
                          label: "Tableau",
                          selected: _viewMode == TaskViewMode.board,
                          onTap: () => setState(() => _viewMode = TaskViewMode.board),
                        ),
                        const SizedBox(height: 8),
                        _buildViewButton(
                          context: context,
                          icon: Icons.calendar_month,
                          label: "Calendrier",
                          selected: _viewMode == TaskViewMode.calendar,
                          onTap: () => setState(() => _viewMode = TaskViewMode.calendar),
                        ),
                      ],
                    ),
                  ),

                  // Contenu principal des tâches
                  Expanded(child: _buildView(context, filteredTasks)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildView(BuildContext context, List<CustomTask> tasks) {
    switch (_viewMode) {
      case TaskViewMode.list:
        return _buildListView(context, tasks);
      case TaskViewMode.board:
        return _buildBoardView(context, tasks);
      case TaskViewMode.calendar:
        return _buildCalendarView(context, tasks);
    }
  }

  Widget _buildViewButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final activeBg = selected
        ? AppColors.blue.withOpacity(0.2)
        : Colors.transparent;
    final activeColor =
    selected ? AppColors.blue : Theme.of(context).colorScheme.onBackground;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: activeBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: activeColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: activeColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = AppColors.glassBackground;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: pageBg,
        child: Column(
          children: [
            AppBar(
              backgroundColor: pageBg,
              elevation: 0,
              title: Text(widget.project.name),
            ),
            Expanded(
              child: Stack(
                children: [
                  buildTasksContent(),
                  if (showTaskPanel && activeTask != null) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => setState(() => showTaskPanel = false),
                        child: Container(color: Colors.black.withOpacity(0.5)),
                      ),
                    ),
                    Center(
                      child: Material(
                        color: isDark
                            ? AppColors.darkBackground
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: 500,
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: TaskDetailPanel(
                            task: activeTask!,
                            onSave: (updatedTask) async {
                              await saveTaskToFirestore(updatedTask);
                              setState(() {
                                showTaskPanel = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Tâche '${updatedTask.name}' sauvegardée")),
                              );
                            },
                            onClose: () {
                              setState(() {
                                showTaskPanel = false;
                              });
                            },
                            onMarkAsDone: () async {
                              activeTask!.status = 'terminée';
                              await saveTaskToFirestore(activeTask!);
                              setState(() {
                                showTaskPanel = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: () {
          setState(() {
            activeTask = CustomTask(
              name: "",
              description: "",
              project: widget.project.id, // on lie la tâche au projet par son ID
            );
            showTaskPanel = true;
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> saveTaskToFirestore(CustomTask task) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final tasksCollection = FirebaseFirestore.instance.collection('tasks');
    if (task.id.isEmpty) {
      if (task.status.isEmpty) task.status = "à venir";
      DocumentReference docRef =
      await tasksCollection.add(task.toMap(currentUser.uid));
      task.id = docRef.id;
    } else {
      await tasksCollection.doc(task.id).update(task.toMap(currentUser.uid));
    }
  }

  void _toggleStatus(CustomTask task) async {
    final nextStatus =
    (task.status == 'completed' || task.status == 'terminée') ? 'pending' : 'completed';
    task.status = nextStatus;
    await saveTaskToFirestore(task);
    setState(() {});
  }

  Future<void> _deleteTask(CustomTask task) async {
    final db = FirebaseFirestore.instance;
    await db.collection('tasks').doc(task.id).delete();
    setState(() {});
  }
}