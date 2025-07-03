// lib/features/tasks/widgets/task_calendar_mode_widget.dart

import 'package:flutter/material.dart';
import 'package:tokan/features/calendar/views/calendar_screen.dart';
import '../../../main.dart'; // Pour AppColors

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
    // On enveloppe CalendarPage dans un Container « verre sombre »
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.glassBackground : Colors.transparent,
      child: CalendarPage(
        refreshNotifier: refreshNotifier,
        projectId: projectId,
      ),
    );
  }
}