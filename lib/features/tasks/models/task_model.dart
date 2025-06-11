import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de données pour une tâche du calendrier,
/// avec prise en charge de la récurrence.
class Task {
  String id;
  String title;
  DateTime start;
  DateTime end;
  int color; // Couleur stockée comme int (format ARGB)

  // Nouveaux champs pour la récurrence
  String? recurrenceType;    // Ex. "Tous les Lundi", "Chaque semaine", "Choisir les jours"
  List<int>? recurrenceDays; // Indices des jours (0 = Lundi … 6 = Dimanche)

  Task({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
    this.recurrenceType,
    this.recurrenceDays,
  });

  /// Construire depuis les données Firestore
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
      color: (data['color'] is int) ? data['color'] as int : 0xFF2196F3,
      recurrenceType: data['recurrenceType'] as String?,
      recurrenceDays: (data['recurrenceDays'] is List)
          ? List<int>.from((data['recurrenceDays'] as List).map((e) => e as int))
          : null,
    );
  }

  /// Convertit l'objet en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'color': color,
      'recurrenceType': recurrenceType,
      'recurrenceDays': recurrenceDays,
    };
  }
}
