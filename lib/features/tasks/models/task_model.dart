import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de données pour une tâche du calendrier
class Task {
  String id;
  String title;
  DateTime start;
  DateTime end;
  int color; // Couleur stockée comme int (format ARGB)

  Task({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
  });

  /// Constructeur permettant de créer une tâche à partir des données Firestore
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
      color: (data['color'] is int) ? data['color'] as int : 0xFF2196F3,
      // Si 'color' absent, on utilise une couleur par défaut (bleu)
    );
  }

  /// Convertit l'objet Task en Map pour stockage dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'color': color,
    };
  }
}
