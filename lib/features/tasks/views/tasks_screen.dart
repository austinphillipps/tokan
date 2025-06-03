import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import des vues « Liste » et « Calendrier »
import '../widgets/task_list_mode_widget.dart';
import '../widgets/task_calendar_mode_widget.dart';

// Import du panneau de détails de tâche
import '../../../shared/widgets/task_details_panel_widget.dart';

import '../../tasks/models/custom_task_model.dart';

// Import de AppColors (défini dans votre main.dart)
import '../../../main.dart';

enum TaskViewMode { list, calendar }

class TasksPage extends StatefulWidget {
  /// Si non-null : affiche uniquement les tâches du projet {projectId}
  /// Sinon : affiche toutes les tâches de l’utilisateur (racine + projets)
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

  final ValueNotifier<int> _calendarRefreshNotifier = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On récupère la couleur de fond depuis le Theme
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1) La liste / calendrier en fond
          StreamBuilder<List<CustomTask>>(
            stream: _getTasksStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Erreur : ${snap.error}',
                    // On utilise la couleur “onBackground” pour le texte d’erreur
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  ),
                );
              }
              if (!snap.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    // On colore l’indicateur de progression en vert (validation / accent)
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                  ),
                );
              }
              final tasks = snap.data!;
              return Column(
                children: [
                  _buildHorizontalMenu(),
                  Expanded(child: _buildView(tasks)),
                ],
              );
            },
          ),

          // 2) Si panneau ouvert, intercepteur de clics hors du panneau
          if (showTaskPanel)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    showTaskPanel = false;
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          // 3) Le panneau de détails, affiché au-dessus
          if (showTaskPanel && activeTask != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                // Taille du panneau : 1/3 de la largeur de l’écran
                width: MediaQuery.of(context).size.width / 3,
                // On utilise la couleur “surface” du Theme (gris sombre en dark, blanc en light)
                color: Theme.of(context).colorScheme.surface,
                child: TaskDetailPanel(
                  task: activeTask!,
                  onSave: (updated) async {
                    await _saveTask(updated);
                    setState(() => showTaskPanel = false);
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

      // Bouton flottant d’ajout de tâche : masqué lorsque le panneau est ouvert
      floatingActionButton: showTaskPanel
          ? null
          : FloatingActionButton(
        onPressed: () {
          setState(() {
            activeTask = CustomTask(
              name: '',
              description: '',
              project: widget.projectId,
            );
            showTaskPanel = true;
          });
        },
        // On force la couleur de fond en violet (AppColors.purple)
        backgroundColor: AppColors.purple,
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
          t.responsable = uid;
          await _saveTask(t);
          setState(() {});
        },
        onProjectChanged: (t, id) async {
          t.project = id;
          // Si la tâche est nouvelle (id vide), on créera directement sous projects/{id}/tasks
          if (t.id.isEmpty) {
            await _saveTask(t);
          } else {
            // Sinon, tâche existante en racine, on migre
            await _migrateToProject(t);
          }
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
            name: '',
            description: '',
            project: widget.projectId,
          );
          showTaskPanel = true;
        }),
      );
    }
  }

  /// Flux de tâches :
  /// • Si widget.projectId non null → écoute /projects/{projectId}/tasks
  /// • Sinon → écoute collectionGroup('tasks'), puis filtre client-side createdBy == me
  Stream<List<CustomTask>> _getTasksStream() {
    final db = FirebaseFirestore.instance;
    final me = FirebaseAuth.instance.currentUser?.uid;

    if (widget.projectId != null && widget.projectId!.isNotEmpty) {
      return db
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .snapshots()
          .map((snap) {
        final list = snap.docs
            .map((d) => CustomTask.fromMap(d.data(), d.id))
            .toList();
        list.sort((a, b) =>
            (a.deadline ?? DateTime(1970)).compareTo(b.deadline ?? DateTime(1970)));
        return list;
      });
    } else {
      return db.collectionGroup('tasks').snapshots().map((snap) {
        var list = snap.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['createdBy'] == me;
        }).map((d) => CustomTask.fromMap(d.data(), d.id)).toList();

        if (filterCollaborator?.isNotEmpty == true) {
          list = list.where((t) => t.responsable == filterCollaborator).toList();
        }
        if (filterDate != null) {
          list = list
              .where((t) =>
          t.deadline != null && _sameDay(t.deadline!, filterDate!))
              .toList();
        }
        list.sort((a, b) =>
            (a.deadline ?? DateTime(1970)).compareTo(b.deadline ?? DateTime(1970)));
        return list;
      });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Sauvegarde ou mise à jour d'une tâche, avec gestion de migration racine → projet
  Future<void> _saveTask(CustomTask task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final db = FirebaseFirestore.instance;

    // --- 1) Si on est “dans un projet” (page projet courante) ---
    if (widget.projectId != null && widget.projectId!.isNotEmpty) {
      final refProj = db
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks');
      final data = task.toMap(user.uid)
        ..['updatedBy'] = user.uid
        ..['updatedAt'] = FieldValue.serverTimestamp();

      if (task.id.isEmpty) {
        // Nouvelle tâche DANS ce projet
        if (task.status.isEmpty) task.status = 'à venir';
        final docRef = await refProj.add(data);
        task.id = docRef.id;
      } else {
        // Tâche existante DANS ce projet : simple update
        await refProj.doc(task.id).update(data);
      }
      return;
    }

    // --- 2) Sinon – on est dans la “vue principale” (page toutes mes tâches) ---
    if (task.project != null && task.project!.isNotEmpty) {
      final refProj = db
          .collection('projects')
          .doc(task.project)
          .collection('tasks');
      final data = task.toMap(user.uid)
        ..['updatedBy'] = user.uid
        ..['updatedAt'] = FieldValue.serverTimestamp();

      if (task.id.isEmpty) {
        // 2a) Nouvelle tâche qui passe directement dans un projet : création
        if (task.status.isEmpty) task.status = 'à venir';
        final docRef = await refProj.add(data);
        task.id = docRef.id;
      } else {
        // 2b) Tâche existante en “racine”, on doit vérifier si elle existe déjà dans le projet
        final snapshot = await refProj.doc(task.id).get();
        if (snapshot.exists) {
          // 2b-i) si le doc existe déjà dans projects/{…}/tasks → simple update
          await refProj.doc(task.id).update(data);
        } else {
          // 2b-ii) sinon, on migre la tâche
          await _migrateToProject(task);
        }
      }
      return;
    }

    // --- 3) Cas “racine” (pas de projet sélectionné) ---
    final refRoot = db.collection('tasks');
    final dataRoot = task.toMap(user.uid)
      ..['updatedBy'] = user.uid
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (task.id.isEmpty) {
      // Nouvelle tâche en « racine »
      if (task.status.isEmpty) task.status = 'à venir';
      final docRef = await refRoot.add(dataRoot);
      task.id = docRef.id;
    } else {
      // Mise à jour d’une tâche existante en « racine »
      await refRoot.doc(task.id).update(dataRoot);
    }
  }

  /// Migration manuelle : quand on change le projet d'une tâche déjà en racine
  Future<void> _migrateToProject(CustomTask task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final db = FirebaseFirestore.instance;
    final data = task.toMap(user.uid)
      ..['updatedBy'] = user.uid
      ..['updatedAt'] = FieldValue.serverTimestamp();

    final projRef = db
        .collection('projects')
        .doc(task.project)
        .collection('tasks');

    // 1) Création dans le projet
    final docRef = await projRef.add(data);

    // 2) Suppression de l’ancienne tâche dans “tasks/{task.id}”
    if (task.id.isNotEmpty) {
      await db.collection('tasks').doc(task.id).delete();
    }
    // 3) Mise à jour de l’ID local pour pointer vers le nouvel ID dans le projet
    task.id = docRef.id;
  }

  void _toggleStatus(CustomTask task) async {
    final nextStatus = task.status == 'completed' ? 'pending' : 'completed';
    task.status = nextStatus;
    await _saveTask(task);
    _calendarRefreshNotifier.value++;
  }

  /// Barre d'outils en haut : bascule Liste/Calendrier, filtres (sur Liste)
  Widget _buildHorizontalMenu() {
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
              });
            },
            // On peut (éventuellement) surcharger les couleurs sélectionnées :
            color: Theme.of(context).colorScheme.onBackground,
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
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              ))
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
                    // On force le thème sur le datePicker : si sombre, fond sombre, etc.
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme(
                          brightness: Theme.of(context).brightness,
                          primary: AppColors.blue, // jour sélectionné en bleu
                          onPrimary: Colors.white,
                          secondary: AppColors.blue,
                          onSecondary: Colors.white,
                          error: Colors.red,
                          onError: Colors.white,
                          background: Theme.of(context).scaffoldBackgroundColor,
                          onBackground: Theme.of(context).colorScheme.onBackground,
                          surface: Theme.of(context).colorScheme.surface,
                          onSurface: Theme.of(context).colorScheme.onBackground,
                        ),
                        dialogBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => filterDate = picked);
                }
              },
              // Utilise la couleur par défaut de l’ElevatedButton (violet)
              child: Text(
                filterDate == null
                    ? 'Filtrer par date'
                    : DateFormat('yyyy-MM-dd').format(filterDate!),
              ),
            ),
            if (filterDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                // On hérite la couleur d’icône active (bleu)
                onPressed: () => setState(() => filterDate = null),
              ),
          ],
        ],
      ),
    );
  }
}
