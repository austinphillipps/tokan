// lib/models/calendar_task_widget.dart
class CalendarTask {
  final String id;
  DateTime start;
  DateTime end;
  String title;

  // Propriétés d'affichage (initialisées lors du calcul de la disposition)
  int? columnIndex;
  int? totalColumns;
  double? topPx;
  double? heightPx;

  CalendarTask({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    this.columnIndex,
    this.totalColumns,
    this.topPx,
    this.heightPx,
  });
}
