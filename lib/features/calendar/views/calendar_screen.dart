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

  // NOUVEAU : pour gérer la tâche en cours de drag
  String? _draggingTaskId;
  DateTime? _draggingToDay;

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
    _tasksSubscription = query.snapshots().listen((snap) async {
      if (!mounted) return;

      final List<CalendarTask> allOccurrences = [];
      final DateTime todayDateOnly = DateTime.now().toLocal();
      final DateTime todayStart = DateTime(
          todayDateOnly.year, todayDateOnly.month, todayDateOnly.day);

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final cTask = CustomTask.fromMap(data, doc.id);

        // Couleur par défaut si pas de projet ou pas de couleur :
        Color cellColor = AppColors.blue;
        final projId = (data['project'] as String?)?.trim();
        if (projId != null && projId.isNotEmpty) {
          try {
            final projSnap = await FirebaseFirestore.instance
                .collection('projects')
                .doc(projId)
                .get();
            if (projSnap.exists) {
              final projData = projSnap.data()!;
              final colorString = projData['color'] as String?;
              if (colorString != null && colorString.isNotEmpty) {
                cellColor = Color(int.parse(colorString, radix: 16));
              }
            }
          } catch (_) {
            // Garde la couleur par défaut en cas d'erreur
          }
        }

        final taskDate = cTask.deadline;
        if (taskDate == null) continue;
        final stTOD = cTask.startTime ?? const TimeOfDay(hour: 0, minute: 0);
        final enTOD = cTask.endTime ?? const TimeOfDay(hour: 23, minute: 59);

        final origStart = DateTime(
          taskDate.year,
          taskDate.month,
          taskDate.day,
          stTOD.hour,
          stTOD.minute,
        );
        final origEnd = DateTime(
          taskDate.year,
          taskDate.month,
          taskDate.day,
          enTOD.hour,
          enTOD.minute,
        );

        final forwardLimit = DateTime(
          taskDate.year,
          taskDate.month + 6,
          taskDate.day,
        );
        final pastLimit = DateTime(
          taskDate.year,
          taskDate.month - 6,
          taskDate.day,
        );

        final recType = cTask.recurrenceType;
        final recDays = cTask.recurrenceDays;
        final includePast = cTask.recurrenceIncludePast ?? false;

        if (recType == null || recType == 'none') {
          // On affiche maintenant toutes les tâches, quel que soit leur jour
          allOccurrences.add(
            CalendarTask(
              id: doc.id,
              start: origStart,
              end: origEnd,
              title: cTask.name,
              projectColor: cellColor,
            ),
          );
        } else {
          if (includePast) {
            DateTime currentBack =
            origStart.subtract(const Duration(days: 1));
            while (!currentBack.isBefore(pastLimit)) {
              final weekdayIndex = currentBack.weekday;
              bool shouldAddBack = false;
              if (recType == 'sameDay') {
                if (weekdayIndex == origStart.weekday) shouldAddBack = true;
              } else if (recType == 'weekdays') {
                if (weekdayIndex >= DateTime.monday &&
                    weekdayIndex <= DateTime.friday) shouldAddBack = true;
              } else if (recType == 'weekends') {
                if (weekdayIndex == DateTime.saturday ||
                    weekdayIndex == DateTime.sunday) shouldAddBack = true;
              } else if (recDays != null && recDays.isNotEmpty) {
                if (recDays.contains(weekdayIndex - 1)) shouldAddBack = true;
              }
              if (shouldAddBack) {
                final startOcc = DateTime(
                  currentBack.year,
                  currentBack.month,
                  currentBack.day,
                  stTOD.hour,
                  stTOD.minute,
                );
                final endOcc = DateTime(
                  currentBack.year,
                  currentBack.month,
                  currentBack.day,
                  enTOD.hour,
                  enTOD.minute,
                );
                allOccurrences.add(
                  CalendarTask(
                    id: doc.id,
                    start: startOcc,
                    end: endOcc,
                    title: cTask.name,
                    projectColor: cellColor,
                  ),
                );
              }
              currentBack = currentBack.subtract(const Duration(days: 1));
            }
          }

          DateTime current = origStart;
          while (!current.isAfter(forwardLimit)) {
            final weekdayIndex = current.weekday;
            bool shouldAddForward = false;

            if (recType == 'sameDay') {
              if (weekdayIndex == origStart.weekday) shouldAddForward = true;
            } else if (recType == 'weekdays') {
              if (weekdayIndex >= DateTime.monday &&
                  weekdayIndex <= DateTime.friday) shouldAddForward = true;
            } else if (recType == 'weekends') {
              if (weekdayIndex == DateTime.saturday ||
                  weekdayIndex == DateTime.sunday) shouldAddForward = true;
            } else if (recDays != null && recDays.isNotEmpty) {
              if (recDays.contains(weekdayIndex - 1)) shouldAddForward = true;
            }

            if (shouldAddForward) {
              final occurrenceDay = DateTime(
                current.year,
                current.month,
                current.day,
              );
              if (includePast ||
                  !occurrenceDay.isBefore(todayStart)) {
                final startOcc = DateTime(
                  current.year,
                  current.month,
                  current.day,
                  stTOD.hour,
                  stTOD.minute,
                );
                final endOcc = DateTime(
                  current.year,
                  current.month,
                  current.day,
                  enTOD.hour,
                  enTOD.minute,
                );
                allOccurrences.add(
                  CalendarTask(
                    id: doc.id,
                    start: startOcc,
                    end: endOcc,
                    title: cTask.name,
                    projectColor: cellColor,
                  ),
                );
              }
            }

            current = current.add(const Duration(days: 1));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _tasks = allOccurrences;
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
  void _goToPreviousWeek() => setState(() {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _subscribeToTasks();
  });

  void _goToNextWeek() => setState(() {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _subscribeToTasks();
  });

  void _goToToday() => setState(() {
    _initWeekStart();
    _subscribeToTasks();
  });

  // ───────────────────────── layout computation

  List<PositionedEvent> _computeLayoutForDay(
      List<CalendarTask> tasks, DateTime day) {
    // Si on déplace la tâche actuelle dans la même date, on l’affiche full-width
    if (_draggingTaskId != null &&
        _draggingToDay != null &&
        day.year == _draggingToDay!.year &&
        day.month == _draggingToDay!.month &&
        day.day == _draggingToDay!.day) {
      final movedList = tasks.where((t) => t.id == _draggingTaskId).toList();
      if (movedList.isNotEmpty) {
        final t = movedList.first;
        final sMin = t.start.hour * 60 + t.start.minute;
        final eMin = t.end.hour * 60 + t.end.minute;
        return [
          PositionedEvent(
            task: t,
            top: (sMin / 60) * _cellHeight,
            height: ((eMin - sMin) / 60) * _cellHeight,
            columnIndex: 0,
            colCount: 1,
          )
        ];
      }
    }

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

    if (_draggingTaskId != null &&
        _draggingToDay != null &&
        day.year == _draggingToDay!.year &&
        day.month == _draggingToDay!.month &&
        day.day == _draggingToDay!.day) {
      return _computeLayoutForDay(dayTasks, day);
    }

    if (_draggingTaskId != null &&
        dayTasks.any((t) => t.id == _draggingTaskId) &&
        !(
            day.year == _draggingToDay?.year &&
                day.month == _draggingToDay?.month &&
                day.day == _draggingToDay?.day
        )) {
      dayTasks.removeWhere((t) => t.id == _draggingTaskId);
    }

    return _computeLayoutForDay(dayTasks, day);
  }

  void _moveTaskToDay(CalendarTask task, DateTime day,
      {required double localDy}) {
    if (task.id.isEmpty) return;

    int minutes = ((localDy / _cellHeight) * 60).round();
    minutes = (minutes ~/ 15) * 15;

    var newStart =
    DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
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
      projectColor: task.projectColor,
    );

    // Mettre à jour Firestore
    _updateTaskInFirestore(updated);

    setState(() {
      // Supprimer toutes les occurrences portant le même id
      _tasks.removeWhere((t) => t.id == task.id);

      // Ne PAS ajouter manuellement updated → on attend le listener Firestore
      // pour régénérer la série complète (passées + futures)

      // Réinitialiser l’état du drag
      _draggingTaskId = null;
      _draggingToDay = null;
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
      responsable: '',
      subTasks: [],
    );

    setState(() {
      _activeTask = cTask;
      _showTaskPanel = true;
    });
  }

  Future<void> _openTaskDetails(CalendarTask task) async {
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
    final client = data['client']?.toString();
    final responsableId = data['responsable']?.toString() ?? '';
    final projectId = data['project']?.toString();
    final recType = data['recurrenceType'] as String?;
    final recDays = (data['recurrenceDays'] != null)
        ? List<int>.from((data['recurrenceDays'] as List).map((e) => e as int))
        : null;
    final recIncludePast = data['recurrenceIncludePast'] as bool? ?? false;

    DateTime? parsedDeadline;
    if (dateVal is Timestamp) {
      parsedDeadline = dateVal.toDate();
    } else if (dateVal is String && dateVal.isNotEmpty) {
      parsedDeadline = DateTime.tryParse(dateVal);
    }

    final stDate = _combineDateAndTime(dateVal, stStr);
    final etDate = _combineDateAndTime(dateVal, etStr);
    final startTOD = TimeOfDay(hour: stDate.hour, minute: stDate.minute);
    final endTOD = TimeOfDay(hour: etDate.hour, minute: etDate.minute);

    final cTask = CustomTask(
      id: task.id,
      name: name,
      description: desc,
      status: status,
      deadline: parsedDeadline,
      startTime: startTOD,
      endTime: endTOD,
      client: client,
      project: projectId,
      responsable: responsableId,
      recurrenceType: recType,
      recurrenceDays: recDays,
      recurrenceIncludePast: recIncludePast,
      subTasks: [],
    );

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

    final data = <String, dynamic>{
      'deadline': DateFormat('yyyy-MM-dd').format(date),
      'startTime':
      '${sH.toString().padLeft(2, '0')}:${sM.toString().padLeft(2, '0')}',
      'endTime':
      '${eH.toString().padLeft(2, '0')}:${eM.toString().padLeft(2, '0')}',
      'name': u.name.trim(),
      'description': u.description,
      'status': u.status,
      'client': u.client,
      'responsable': u.responsable,
      'project': u.project,
      'recurrenceType': u.recurrenceType,
      'recurrenceDays': u.recurrenceDays,
      'recurrenceIncludePast': u.recurrenceIncludePast ?? false,
      'createdBy': FirebaseAuth.instance.currentUser?.uid,
      'subTasks': [], // on ne gère pas les sous‐tâches ici
    };

    if (u.id.isEmpty) {
      final docRef =
      await FirebaseFirestore.instance.collection('tasks').add(data);
      u.id = docRef.id;
    } else {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(u.id)
          .update(data);
    }

    _subscribeToTasks();
    setState(() {
      _showTaskPanel = false;
      _activeTask = null;
    });
  }

  Widget _buildHourColumn(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Theme.of(context).colorScheme.onBackground.withOpacity(0.7)
        : Colors.white;
    final hourColColor = AppColors.glassBackground;
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
  }

  Widget _buildHeaderRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = AppColors.glassHeader;
    final borderColor = isDark
        ? Theme.of(context).colorScheme.onBackground.withOpacity(0.3)
        : Colors.white;
    final textColor =
        isDark ? Theme.of(context).colorScheme.onBackground : Colors.white;

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
      final dayHeight = 24 * _cellHeight;
      final layout = _getLayoutForDay(day);
      final background = AppColors.glassBackground;
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final borderColor = isDark
          ? Theme.of(ctx).colorScheme.onBackground.withOpacity(0.3)
          : Colors.white;

      return Stack(
        children: [
          // 1) Fond de la colonne
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

          // 2) GestureDetector pour créer une tâche à l'heure (tap)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final localDy = details.localPosition.dy;
                int minutes = ((localDy / _cellHeight) * 60).round();
                if (minutes < 0) minutes = 0;
                if (minutes > 23 * 60 + 59) minutes = 23 * 60 + 59;
                final start = DateTime(
                  day.year,
                  day.month,
                  day.day,
                  minutes ~/ 60,
                  minutes % 60,
                );
                _openNewTaskDetail(start);
              },
              child: Container(),
            ),
          ),

          // 3) DragTarget pour déplacer les tâches existantes
          Positioned.fill(
            child: DragTarget<CalendarTask>(
              onWillAccept: (incoming) {
                if (incoming == null) return false;
                setState(() {
                  _draggingTaskId = incoming.id;
                  _draggingToDay = DateTime(
                      day.year, day.month, day.day);
                });
                return true;
              },
              onLeave: (_) {
                setState(() {
                  _draggingTaskId = null;
                  _draggingToDay = null;
                });
              },
              onAcceptWithDetails: (details) {
                final box = ctx.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.offset);
                _moveTaskToDay(
                    details.data, day,
                    localDy: local.dy);
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

          // 4) Placement des tâches (ResizableTaskCell)
          ...layout.map((pe) {
            final colWidth = (constraints.maxWidth -
                (_innerMargin * (pe.colCount + 1))) /
                pe.colCount;
            final leftOffset =
                _innerMargin + pe.columnIndex * (colWidth + _innerMargin);
            return ResizableTaskCell(
              key: ValueKey('${pe.task.id}-${pe.top}-${pe.columnIndex}'),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
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

    if (isMobile) {
      final headerBg = AppColors.glassHeader;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final borderColor = isDark
          ? Theme.of(context).colorScheme.onBackground.withOpacity(0.3)
          : Colors.white;
      final textColor =
          isDark ? Theme.of(context).colorScheme.onBackground : Colors.white;

      final List<Widget> dayWidgets = [];
      for (int i = 0; i < 7; i++) {
        final day = _weekStart.add(Duration(days: i));
        dayWidgets.add(Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(color: headerBg),
          alignment: Alignment.center,
          child: Text(
            '${_weekdayName(day.weekday)} ${day.day}',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ));
        dayWidgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHourColumn(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: _buildDayColumn(day, i),
              ),
            ),
          ],
        ));
        dayWidgets.add(Container(height: 1, color: borderColor));
      }

      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SingleChildScrollView(child: Column(children: dayWidgets)),
      );
    } else {
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
                    _buildHourColumn(context),
                    Expanded(child: Row(children: allColumns)),
                  ],
                ),
              ),
            ),
            Builder(builder: (ctx) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              final borderColor = isDark
                  ? Theme.of(ctx).colorScheme.onBackground.withOpacity(0.3)
                  : Colors.white;
              return Container(height: 1, color: borderColor);
            }),
            const SizedBox(height: 20),
          ],
        ),
      );
    }
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
      body: Container(
        color: AppColors.glassBackground,
        child: Stack(
          children: [
            Column(
              children: [
                if (MediaQuery.of(context).size.width >= 600)
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
                    _subscribeToTasks();
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
              Center(
                child: Material(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBackground
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: 500,
                    height: MediaQuery.of(context).size.height * 0.8,
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
                        // Optionnel : marquer terminé
                      },
                      onCalendarRefresh: () {
                        _subscribeToTasks();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: () => _onCalendarTapDefault(DateTime.now()),
        child: const Icon(Icons.add),
      ),
    );
  }
}