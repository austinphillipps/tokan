// lib/features/calendar/views/calendar_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widgets/month_popup_widget.dart';
import '../widgets/calendar_menu_bar_widget.dart';
import '../widgets/calendar_task_widget.dart';
import '../../tasks/models/custom_task_model.dart';
import '../../../shared/widgets/task_details_panel_widget.dart';
import '../../../shared/widgets/resizable_task_cell_widget.dart';

// Import de AppColors pour récupérer les couleurs centralisées
import '../../../main.dart';

class PositionedEvent {
  final CalendarTask task;
  final double top;
  final double height;
  final int columnIndex;
  final int colCount;

  PositionedEvent({
    required this.task,
    required this.top,
    required this.height,
    required this.columnIndex,
    required this.colCount,
  });
}

class CalendarPage extends StatefulWidget {
  final ValueNotifier<int> refreshNotifier;
  final String? projectId;

  const CalendarPage({
    Key? key,
    required this.refreshNotifier,
    this.projectId,
  }) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // ───────────────────────── constantes UI
  static const double _cellHeight = 60.0;
  static const double _hourColumnWidth = 60.0;
  static const double _innerMargin = 2.0;

  // ───────────────────────── état
  late DateTime _weekStart;
  late DateTime _currentMonth;
  bool _showMonthPopup = false;

  List<CalendarTask> _tasks = [];
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  final Map<String, List<PositionedEvent>> _frozenLayouts = {};

  // Pour afficher le panneau de détail en overlay
  bool _showTaskPanel = false;
  CustomTask? _activeTask;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_refresh);
    _initWeekStart();
    _currentMonth = DateTime.now();
    _subscribeToTasks();
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_refresh);
    _tasksSubscription?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  // ───────────────────────── helpers date
  void _initWeekStart() {
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - DateTime.monday));
  }

  String _monthName(int m) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[m - 1];
  }

  String _weekdayName(int w) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[w - 1];
  }

  // ───────────────────────── Firestore
  void _subscribeToTasks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var query = FirebaseFirestore.instance
        .collection('tasks')
        .where('createdBy', isEqualTo: user.uid);

    // Filtrer par projet si défini
    if (widget.projectId?.isNotEmpty == true) {
      query = query.where('project', isEqualTo: widget.projectId);
    }

    _tasksSubscription?.cancel();
    _tasksSubscription = query.snapshots().listen((snap) {
      if (!mounted) return;
      final loaded = snap.docs.map((doc) {
        final d = doc.data();
        final dateVal = d['deadline'];
        final stStr = d['startTime']?.toString() ?? '';
        final etStr = d['endTime']?.toString() ?? '';
        final title = d['name']?.toString() ?? '';
        final start = _combineDateAndTime(dateVal, stStr);
        final end = _combineDateAndTime(dateVal, etStr);
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
      });
    });
  }

  static DateTime _combineDateAndTime(dynamic dateValue, String hhmm) {
    DateTime date;
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is String && dateValue.isNotEmpty) {
      date = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    if (hhmm.length == 5 && hhmm.contains(':')) {
      final h = int.parse(hhmm.substring(0, 2));
      final m = int.parse(hhmm.substring(3, 5));
      return DateTime(date.year, date.month, date.day, h, m);
    }
    return date;
  }

  void _updateTaskInFirestore(CalendarTask t) {
    FirebaseFirestore.instance.collection('tasks').doc(t.id).update({
      'deadline': DateFormat('yyyy-MM-dd').format(t.start),
      'startTime':
      '${t.start.hour.toString().padLeft(2, '0')}:${t.start.minute.toString().padLeft(2, '0')}',
      'endTime':
      '${t.end.hour.toString().padLeft(2, '0')}:${t.end.minute.toString().padLeft(2, '0')}',
      // On ne modifie pas le champ 'project' ici
    });
  }

  // ───────────────────────── navigation
  void _goToPreviousWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _goToNextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  void _goToToday() => setState(_initWeekStart);

  // ───────────────────────── layout computation
  List<PositionedEvent> _computeLayoutForDay(List<CalendarTask> tasks) {
    if (tasks.isEmpty) return [];
    tasks.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.end.compareTo(b.end);
    });

    final clusters = <List<CalendarTask>>[];
    var current = <CalendarTask>[tasks.first];
    var endOfCluster = tasks.first.end;

    for (final t in tasks.skip(1)) {
      if (t.start.isBefore(endOfCluster)) {
        current.add(t);
        if (t.end.isAfter(endOfCluster)) endOfCluster = t.end;
      } else {
        clusters.add(current);
        current = [t];
        endOfCluster = t.end;
      }
    }
    clusters.add(current);

    final out = <PositionedEvent>[];
    for (var cluster in clusters) {
      final cols = <List<CalendarTask>>[];
      for (final t in cluster) {
        bool placed = false;
        for (final col in cols) {
          if (!col.last.end.isAfter(t.start)) {
            col.add(t);
            placed = true;
            break;
          }
        }
        if (!placed) cols.add([t]);
      }
      final colCount = cols.length;
      for (var c = 0; c < colCount; c++) {
        for (final t in cols[c]) {
          final sMin = t.start.hour * 60 + t.start.minute;
          final eMin = t.end.hour * 60 + t.end.minute;
          out.add(PositionedEvent(
            task: t,
            top: (sMin / 60) * _cellHeight,
            height: ((eMin - sMin) / 60) * _cellHeight,
            columnIndex: c,
            colCount: colCount,
          ));
        }
      }
    }
    return out;
  }

  List<PositionedEvent> _getLayoutForDay(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    if (_frozenLayouts.containsKey(key)) return _frozenLayouts[key]!;
    final dayTasks = _tasks.where((t) =>
    t.start.year == day.year &&
        t.start.month == day.month &&
        t.start.day == day.day).toList();
    return _computeLayoutForDay(dayTasks);
  }

  void _moveTaskToDay(CalendarTask task, DateTime day,
      {required double localDy}) {
    if (task.id.isEmpty) return;

    int minutes = ((localDy / _cellHeight) * 60).round();
    minutes = (minutes ~/ 15) * 15;

    var newStart = DateTime(
        day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
    final duration = task.end.difference(task.start);
    var newEnd = newStart.add(duration);

    final eod = DateTime(day.year, day.month, day.day, 23, 59);
    if (newEnd.isAfter(eod)) {
      newEnd = eod;
      newStart = eod.subtract(duration);
    }

    final updated = CalendarTask(
      id: task.id,
      start: newStart,
      end: newEnd,
      title: task.title,
    );

    _updateTaskInFirestore(updated);
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) _tasks[idx] = updated;
      _frozenLayouts.clear();
    });
  }

  void _openNewTaskDetail(DateTime start) {
    final cTask = CustomTask(
      id: '',
      name: '',
      description: '',
      status: 'pending',
      deadline: DateTime(start.year, start.month, start.day),
      startTime: TimeOfDay(hour: start.hour, minute: start.minute),
      endTime: TimeOfDay(hour: start.hour + 1, minute: start.minute),
      client: null,
      project: widget.projectId,
      subTasks: [],
    );

    setState(() {
      _activeTask = cTask;
      _showTaskPanel = true;
    });
  }

  void _openTaskDetails(CalendarTask task) async {
    final snap = await FirebaseFirestore.instance
        .collection('tasks')
        .doc(task.id)
        .get();
    if (!snap.exists) return;
    final data = snap.data()!;

    final dateVal = data['deadline'];
    final stStr = data['startTime']?.toString() ?? '';
    final etStr = data['endTime']?.toString() ?? '';
    final name = data['name']?.toString() ?? '';
    final desc = data['description']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';

    final st = _combineDateAndTime(dateVal, stStr);
    final et = _combineDateAndTime(dateVal, etStr);

    final rawMap = Map<String, dynamic>.from(data);
    rawMap['startTime'] = st;
    rawMap['endTime'] = et;
    rawMap['deadline'] = (dateVal is Timestamp)
        ? dateVal.toDate()
        : (dateVal is String && dateVal.isNotEmpty
        ? DateTime.tryParse(dateVal)
        : null);

    final cTask = CustomTask.fromMap(rawMap, task.id);

    setState(() {
      _activeTask = cTask;
      _showTaskPanel = true;
    });
  }

  Future<void> _saveTaskFromCalendar(CustomTask u) async {
    final sH = u.startTime?.hour ?? 0;
    final sM = u.startTime?.minute ?? 0;
    final eH = u.endTime?.hour ?? 0;
    final eM = u.endTime?.minute ?? 0;
    final date = u.deadline ?? DateTime.now();

    final List<Map<String, dynamic>> subTasksData = u.subTasks.map((sub) {
      return {
        'id': sub.id,
        'name': sub.name,
        'description': sub.description,
        'status': sub.status,
        'deadline': sub.deadline != null
            ? DateFormat('yyyy-MM-dd').format(sub.deadline!)
            : null,
        'startTime': sub.startTime != null
            ? '${sub.startTime!.hour.toString().padLeft(2, '0')}:${sub.startTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'endTime': sub.endTime != null
            ? '${sub.endTime!.hour.toString().padLeft(2, '0')}:${sub.endTime!.minute.toString().padLeft(2, '0')}'
            : null,
        'client': sub.client,
        'responsable': sub.responsable,
        'project': sub.project,
        'subTasks': [],
      };
    }).toList();

    final data = <String, dynamic>{
      'deadline': DateFormat('yyyy-MM-dd').format(date),
      'startTime': '${sH.toString().padLeft(2, '0')}:${sM.toString().padLeft(2, '0')}',
      'endTime': '${eH.toString().padLeft(2, '0')}:${eM.toString().padLeft(2, '0')}',
      'name': u.name.trim(),
      'description': u.description,
      'status': u.status,
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'subTasks': subTasksData,
      if (widget.projectId?.isNotEmpty == true) 'project': widget.projectId,
    };

    if (u.id.isEmpty) {
      final docRef = await FirebaseFirestore.instance.collection('tasks').add(data);
      u.id = docRef.id;
    } else {
      await FirebaseFirestore.instance.collection('tasks').doc(u.id).update(data);
    }

    _subscribeToTasks();
    setState(() {
      _showTaskPanel = false;
      _activeTask = null;
    });
  }

  Widget _buildHeaderRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // En sombre, on utilise AppColors.darkGreyBackground pour le header
    // En clair, on utilise la couleur de surface du thème (souvent blanche)
    final headerBg = isDark
        ? AppColors.darkGreyBackground
        : Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).colorScheme.onBackground.withOpacity(0.3);
    final textColor = Theme.of(context).colorScheme.onBackground;

    List<Widget> dayHeaders = [];
    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      dayHeaders.add(
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                left: BorderSide(color: borderColor),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${_weekdayName(day.weekday)}\n${day.day}',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: _hourColumnWidth,
          height: 50,
          color: headerBg,
        ),
        Expanded(child: Row(children: dayHeaders)),
      ],
    );
  }

  Widget _buildDayColumn(DateTime day, int _) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final dayHeight = 24 * _cellHeight;
      final layout = _getLayoutForDay(day);

      // Pour le fond des colonnes :
      //   - thème sombre → AppColors.darkBackground
      //   - thème clair   → Colors.white (ou colorScheme.surface si vous préférez)
      final background = isDark
          ? AppColors.darkBackground
          : Colors.white;
      final borderColor = Theme.of(ctx).colorScheme.onBackground.withOpacity(0.3);

      return Stack(
        children: [
          Container(
            height: dayHeight,
            decoration: BoxDecoration(
              color: background,
              border: Border(left: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: List.generate(
                24,
                    (_) => Container(
                  height: _cellHeight,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DragTarget<CalendarTask>(
              onWillAccept: (_) => true,
              onAcceptWithDetails: (details) {
                final box = ctx.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.offset);
                _moveTaskToDay(details.data, day, localDy: local.dy);
              },
              builder: (_, candidate, __) {
                return Container(
                  color: candidate.isNotEmpty
                      ? AppColors.blue.withOpacity(0.1)
                      : null,
                );
              },
            ),
          ),
          ...layout.map((pe) {
            final colWidth = (constraints.maxWidth -
                (_innerMargin * (pe.colCount + 1))) /
                pe.colCount;
            final leftOffset =
                _innerMargin + pe.columnIndex * (colWidth + _innerMargin);
            return ResizableTaskCell(
              key: ValueKey(pe.task.id),
              task: pe.task,
              top: pe.top,
              height: pe.height,
              availableWidth: colWidth,
              leftOffset: leftOffset,
              column: pe.columnIndex,
              totalColumns: pe.colCount,
              cellHeight: _cellHeight,
              maxHeight: dayHeight,
              minAllowedStart:
              DateTime(day.year, day.month, day.day, 0, 0),
              maxAllowedEnd:
              DateTime(day.year, day.month, day.day, 23, 59),
              onTaskResized: (u) {
                setState(() {
                  final idx = _tasks.indexWhere((t) => t.id == u.id);
                  if (idx != -1) _tasks[idx] = u;
                });
                _updateTaskInFirestore(u);
              },
              onTap: _openTaskDetails,
            );
          }).toList(),
        ],
      );
    });
  }

  Widget _buildBodyRow() {
    final List<Widget> allColumns = [];

    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      allColumns.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: _buildDayColumn(day, i),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne des heures
                  Builder(builder: (ctx) {
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    final hourColColor = isDark
                        ? AppColors.darkGreyBackground
                        : Colors.white;
                    final textColor = Theme.of(ctx).colorScheme.onBackground.withOpacity(0.7);

                    return Container(
                      width: _hourColumnWidth,
                      decoration: BoxDecoration(color: hourColColor),
                      child: Column(
                        children: List.generate(24, (h) {
                          return Container(
                            height: _cellHeight,
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.only(top: 10),
                            child: Transform.translate(
                              offset: const Offset(0, -10),
                              child: Text(
                                '${h.toString().padLeft(2, '0')}h',
                                style: TextStyle(color: textColor, fontSize: 12),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),

                  // Colonnes des jours (sans espacement)
                  Expanded(child: Row(children: allColumns)),
                ],
              ),
            ),
          ),
          Builder(builder: (ctx) {
            final borderColor = Theme.of(ctx).colorScheme.onBackground.withOpacity(0.3);
            return Container(height: 1, color: borderColor);
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onCalendarTapDefault(DateTime day) {
    final now = DateTime.now();
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      (now.minute ~/ 15) * 15,
    );
    _openNewTaskDetail(start);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Le fond général de la page s'appuie sur scaffoldBackgroundColor défini dans main.dart
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CalendarMenuBar(
        onPreviousWeek: _goToPreviousWeek,
        onToday: _goToToday,
        onNextWeek: _goToNextWeek,
        onToggleMonthPopup: () => setState(() => _showMonthPopup = !_showMonthPopup),
        monthYearDisplay: '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
        currentMonth: _currentMonth.month,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeaderRow(context),
              Expanded(child: _buildBodyRow()),
            ],
          ),
          if (_showMonthPopup) ...[
            GestureDetector(
              onTap: () => setState(() => _showMonthPopup = false),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              top: 56,
              right: 20,
              child: MonthPopup(
                initialMonth: _currentMonth,
                onDateSelected: (d) {
                  final diff = d.weekday - DateTime.monday;
                  final newStart = d.subtract(Duration(days: diff));
                  setState(() {
                    _weekStart = DateTime(newStart.year, newStart.month, newStart.day);
                    _currentMonth = d;
                    _showMonthPopup = false;
                  });
                },
                onClose: () => setState(() => _showMonthPopup = false),
              ),
            ),
          ],
          if (_showTaskPanel && _activeTask != null) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() {
                  _showTaskPanel = false;
                  _activeTask = null;
                }),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 400,
              child: Container(
                // Fond du panneau de détails : blanc en clair, gris foncé en sombre
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBackground
                    : Colors.white,
                child: TaskDetailPanel(
                  task: _activeTask!,
                  onSave: (updatedTask) async {
                    await _saveTaskFromCalendar(updatedTask);
                  },
                  onClose: () => setState(() {
                    _showTaskPanel = false;
                    _activeTask = null;
                  }),
                  onMarkAsDone: () {
                    // Optionnel : permettre de marquer terminé directement
                  },
                  onCalendarRefresh: () {
                    _subscribeToTasks();
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue, // bleu pour le bouton flottant
        onPressed: () => _onCalendarTapDefault(DateTime.now()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
