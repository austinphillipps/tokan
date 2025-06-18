import 'package:flutter/material.dart';

/// Représente un collaborateur au sein d’un projet
class Collaborator {
  final String uid;
  final String role;

  Collaborator({
    required this.uid,
    required this.role,
  });

  /// Sérialise en Map pour Firestore
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'role': role,
  };

  /// Désérialise depuis Firestore
  factory Collaborator.fromMap(Map<String, dynamic> map) {
    return Collaborator(
      uid: map['uid'] as String? ?? '',
      role: map['role'] as String? ?? 'viewer',
    );
  }
}

/// Modèle représentant un projet
enum ProjectType { simple }

/// Modèle représentant un projet
class Project {
  String id;
  String name;
  String description;
  String ownerId;
  String? objective;
  List<Collaborator> collaborators;
  String? color; // code hexadécimal (ex: "ff00ff00")

  /// Type du projet
  ProjectType type;

  /// Liste des plugins installés pour ce projet
  List<String>? plugins;

  Project({
    this.id = '',
    required this.name,
    required this.description,
    required this.ownerId,
    this.objective,
    List<Collaborator>? collaborators,
    this.color,
    this.type = ProjectType.simple,
    this.plugins, // ← prend en charge la liste des plugins (ex: ['crm', ...])
  }) : collaborators = collaborators ?? [];

  /// Clone le projet en ne modifiant que certains champs
  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? objective,
    List<Collaborator>? collaborators,
    String? color,
    ProjectType? type,
    List<String>? plugins, // ← on ajoute ce champ pour la copie
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      objective: objective ?? this.objective,
      collaborators: collaborators ?? this.collaborators,
      color: color ?? this.color,
      type: type ?? this.type,
      plugins: plugins ?? this.plugins,
    );
  }

  /// Sérialisation pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'type': 'simple',
      if (objective != null) 'objective': objective,
      if (color != null) 'color': color,
      'collaborators': collaborators.map((c) => c.toMap()).toList(),
      // ← ON AJOUTE LE CHAMP "plugins" EN BDD
      if (plugins != null) 'plugins': plugins,
    };
  }

  /// Désérialisation depuis Firestore (map + id)
  factory Project.fromMap(Map<String, dynamic> map, String id) {
    return Project(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      type: ProjectType.simple,
      objective: map['objective'] as String?,
      color: map['color'] as String?,
      collaborators: (map['collaborators'] as List<dynamic>?)
          ?.map((e) {
        if (e is Map<String, dynamic>) {
          return Collaborator.fromMap(e);
        } else {
          return Collaborator(uid: e.toString(), role: 'viewer');
        }
      })
          .toList() ??
          [],
      // ← ON RÉCUPÈRE LE CHAMP "plugins" S’IL EXISTE
      plugins: (map['plugins'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}