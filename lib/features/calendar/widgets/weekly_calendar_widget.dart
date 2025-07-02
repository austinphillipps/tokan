import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'calendar_task_widget.dart';
import '../../tasks/models/custom_task_model.dart';
import '../../../shared/widgets/task_details_panel_widget.dart';
import '../../../shared/widgets/resizable_task_cell_widget.dart';

class PositionedEvent {
  final CalendarTask task;
  final double top;
  final double height;

  /// Rang de cette tâche parmi celles qui se chevauchent (columnIndex)
  final int columnIndex;

  /// Nombre total de tâches se chevauchant en même temps (colCount)
  int colCount;

  PositionedEvent({
    required this.task,
    required this.top,
    required this.height,
    required this.columnIndex,
    required this.colCount,
  });
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const double _cellHeight = 60.0;
  static const double _hourColumnWidth = 60.0;

  late DateTime _weekStart;
  late DateTime _currentMonth;
  bool _showMonthPopup = false;

  /// Liste de toutes les tâches récupérées depuis Firestore
  List<CalendarTask> _tasks = [];

  /// Souscription (listener) sur la collection Firestore
  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  double? _dragStartDy;
  double? _dragCurrentDy;
  String? _dragDayKey;

  /// Pour “geler” l’affichage pendant un drag
  final Map<String, List<PositionedEvent>> _frozenLayouts = {};

  /// Mise en cache pour éviter de recalculer le layout d’un jour plusieurs fois
  final Map<String, List<PositionedEvent>> _cachedLayouts = {};

  @override
  void initState() {
    super.initState();
    _initWeekStart();
    _currentMonth = DateTime.now();
    _subscribeToTasks();
  }

  @override
  void dispose() {
    // Annuler la souscription pour ne plus écouter Firestore
    _tasksSubscription?.cancel();
    super.dispose();
  }

  void _initWeekStart() {
    final now = DateTime.now();
    final diff = now.weekday - DateTime.monday;
    _weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: diff));
  }

  /// Souscription Firestore pour écouter la collection 'tasks'
  void _subscribeToTasks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _tasksSubscription = FirebaseFirestore.instance
        .collection('tasks')
        .where('createdBy', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      // Vérifier si le widget est encore monté
      if (!mounted) return;

      final loaded = snapshot.docs.map((doc) {
        final data = doc.data();
        final deadlineStr = data['deadline']?.toString() ?? '';
        final startStr = data['startTime']?.toString() ?? '';
        final endStr = data['endTime']?.toString() ?? '';
        final title = data['name']?.toString() ?? '';

        final start = _combineDateAndTime(deadlineStr, startStr);
        final end = _combineDateAndTime(deadlineStr, endStr);

        return CalendarTask(
          id: doc.id,
          start: start,
          end: end,
          title: title,
        );
      }).toList();

      setState(() {
        _tasks = loaded;
        _frozenLayouts.clear();
        _cachedLayouts.clear();
      });
    });
  }

  /// Méthode qui construit un DateTime à partir d’une date “yyyy-MM-dd” et d’une heure “HH:mm”
  static DateTime _combineDateAndTime(String dateStr, String hhmmStr) {
    if (dateStr.isEmpty) {
      return DateTime.now();
    }
    final date = DateTime.parse(dateStr);
    if (hhmmStr.length == 5 && hhmmStr.contains(':')) {
      final h = int.parse(hhmmStr.substring(0, 2));
      final m = int.parse(hhmmStr.substring(3, 5));
      return DateTime(date.year, date.month, date.day, h, m);
    }
    return date;
  }

  void _goToPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _initWeekStart();
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _onSelectDayFromMonth(DateTime day) {
    setState(() {
      _showMonthPopup = false;
    });
    final diff = day.weekday - DateTime.monday;
    final newWeekStart = day.subtract(Duration(days: diff));
    setState(() {
      _weekStart =
          DateTime(newWeekStart.year, newWeekStart.month, newWeekStart.day);
    });
  }

  String _monthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return months[month - 1];
  }

  String _weekdayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }

  /// Grille mensuelle (pop-up)
  Widget _buildMonthGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDay.weekday;
    final lastDay =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    List<Widget> rows = [];
    int dayCounter = 1;
    int offset = firstWeekday - 1;

    for (int w = 0; w < 6; w++) {
      List<Widget> rowDays = [];
      for (int wd = 0; wd < 7; wd++) {
        int idx = w * 7 + wd;
        if (idx < offset || dayCounter > lastDay) {
          rowDays.add(Expanded(child: Container()));
        } else {
          final d =
          DateTime(_currentMonth.year, _currentMonth.month, dayCounter);
          rowDays.add(
            Expanded(
              child: InkWell(
                onTap: () => _onSelectDayFromMonth(d),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text('$dayCounter',
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }
      rows.add(Row(children: rowDays));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _goToPreviousMonth,
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
            Text(
              '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
              style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _goToNextMonth,
              icon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
        Expanded(child: Column(children: rows)),
      ],
    );
  }

  Widget _buildHeaderRow() {
    List<Widget> dayHeaders = [];
    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      dayHeaders.add(
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              border: Border(
                left: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${_weekdayName(day.weekday)}\n${day.day}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(width: _hourColumnWidth, height: 50, color: Colors.grey[800]),
        Expanded(child: Row(children: dayHeaders)),
      ],
    );
  }

  /// Algorithme de partitionnement : on attribue à chaque tâche la première colonne libre
  /// pour qu'il n'y ait de chevauchement QUE si les tâches se recouvrent vraiment.
  List<PositionedEvent> _computeLayoutForDay(List<CalendarTask> tasksOfDay) {
    if (tasksOfDay.isEmpty) return [];

    // 1) Trier par heure de début
    tasksOfDay.sort((a, b) => a.start.compareTo(b.start));

    // Liste pour stocker la fin de la dernière tâche de chaque "colonne"
    final columnEndTimes = <DateTime>[];

    // Résultat final
    final results = <PositionedEvent>[];

    for (final task in tasksOfDay) {
      // Trouver la première colonne dont la fin n'est pas après le début de la task
      int chosenColumn = -1;
      for (int i = 0; i < columnEndTimes.length; i++) {
        // Si la colonne i se termine avant ou pile à l'heure où task commence, c'est libre
        if (!columnEndTimes[i].isAfter(task.start)) {
          chosenColumn = i;
          // On met à jour la fin de la colonne
          columnEndTimes[i] = task.end;
          break;
        }
      }

      // Si aucune colonne n'est libre, on en crée une nouvelle
      if (chosenColumn == -1) {
        chosenColumn = columnEndTimes.length;
        columnEndTimes.add(task.end);
      }

      final startMinutes = task.start.hour * 60 + task.start.minute;
      final endMinutes = task.end.hour * 60 + task.end.minute;
      final top = (startMinutes / 60.0) * _cellHeight;
      final height = ((endMinutes - startMinutes) / 60.0) * _cellHeight;

      results.add(
        PositionedEvent(
          task: task,
          top: top,
          height: height,
          columnIndex: chosenColumn,
          colCount: 1, // On mettra à jour après
        ),
      );
    }

    // Le nombre total de colonnes utilisées
    final totalCols = columnEndTimes.length;
    // On met à jour colCount pour chacune
    for (final pe in results) {
      pe.colCount = totalCols;
    }

    return results;
  }

  /// Renvoie la liste de [PositionedEvent] pour un jour donné (avec mise en cache).
  List<PositionedEvent> _getLayoutForDay(DateTime dayDate) {
    final dateKey = DateFormat('yyyy-MM-dd').format(dayDate);

    // Filtrer les tâches de ce jour
    final tasksForDay = _tasks.where((t) {
      return t.start.year == dayDate.year &&
          t.start.month == dayDate.month &&
          t.start.day == dayDate.day;
    }).toList();

    // Si on est en plein drag, on "gèle" l'affichage
    if (_dragDayKey == dateKey &&
        _dragStartDy != null &&
        _frozenLayouts.containsKey(dateKey)) {
      return _frozenLayouts[dateKey]!;
    }

    // Retour cache si déjà calculé
    if (_cachedLayouts.containsKey(dateKey)) {
      return _cachedLayouts[dateKey]!;
    }

    final layout = _computeLayoutForDay(tasksForDay);
    _cachedLayouts[dateKey] = layout;
    return layout;
  }

  void _updateTaskInFirestore(CalendarTask task) {
    final startH = task.start.hour.toString().padLeft(2, '0');
    final startM = task.start.minute.toString().padLeft(2, '0');
    final endH = task.end.hour.toString().padLeft(2, '0');
    final endM = task.end.minute.toString().padLeft(2, '0');

    FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
      'startTime': '$startH:$startM',
      'endTime': '$endH:$endM',
      'deadline': DateFormat('yyyy-MM-dd').format(task.start),
    }).catchError((err) {
      debugPrint('Erreur update : $err');
    });
  }

  Future<void> _createTaskDialog(DateTime start, DateTime end) async {
    String title = '';
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Créer une tâche'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Titre de la tâche'),
            onChanged: (val) => title = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('tasks').add({
                    'deadline': DateFormat('yyyy-MM-dd').format(start),
                    'startTime':
                    '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                    'endTime':
                    '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                    'name': title.trim(),
                    'status': 'à venir',
                    'createdBy': FirebaseAuth.instance.currentUser?.uid,
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  /// Ouvre la modale “détails d’une tâche”
  void _openTaskDetails(CalendarTask task) async {
    final docSnap = await FirebaseFirestore.instance
        .collection('tasks')
        .doc(task.id)
        .get();
    if (!docSnap.exists) return;

    final data = docSnap.data()!;
    final deadlineStr = data['deadline']?.toString() ?? '';
    final startStr = data['startTime']?.toString() ?? '';
    final endStr = data['endTime']?.toString() ?? '';
    final st = _combineDateAndTime(deadlineStr, startStr);
    final et = _combineDateAndTime(deadlineStr, endStr);

    final name = data['name']?.toString() ?? '';
    final desc = data['description']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'à venir';

    DateTime? deadline;
    try {
      deadline =
      deadlineStr.isNotEmpty ? DateTime.parse(deadlineStr) : null;
    } catch (_) {
      deadline = null;
    }

    final customTask = CustomTask(
      name: name,
      description: desc,
      deadline: deadline,
      startTime: TimeOfDay(hour: st.hour, minute: st.minute),
      endTime: TimeOfDay(hour: et.hour, minute: et.minute),
      status: status,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TaskDetailPanel(
              task: customTask,
              onSave: (updatedTask) async {
                await _saveCustomTaskToFirestore(task.id, updatedTask);
                Navigator.pop(ctx);
              },
              onClose: () {
                Navigator.pop(ctx);
              },
              onMarkAsDone: () async {
                await FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(task.id)
                    .update({'status': 'terminé'});
                Navigator.pop(ctx);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCustomTaskToFirestore(
      String docId, CustomTask t) async {
    final startH = t.startTime?.hour ?? 0;
    final startM = t.startTime?.minute ?? 0;
    final endH = t.endTime?.hour ?? 0;
    final endM = t.endTime?.minute ?? 0;

    final mapData = {
      'name': t.name,
      'description': t.description,
      'deadline': (t.deadline != null)
          ? DateFormat('yyyy-MM-dd').format(t.deadline!)
          : null,
      'startTime':
      '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')}',
      'endTime':
      '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}',
      'status': t.status,
    };
    mapData.removeWhere((k, v) => v == null);

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(docId)
        .update(mapData);
  }

  Widget _buildDayColumn(DateTime dayDate) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);
        final layout = _getLayoutForDay(dayDate);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            setState(() {
              _dragDayKey = dayKey;
              _dragStartDy = details.localPosition.dy;
              _dragCurrentDy = details.localPosition.dy;
              _frozenLayouts[dayKey] = layout;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _dragCurrentDy = details.localPosition.dy;
            });
          },
          onPanEnd: (details) {
            if (_dragStartDy != null && _dragCurrentDy != null) {
              final startY = min(_dragStartDy!, _dragCurrentDy!);
              final endY = max(_dragStartDy!, _dragCurrentDy!);

              int startMin = (startY / _cellHeight * 60).round();
              int endMin = (endY / _cellHeight * 60).round();
              if (startMin == endMin) {
                endMin += 30;
              }

              final startDT = DateTime(
                dayDate.year,
                dayDate.month,
                dayDate.day,
                startMin ~/ 60,
                startMin % 60,
              );
              final endDT = DateTime(
                dayDate.year,
                dayDate.month,
                dayDate.day,
                endMin ~/ 60,
                endMin % 60,
              );

              _createTaskDialog(startDT, endDT);
            }

            setState(() {
              _dragStartDy = null;
              _dragCurrentDy = null;
              _dragDayKey = null;
              _frozenLayouts.remove(dayKey);
            });
          },
          child: Container(
            height: 24 * _cellHeight,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(left: BorderSide(color: Colors.grey[700]!)),
            ),
            child: Stack(
              children: [
                // 24 conteneurs pour la grille horaire
                Column(
                  children: List.generate(24, (hour) {
                    return Container(
                      height: _cellHeight,
                      decoration: BoxDecoration(
                        border:
                        Border(top: BorderSide(color: Colors.grey[700]!)),
                      ),
                    );
                  }),
                ),

                // Tâches positionnées
                ...layout.map((pe) {
                  // Petit margin pour éviter le chevauchement visuel
                  final margin = 2.0;
                  final colWidth = constraints.maxWidth / pe.colCount;
                  final leftPx = pe.columnIndex * colWidth + margin;
                  final effectiveWidth = colWidth - 2 * margin;

                  return ResizableTaskCell(
                    key: ValueKey(pe.task.id),
                    task: pe.task,
                    top: pe.top,
                    height: pe.height,
                    availableWidth: effectiveWidth,
                    leftOffset: leftPx,
                    column: pe.columnIndex,
                    totalColumns: pe.colCount,
                    cellHeight: _cellHeight,
                    maxHeight: 24 * _cellHeight, // <-- Ajout du paramètre manquant.
                    onTaskResized: (updated) {
                      setState(() {
                        final ix =
                        _tasks.indexWhere((t) => t.id == updated.id);
                        if (ix != -1) {
                          _tasks[ix] = updated;
                        }
                      });
                      _updateTaskInFirestore(updated);
                    },
                    onTap: (t) {
                      _openTaskDetails(t);
                    },
                  );
                }).toList(),

                // Le rectangle vert pendant le drag
                if (_dragDayKey == dayKey &&
                    _dragStartDy != null &&
                    _dragCurrentDy != null)
                  Positioned(
                    top: min(_dragStartDy!, _dragCurrentDy!),
                    left: 0,
                    right: 0,
                    height: (_dragStartDy! - _dragCurrentDy!).abs(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.3),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          _overlayText(
                              dayDate, _dragStartDy!, _dragCurrentDy!),
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Convertit un drag overlay en "HH:mm - HH:mm"
  String _overlayText(DateTime day, double startY, double endY) {
    int startMin = (startY / _cellHeight * 60).round();
    int endMin = (endY / _cellHeight * 60).round();
    if (endMin < startMin) {
      final tmp = startMin;
      startMin = endMin;
      endMin = tmp;
    }
    final startHH = (startMin ~/ 60).toString().padLeft(2, '0');
    final startMM = (startMin % 60).toString().padLeft(2, '0');
    final endHH = (endMin ~/ 60).toString().padLeft(2, '0');
    final endMM = (endMin % 60).toString().padLeft(2, '0');
    return '$startHH:$startMM - $endHH:$endMM';
  }

  Widget _buildBodyRow() {
    List<Widget> dayCols = [];
    for (int i = 0; i < 7; i++) {
      final d = _weekStart.add(Duration(days: i));
      dayCols.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: _buildDayColumn(d),
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne heures
                Container(
                  width: _hourColumnWidth,
                  decoration: BoxDecoration(color: Colors.grey[850]),
                  child: Column(
                    children: List.generate(24, (hour) {
                      return Container(
                        height: _cellHeight,
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 10),
                        child: Transform.translate(
                          offset: const Offset(0, -10),
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}h',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // 7 colonnes de jours
                Expanded(
                  child: Row(children: dayCols),
                ),
              ],
            ),
          ),
        ),
        Container(height: 1, color: Colors.grey[700]),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              onPressed: _goToPreviousWeek,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Semaine précédente',
            ),
            TextButton(
              onPressed: _goToToday,
              child: const Text(
                'revenir à\naujourd\'hui',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: _goToNextWeek,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Semaine suivante',
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _showMonthPopup = !_showMonthPopup;
                });
              },
              child: Text(
                '${_monthName(_weekStart.month)} ${_weekStart.year}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeaderRow(),
              Expanded(child: _buildBodyRow()),
            ],
          ),

          if (_showMonthPopup)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              height: 300,
              child: Material(
                color: Colors.grey[900],
                elevation: 5,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: _buildMonthGrid(),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          // Création manuelle d'une nouvelle tâche
          showDialog(
            context: context,
            builder: (ctx) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TaskDetailPanel(
                    task: CustomTask(name: '', description: ''),
                    onSave: (updatedTask) async {
                      Navigator.pop(context);
                    },
                    onClose: () {
                      Navigator.pop(context);
                    },
                    onMarkAsDone: () async {
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}