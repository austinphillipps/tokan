import 'package:equatable/equatable.dart';

/// Représente une plage horaire dans l’agenda (par ex. "08:00–09:00").
/// Immuable et comparable grâce à Equatable.
class TimeSlot extends Equatable {
  /// Chaîne au format "HH:mm–HH:mm" (ex. "08:00–09:00").
  final String timeRange;

  /// Texte de la tâche assignée, s’il y en a.
  final String? task;

  /// Marque la tâche comme complétée ou non.
  final bool completed;

  /// Point de départ en minutes depuis minuit (ex. 8h → 8 * 60 = 480).
  final int startInMinutes;

  /// Point de fin en minutes depuis minuit (ex. 9h → 9 * 60 = 540).
  final int endInMinutes;

  /// Constructeur non-constant (pour pouvoir appeler les méthodes statiques).
  TimeSlot({
    required this.timeRange,
    this.task,
    this.completed = false,
  })  : startInMinutes = _parseStart(timeRange),
        endInMinutes = _parseEnd(timeRange);

  /// Copie avec possibilité de modifier le texte de la tâche ou l’état.
  TimeSlot copyWith({
    String? task,
    bool? completed,
  }) {
    return TimeSlot(
      timeRange: timeRange,
      task: task ?? this.task,
      completed: completed ?? this.completed,
    );
  }

  /// Extrait les minutes depuis minuit pour le début de la plage.
  static int _parseStart(String range) {
    final parts = range.split(RegExp(r'–|-'));
    if (parts.isEmpty) return 0;
    final hm = parts[0].trim().split(':');
    if (hm.length != 2) return 0;
    final h = int.tryParse(hm[0]) ?? 0;
    final m = int.tryParse(hm[1]) ?? 0;
    return h * 60 + m;
  }

  /// Extrait les minutes depuis minuit pour la fin de la plage.
  static int _parseEnd(String range) {
    final parts = range.split(RegExp(r'–|-'));
    if (parts.length < 2) return 0;
    final hm = parts[1].trim().split(':');
    if (hm.length != 2) return 0;
    final h = int.tryParse(hm[0]) ?? 0;
    final m = int.tryParse(hm[1]) ?? 0;
    return h * 60 + m;
  }

  /// Durée de la plage en minutes.
  int get durationInMinutes => endInMinutes - startInMinutes;

  @override
  List<Object?> get props => [
    timeRange,
    task,
    completed,
    startInMinutes,
    endInMinutes,
  ];
}
