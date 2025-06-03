// lib/features/tasks/widgets/task_calendar_mode_widget.dart

import 'package:flutter/material.dart';
import 'package:tokan/features/calendar/views/calendar_screen.dart';

/// Widget enveloppant CalendarPage, en prenant en compte le refreshNotifier
/// et le projectId (pour filtrer les tâches du calendrier).
class TasksCalendarView extends StatelessWidget {
  /// Le ValueNotifier<int> permettant de forcer une reconstruction du CalendarPage.
  final ValueNotifier<int> refreshNotifier;

  /// (Optionnel) L'ID du projet dont on souhaite afficher les tâches.
  final String? projectId;

  const TasksCalendarView({
    Key? key,
    required this.refreshNotifier,
    this.projectId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On appelle CalendarPage, en passant le refreshNotifier ET le projectId
    return CalendarPage(
      refreshNotifier: refreshNotifier,
      projectId: projectId,
    );
  }
}
