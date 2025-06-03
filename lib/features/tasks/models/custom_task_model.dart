import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTask {
  String id;
  String name;
  String description;
  List<CustomTask> subTasks;
  String status;         // Exemple : "pending", "inProgress", "completed", etc.
  String responsable;
  DateTime? deadline;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int? duration; // Durée estimée en minutes
  String? client; // Nom du client (optionnel)
  String? project; // Projet d'appartenance (optionnel)

  CustomTask({
    this.id = '',
    required this.name,
    required this.description,
    List<CustomTask>? subTasks,
    this.status = 'pending',
    this.responsable = '',
    this.deadline,
    this.startTime,
    this.endTime,
    this.duration,
    this.client,
    this.project,
  }) : subTasks = subTasks ?? [];

  /// Retourne la DateTime de début en combinant la deadline et le startTime.
  DateTime get start {
    final date = deadline ?? DateTime.now();
    final st = startTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(date.year, date.month, date.day, st.hour, st.minute);
  }

  /// Retourne la DateTime de fin en combinant la deadline et le endTime.
  DateTime get end {
    final date = deadline ?? DateTime.now();
    final et = endTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(date.year, date.month, date.day, et.hour, et.minute);
  }

  /// Convertit un TimeOfDay en chaîne au format "HH:mm".
  static String _formatTime(TimeOfDay time) {
    return time.hour.toString().padLeft(2, '0') + ":" + time.minute.toString().padLeft(2, '0');
  }

  /// Sérialisation pour Firestore avec des formats normalisés.
  Map<String, dynamic> toMap(String userId) {
    return {
      'name': name,
      'description': description,
      'status': status,
      'responsable': responsable,
      'deadline': deadline != null ? DateFormat('yyyy-MM-dd').format(deadline!) : null,
      'startTime': startTime != null ? _formatTime(startTime!) : null,
      'endTime': endTime != null ? _formatTime(endTime!) : null,
      'duration': duration,
      'client': client,
      'project': project,
      'subTasks': subTasks.map((t) => t._toSubMap()).toList(),
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Sérialisation pour une sous‑tâche.
  Map<String, dynamic> _toSubMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'responsable': responsable,
      'deadline': deadline != null ? DateFormat('yyyy-MM-dd').format(deadline!) : null,
      'startTime': startTime != null ? _formatTime(startTime!) : null,
      'endTime': endTime != null ? _formatTime(endTime!) : null,
      'duration': duration,
      'client': client,
      'project': project,
      'subTasks': subTasks.map((t) => t._toSubMap()).toList(),
    };
  }

  static DateTime? _mapToDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value); // Ex. "2025-04-15"
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static TimeOfDay? _mapToTimeOfDay(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        final parts = value.split(":");
        if (parts.length == 2) {
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (_) {
        return null;
      }
    } else if (value is Map) {
      final hour = value['hour'] ?? 0;
      final minute = value['minute'] ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  factory CustomTask.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomTask(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      responsable: map['responsable'] ?? '',
      deadline: _mapToDate(map['deadline']),
      startTime: _mapToTimeOfDay(map['startTime']),
      endTime: _mapToTimeOfDay(map['endTime']),
      duration: map['duration'],
      client: map['client'],
      project: map['project'],
      subTasks: map['subTasks'] != null
          ? List<CustomTask>.from(
          (map['subTasks'] as List)
              .map((subMap) => CustomTask._fromSubMap(subMap as Map<String, dynamic>)))
          : [],
    );
  }

  factory CustomTask._fromSubMap(Map<String, dynamic> map) {
    return CustomTask(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      responsable: map['responsable'] ?? '',
      deadline: _mapToDate(map['deadline']),
      startTime: _mapToTimeOfDay(map['startTime']),
      endTime: _mapToTimeOfDay(map['endTime']),
      duration: map['duration'],
      client: map['client'],
      project: map['project'],
      subTasks: map['subTasks'] != null
          ? List<CustomTask>.from(
          (map['subTasks'] as List)
              .map((subMap) => CustomTask._fromSubMap(subMap as Map<String, dynamic>)))
          : [],
    );
  }

  CustomTask copy() {
    return CustomTask(
      id: id,
      name: name,
      description: description,
      status: status,
      responsable: responsable,
      deadline: deadline,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      client: client,
      project: project,
      subTasks: subTasks.map((t) => t.copy()).toList(),
    );
  }
}
