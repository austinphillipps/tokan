import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/tasks/models/custom_task_model.dart';
import '../../features/tasks/widgets/sub_task_list_widget.dart';
import '../../features/chat/widgets/comment_section_widget.dart';

class TaskDetailPanel extends StatefulWidget {
  final CustomTask task;
  final Function(CustomTask) onSave;
  final VoidCallback onClose;
  final VoidCallback onMarkAsDone;
  final VoidCallback onCalendarRefresh;

  const TaskDetailPanel({
    Key? key,
    required this.task,
    required this.onSave,
    required this.onClose,
    required this.onMarkAsDone,
    this.onCalendarRefresh = _defaultCalendarRefresh,
  }) : super(key: key);

  static void _defaultCalendarRefresh() {}

  @override
  _TaskDetailPanelState createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends State<TaskDetailPanel> {
  /// Pile de tâches pour gérer la navigation dans les sous‐tâches
  late List<CustomTask> taskStack;
  late List<int> indexStack;

  /// Contrôleurs de champ
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController clientController;
  final TextEditingController commentController = TextEditingController();

  late TextEditingController startHourController;
  late TextEditingController startMinuteController;
  late TextEditingController endHourController;
  late TextEditingController endMinuteController;

  DateTime? _deadline;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  /// Réplication / récurrence
  late String _recurrence;
  late bool _recurrenceIncludePast;
  List<int> _recurrenceDays = [];

  /// Sélection du responsable
  String? selectedResponsableId;
  String? selectedResponsableName;
  bool _showResponsableDropdown = false;
  String responsableSearch = '';
  final TextEditingController _responsableSearchController = TextEditingController();
  late Stream<List<Map<String, String>>> _friendsStream;

  /// Sélection de projet
  Map<String, String> projectNamesById = {};
  List<String> projetsExistants = [];
  String? selectedProject;

  final FocusNode startHourFocusNode = FocusNode();
  final FocusNode startMinuteFocusNode = FocusNode();
  final FocusNode endHourFocusNode = FocusNode();
  final FocusNode endMinuteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    taskStack = [widget.task.copyWith()];
    indexStack = [];
    _loadCurrentTask();
    _fetchProjetsExistants();
    _friendsStream = _getFriends();
    _loadSelectedResponsableName();
  }

  @override
  void didUpdateWidget(covariant TaskDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      setState(() {
        taskStack = [widget.task.copyWith()];
        indexStack = [];
        _loadCurrentTask();
        _loadSelectedResponsableName();
      });
    }
  }

  void _loadCurrentTask() {
    final t = taskStack.last;
    nameController = TextEditingController(text: t.name);
    descController = TextEditingController(text: t.description);
    clientController = TextEditingController(text: t.client ?? '');
    _deadline = t.deadline;
    _startTime = t.startTime;
    _endTime = t.endTime;

    selectedProject = (t.project != null && t.project!.isNotEmpty) ? t.project : null;
    selectedResponsableId = t.responsable.isNotEmpty ? t.responsable : null;

    startHourController = TextEditingController(
      text: _startTime != null ? _startTime!.hour.toString().padLeft(2, '0') : '',
    );
    startMinuteController = TextEditingController(
      text: _startTime != null ? _startTime!.minute.toString().padLeft(2, '0') : '',
    );
    endHourController = TextEditingController(
      text: _endTime != null ? _endTime!.hour.toString().padLeft(2, '0') : '',
    );
    endMinuteController = TextEditingController(
      text: _endTime != null ? _endTime!.minute.toString().padLeft(2, '0') : '',
    );

    _recurrence = t.recurrenceType ?? 'none';
    _recurrenceIncludePast = t.recurrenceIncludePast ?? false;
    _recurrenceDays = List<int>.from(t.recurrenceDays ?? []);
  }

  Future<void> _loadSelectedResponsableName() async {
    if (selectedResponsableId == null || selectedResponsableId!.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedResponsableId)
        .get();
    if (doc.exists) {
      setState(() {
        selectedResponsableName = (doc.data()?['displayName'] as String?) ?? '';
      });
    }
  }

  Stream<List<Map<String, String>>> _getFriends() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('collaborations')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snap) async {
      final list = <Map<String, String>>[];
      for (var d in snap.docs) {
        final data = d.data();
        final from = data['from'] as String?;
        final to = data['to'] as String?;
        if (from == null || to == null) continue;
        if (from == user.uid || to == user.uid) {
          final other = from == user.uid ? to : from;
          final udoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(other)
              .get();
          if (!udoc.exists) continue;
          list.add({
            'uid': other,
            'displayName': udoc.data()?['displayName'] ?? 'Utilisateur',
          });
        }
      }
      return list;
    });
  }

  Future<void> _fetchProjetsExistants() async {
    final snap = await FirebaseFirestore.instance.collection('projects').get();
    final names = <String, String>{};
    for (var d in snap.docs) {
      names[d.id] = (d.data()['name'] as String?) ?? 'Sans nom';
    }
    setState(() {
      projectNamesById = names;
      projetsExistants = names.keys.toList();
    });
  }

  void _updateCurrentTaskFromUI() {
    final t = taskStack.last;
    t.name = nameController.text.trim();
    t.description = descController.text.trim();
    t.client = clientController.text.trim().isEmpty ? null : clientController.text;
    if (t.status.isEmpty) t.status = 'à venir';
    t.deadline = _deadline;

    final sh = int.tryParse(startHourController.text);
    final sm = int.tryParse(startMinuteController.text);
    if (sh != null && sm != null) {
      _startTime = TimeOfDay(hour: sh, minute: sm);
    }
    final eh = int.tryParse(endHourController.text);
    final em = int.tryParse(endMinuteController.text);
    if (eh != null && em != null) {
      _endTime = TimeOfDay(hour: eh, minute: em);
    }
    t.startTime = _startTime;
    t.endTime = _endTime;
    t.responsable = selectedResponsableId ?? '';
    t.project = selectedProject ?? '';

    t.recurrenceType = _recurrence;
    t.recurrenceIncludePast = _recurrenceIncludePast;
    t.recurrenceDays = _recurrenceDays.isNotEmpty ? List<int>.from(_recurrenceDays) : null;
  }

  Future<void> _openRecurrenceDialog() async {
    String tempRecurrence = _recurrence;
    bool tempIncludePast = _recurrenceIncludePast;
    List<int> tempRecDays = List<int>.from(_recurrenceDays);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Paramètres de récurrence"),
          content: StatefulBuilder(
            builder: (ctx2, setState2) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: tempRecurrence,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Aucune')),
                      DropdownMenuItem(value: 'sameDay', child: Text('Tous les mêmes jours')),
                      DropdownMenuItem(value: 'weekdays', child: Text('Jours de semaine (lun–ven)')),
                      DropdownMenuItem(value: 'weekends', child: Text('Week‐ends (sam–dim)')),
                      DropdownMenuItem(value: 'customDays', child: Text('Choisir les jours')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState2(() => tempRecurrence = value);
                      }
                    },
                  ),
                  if (tempRecurrence == 'customDays')
                    Column(
                      children: List.generate(7, (i) {
                        const dayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(dayNames[i]),
                          value: tempRecDays.contains(i),
                          onChanged: (v) {
                            setState2(() {
                              if (v == true) {
                                if (!tempRecDays.contains(i)) tempRecDays.add(i);
                              } else {
                                tempRecDays.remove(i);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Inclure les tâches antérieures"),
                    value: tempIncludePast,
                    onChanged: (v) {
                      if (v != null) {
                        setState2(() => tempIncludePast = v);
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _recurrence = tempRecurrence;
                  _recurrenceIncludePast = tempIncludePast;
                  _recurrenceDays = tempRecurrence == 'customDays' ? List<int>.from(tempRecDays) : [];
                });
                Navigator.of(ctx).pop();
              },
              child: const Text("Valider"),
            ),
          ],
        );
      },
    );
  }

  void _goBack() {
    if (taskStack.length <= 1) return;

    _updateCurrentTaskFromUI();
    final last = taskStack.removeLast();
    final idx = indexStack.removeLast();
    taskStack.last.subTasks[idx] = last;
    setState(() {
      _loadCurrentTask();
      _loadSelectedResponsableName();
    });
  }

  void _navigateToSubTask(int idx) {
    if (taskStack.isEmpty) return;
    final parent = taskStack.last;
    if (parent.subTasks.isEmpty || idx < 0 || idx >= parent.subTasks.length) {
      return;
    }
    _updateCurrentTaskFromUI();
    final sub = parent.subTasks[idx].copyWith();

    setState(() {
      taskStack.add(sub);
      indexStack.add(idx);
      _loadCurrentTask();
      _loadSelectedResponsableName();
    });
  }

  Future<void> _pickDeadline() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime(now.year + 5),
      builder: (c, child) => Theme(data: theme, child: child!),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    clientController.dispose();
    commentController.dispose();
    startHourController.dispose();
    startMinuteController.dispose();
    endHourController.dispose();
    endMinuteController.dispose();
    _responsableSearchController.dispose();
    startHourFocusNode.dispose();
    startMinuteFocusNode.dispose();
    endHourFocusNode.dispose();
    endMinuteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentTask = taskStack.last;

    final bgColor = cs.background;
    final onBg = cs.onBackground;
    final onBgFaded = onBg.withOpacity(0.7);
    final onBgFadedLight = onBg.withOpacity(0.54);
    final surfaceColor = cs.surface;
    final surfaceVariant = cs.surfaceVariant ?? surfaceColor;
    final borderColor = onBg.withOpacity(0.3);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_showResponsableDropdown) {
          setState(() => _showResponsableDropdown = false);
        }
      },
      child: Row(
        children: [
          if (taskStack.length > 1)
            Container(
              width: 20,
              color: bgColor,
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  taskStack[taskStack.length - 2].name,
                  style: TextStyle(color: onBg.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Expanded(
            child: Container(
              color: bgColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- En‐tête : bouton retour (si sous‐tâche) et fermeture ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (taskStack.length > 1)
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: onBg),
                            onPressed: _goBack,
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: onBg),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),

                    if (taskStack.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          taskStack[taskStack.length - 2].name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: onBg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // --- Champ nom de tâche ---
                    if (taskStack.length > 1)
                      Row(
                        children: [
                          Container(
                            width: 2,
                            height: 20,
                            color: onBg.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              style: TextStyle(
                                fontSize: 16,
                                color: onBg,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Nouvelle tâche…",
                                hintStyle: TextStyle(color: onBgFadedLight),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: onBg,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Nouvelle tâche…",
                          hintStyle: TextStyle(color: onBgFadedLight),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // --- Champ client (optionnel) ---
                    TextField(
                      controller: clientController,
                      style: TextStyle(color: onBg),
                      decoration: InputDecoration(
                        labelText: "Client (optionnel)",
                        labelStyle: TextStyle(color: onBgFaded),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- Sélecteur de date d’échéance ---
                    InkWell(
                      onTap: _pickDeadline,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: onBg),
                            const SizedBox(width: 8),
                            Text("Échéance : ", style: TextStyle(color: onBg)),
                            const SizedBox(width: 8),
                            Text(
                              _deadline == null
                                  ? DateFormat('yyyy-MM-dd').format(DateTime.now())
                                  : DateFormat('yyyy-MM-dd').format(_deadline!),
                              style: TextStyle(color: onBgFaded),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- Champ Récurrence (ouvre un dialogue) ---
                    Text(
                      "Récurrence :",
                      style: TextStyle(
                        color: onBg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _openRecurrenceDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4),
                          color: surfaceColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _recurrence == 'none'
                                      ? "Aucune"
                                      : _recurrence == 'sameDay'
                                      ? "Tous les mêmes jours"
                                      : _recurrence == 'weekdays'
                                      ? "Jours de semaine"
                                      : _recurrence == 'weekends'
                                      ? "Week‐ends"
                                      : _recurrence == 'customDays'
                                      ? _recurrenceDays
                                      .map((i) => [
                                    'Lun',
                                    'Mar',
                                    'Mer',
                                    'Jeu',
                                    'Ven',
                                    'Sam',
                                    'Dim'
                                  ][i])
                                      .join(', ')
                                      : "Personnalisé",
                                  style: TextStyle(color: onBg),
                                ),
                                if (_recurrenceIncludePast)
                                  Text(
                                    "Inclut tâches antérieures",
                                    style:
                                    TextStyle(color: onBgFadedLight, fontSize: 12),
                                  ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: onBgFadedLight),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Heures de début / fin ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Heure de début
                        Row(
                          children: [
                            Text("Début: ", style: TextStyle(color: onBg)),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: startHourController,
                                focusNode: startHourFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "HH",
                                  hintStyle: TextStyle(color: onBgFadedLight),
                                  counterText: "",
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                                maxLength: 2,
                                style: TextStyle(color: onBg),
                                onChanged: (v) {
                                  if (v.length >= 2) {
                                    FocusScope.of(context).requestFocus(startMinuteFocusNode);
                                  }
                                },
                              ),
                            ),
                            Text(":", style: TextStyle(color: onBgFaded)),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: startMinuteController,
                                focusNode: startMinuteFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "MM",
                                  hintStyle: TextStyle(color: onBgFadedLight),
                                  counterText: "",
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                                maxLength: 2,
                                style: TextStyle(color: onBg),
                              ),
                            ),
                          ],
                        ),

                        // Heure de fin
                        Row(
                          children: [
                            Text("Fin: ", style: TextStyle(color: onBg)),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: endHourController,
                                focusNode: endHourFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "HH",
                                  hintStyle: TextStyle(color: onBgFadedLight),
                                  counterText: "",
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                                maxLength: 2,
                                style: TextStyle(color: onBg),
                                onChanged: (v) {
                                  if (v.length >= 2) {
                                    FocusScope.of(context).requestFocus(endMinuteFocusNode);
                                  }
                                },
                              ),
                            ),
                            Text(":", style: TextStyle(color: onBgFaded)),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: endMinuteController,
                                focusNode: endMinuteFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: "MM",
                                  hintStyle: TextStyle(color: onBgFadedLight),
                                  counterText: "",
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                                maxLength: 2,
                                style: TextStyle(color: onBg),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Sélecteur de responsable ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Responsable :", style: TextStyle(color: onBg)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => setState(() => _showResponsableDropdown = !_showResponsableDropdown),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(4),
                                color: surfaceColor,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedResponsableName ?? "Sélectionnez un responsable",
                                    style: TextStyle(
                                      color: selectedResponsableName != null ? onBg : onBgFadedLight,
                                    ),
                                  ),
                                  Icon(
                                    _showResponsableDropdown
                                        ? Icons.arrow_drop_up
                                        : Icons.arrow_drop_down,
                                    color: onBgFadedLight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showResponsableDropdown)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: surfaceVariant,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _responsableSearchController,
                                    style: TextStyle(color: onBg),
                                    decoration: InputDecoration(
                                      hintText: "Rechercher…",
                                      hintStyle: TextStyle(color: onBgFadedLight),
                                      prefixIcon: Icon(Icons.search, color: onBgFadedLight),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(color: borderColor),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    ),
                                    onChanged: (v) => setState(() => responsableSearch = v.trim().toLowerCase()),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 200,
                                    child: StreamBuilder<List<Map<String, String>>>(
                                      stream: _friendsStream,
                                      builder: (ctx, snap) {
                                        if (!snap.hasData) {
                                          return Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation(onBg),
                                            ),
                                          );
                                        }
                                        final results = snap.data!
                                            .where((f) =>
                                            f['displayName']!
                                                .toLowerCase()
                                                .contains(responsableSearch))
                                            .toList();
                                        if (results.isEmpty) {
                                          return Center(
                                            child: Text(
                                              "Aucun ami trouvé",
                                              style: TextStyle(color: onBgFadedLight),
                                            ),
                                          );
                                        }
                                        return ListView.builder(
                                          itemCount: results.length,
                                          itemBuilder: (c, i) {
                                            final f = results[i];
                                            return ListTile(
                                              title: Text(
                                                f['displayName']!,
                                                style: TextStyle(color: onBg),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  selectedResponsableId = f['uid'];
                                                  selectedResponsableName = f['displayName'];
                                                  _showResponsableDropdown = false;
                                                  _responsableSearchController.clear();
                                                  responsableSearch = '';
                                                });
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
                        ],
                      ),
                    ),

                    // --- Sélecteur de projet (sans bouton "+") ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.work, color: onBg),
                          const SizedBox(width: 8),
                          Text("Projet :", style: TextStyle(color: onBg)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedProject,
                              hint: Text(
                                "Sélectionnez un projet",
                                style: TextStyle(color: onBgFadedLight),
                              ),
                              dropdownColor: surfaceVariant,
                              style: TextStyle(color: onBg),
                              onChanged: (newProjectId) => setState(() => selectedProject = newProjectId),
                              items: projetsExistants.map((projId) {
                                return DropdownMenuItem<String>(
                                  value: projId,
                                  child: Text(projectNamesById[projId]!),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: borderColor, height: 24),

                    // --- Champ description ---
                    Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onBg,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      style: TextStyle(color: onBg),
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: surfaceVariant,
                        hintText: "Décris la tâche ici…",
                        hintStyle: TextStyle(color: onBgFadedLight),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Sous‐tâches ---
                    SubTaskListWidget(
                      subTasks: currentTask.subTasks,
                      onEdit: (idx) => _navigateToSubTask(idx),
                      onDelete: (i) => setState(() => currentTask.subTasks.removeAt(i)),
                      onToggleStatus: (i) {
                        setState(() {
                          final s = currentTask.subTasks[i];
                          s.status = s.status == 'terminé' ? 'à venir' : 'terminé';
                        });
                      },
                      onAdd: (name) =>
                          setState(() => currentTask.subTasks.add(CustomTask(name: name, description: ''))),
                    ),

                    const SizedBox(height: 16),

                    // --- Section commentaires ---
                    CommentSectionWidget(controller: commentController),

                    const SizedBox(height: 16),

                    // --- Bouton Sauvegarder ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            _updateCurrentTaskFromUI();

                            // Vérification des heures de début/fin
                            if (_startTime != null && _endTime != null) {
                              final sh = _startTime!.hour;
                              final sm = _startTime!.minute;
                              final eh = _endTime!.hour;
                              final em = _endTime!.minute;
                              if (sh > eh || (sh == eh && sm >= em)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "L'heure de fin doit être ultérieure à celle de début.",
                                      style: TextStyle(color: onBg),
                                    ),
                                    backgroundColor: surfaceColor,
                                  ),
                                );
                                return;
                              }
                            }

                            try {
                              await widget.onSave(taskStack.last);
                              widget.onCalendarRefresh();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Tâche '${taskStack.last.name}' enregistrée",
                                    style: TextStyle(color: onBg),
                                  ),
                                  backgroundColor: surfaceColor,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Erreur lors de la sauvegarde : $e",
                                    style: TextStyle(color: onBg),
                                  ),
                                  backgroundColor: surfaceColor,
                                ),
                              );
                              return;
                            }

                            widget.onClose();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                          ),
                          child: Text(
                            "Enregistrer",
                            style: TextStyle(color: cs.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}