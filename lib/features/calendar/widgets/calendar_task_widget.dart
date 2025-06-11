// lib/models/calendar_task_widget.dart

import 'package:flutter/material.dart';

/// Représente une tâche pour l’affichage dans le calendrier.
/// On y ajoute le champ `projectColor` pour pouvoir afficher
/// la couleur du projet (ou null si pas de projet).
class CalendarTask {
  final String id;
  DateTime start;
  DateTime end;
  String title;

  /// Couleur utilisée pour l’affichage (ex. champ `color` du projet en Firestore).
  /// Si null, on pourra retomber sur une couleur par défaut dans le widget.
  Color? projectColor;

  // Propriétés d’affichage (initialisées lors du calcul de la disposition)
  int? columnIndex;
  int? totalColumns;
  double? topPx;
  double? heightPx;

  CalendarTask({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    this.projectColor,
    this.columnIndex,
    this.totalColumns,
    this.topPx,
    this.heightPx,
  });
}
