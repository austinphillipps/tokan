import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTask extends Equatable {
  String id;
  String name;
  String description;
  List<CustomTask> subTasks;
  String status;         // Exemple : "pending", "inProgress", "completed", etc.
  String responsable;
  DateTime? deadline;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int? duration;         // Durée estimée en minutes
  String? client;        // Nom du client (optionnel)
  String? project;       // Projet d’appartenance (optionnel)

  /// ID du projet avant édition, pour détecter les changements de projet
  String? originalProjectId;

  // Nouveaux champs pour la récurrence
  /// 'none' | 'sameDay' | 'weekdays' | 'weekends'
  String? recurrenceType;

  /// Liste des indices des jours (0=Lundi ... 6=Dimanche)
  List<int>? recurrenceDays;

  /// Inclure ou non les occurrences antérieures
  bool? recurrenceIncludePast;

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
    this.originalProjectId,
    this.recurrenceType,
    this.recurrenceDays,
    this.recurrenceIncludePast,
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
      // Champs de récurrence
      'recurrenceType': recurrenceType,
      'recurrenceDays': recurrenceDays,
      'recurrenceIncludePast': recurrenceIncludePast ?? false,
      'subTasks': subTasks.map((t) => t._toSubMap()).toList(),
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Sérialisation pour une sous‐tâche.
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
      'recurrenceType': recurrenceType,
      'recurrenceDays': recurrenceDays,
      'recurrenceIncludePast': recurrenceIncludePast ?? false,
      'subTasks': subTasks.map((t) => t._toSubMap()).toList(),
    };
  }

  static String _formatTime(TimeOfDay time) {
    return time.hour.toString().padLeft(2, '0') + ":" + time.minute.toString().padLeft(2, '0');
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

  static List<int>? _mapToRecurrenceDays(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      try {
        return List<int>.from(value.map((e) => e as int));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory CustomTask.fromMap(Map<String, dynamic> map, String documentId) {
    final String? proj = map['project'] as String?;
    return CustomTask(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      responsable: map['responsable'] ?? '',
      deadline: _mapToDate(map['deadline']),
      startTime: _mapToTimeOfDay(map['startTime']),
      endTime: _mapToTimeOfDay(map['endTime']),
      duration: map['duration'] as int?,
      client: map['client'] as String?,
      project: proj,
      originalProjectId: proj,
      recurrenceType: map['recurrenceType'] as String?,
      recurrenceDays: _mapToRecurrenceDays(map['recurrenceDays']),
      recurrenceIncludePast: map['recurrenceIncludePast'] as bool?,
      subTasks: map['subTasks'] != null
          ? List<CustomTask>.from(
        (map['subTasks'] as List).map(
              (subMap) => CustomTask._fromSubMap(subMap as Map<String, dynamic>),
        ),
      )
          : [],
    );
  }

  factory CustomTask._fromSubMap(Map<String, dynamic> map) {
    final String? proj = map['project'] as String?;
    return CustomTask(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      responsable: map['responsable'] ?? '',
      deadline: _mapToDate(map['deadline']),
      startTime: _mapToTimeOfDay(map['startTime']),
      endTime: _mapToTimeOfDay(map['endTime']),
      duration: map['duration'] as int?,
      client: map['client'] as String?,
      project: proj,
      originalProjectId: proj,
      recurrenceType: map['recurrenceType'] as String?,
      recurrenceDays: _mapToRecurrenceDays(map['recurrenceDays']),
      recurrenceIncludePast: map['recurrenceIncludePast'] as bool?,
      subTasks: map['subTasks'] != null
          ? List<CustomTask>.from(
        (map['subTasks'] as List).map(
              (subMap) => CustomTask._fromSubMap(subMap as Map<String, dynamic>),
        ),
      )
          : [],
    );
  }

  CustomTask copyWith({
    String? id,
    String? name,
    String? description,
    List<CustomTask>? subTasks,
    String? status,
    String? responsable,
    DateTime? deadline,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? duration,
    String? client,
    String? project,
    String? originalProjectId,
    String? recurrenceType,
    List<int>? recurrenceDays,
    bool? recurrenceIncludePast,
  }) {
    return CustomTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subTasks: subTasks ?? List<CustomTask>.from(this.subTasks),
      status: status ?? this.status,
      responsable: responsable ?? this.responsable,
      deadline: deadline ?? this.deadline,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      client: client ?? this.client,
      project: project ?? this.project,
      originalProjectId: originalProjectId ?? this.originalProjectId,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays != null ? List<int>.from(recurrenceDays) : this.recurrenceDays,
      recurrenceIncludePast: recurrenceIncludePast ?? this.recurrenceIncludePast,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    subTasks,
    status,
    responsable,
    deadline,
    startTime?.hour,
    startTime?.minute,
    endTime?.hour,
    endTime?.minute,
    duration,
    client,
    project,
    originalProjectId,
    recurrenceType,
    recurrenceDays,
    recurrenceIncludePast,
  ];
}