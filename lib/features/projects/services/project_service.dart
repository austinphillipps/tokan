// lib/features/projects/services/project_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_models.dart';

class ProjectService {
  final CollectionReference _projectsRef =
  FirebaseFirestore.instance.collection('projects');

  /// Crée un nouveau projet et retourne son nouvel ID.
  Future<String> createProject(Project project) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerId = currentUser?.uid ?? '';
    final data = project.toMap()..['ownerId'] = ownerId;
    // Initialise la liste des plugins activés vide
    data['plugins'] = <String>[];
    final docRef = await _projectsRef.add(data);
    return docRef.id;
  }

  /// Crée ou met à jour selon que project.id soit vide ou non.
  Future<void> updateProject(Project project) async {
    if (project.id.isEmpty) {
      // Nouveau projet : on crée
      await createProject(project);
      return;
    }
    final docRef = _projectsRef.doc(project.id);
    final prev = await docRef.get();
    final oldList = <String>{};
    if (prev.exists) {
      final prevData = prev.data() as Map<String, dynamic>;
      final prevCollabs = prevData['collaborators'] as List<dynamic>? ?? [];
      for (var c in prevCollabs) {
        if (c is Map<String, dynamic>) {
          final uid = c['uid'] as String?;
          if (uid != null) oldList.add(uid);
        } else if (c is String) {
          oldList.add(c);
        }
      }
    }

    // Projet existant : on met à jour
    final data = project.toMap()..['ownerId'] = project.ownerId;
    await docRef.update(data);

    final newList = project.collaborators.map((c) => c.uid).toSet();
    final added = newList.difference(oldList);
    for (var uid in added) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientId': uid,
        'type': 'project_invite',
        'title': 'Nouveau projet',
        'body': 'Vous avez été ajouté au projet ${project.name}',
        'projectId': project.id,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
  }

  /// Supprime un projet.
  Future<void> deleteProject(String projectId) async {
    await _projectsRef.doc(projectId).delete();
  }

  /// Flux des projets accessibles à l'utilisateur (propriétaire ou collaborateur).
  Stream<List<Project>> getProjectsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _projectsRef.snapshots().map((snap) {
      return snap.docs
          .map((d) =>
          Project.fromMap(d.data() as Map<String, dynamic>, d.id))
          .where((proj) {
        if (uid == null) return false;
        final isOwner = proj.ownerId == uid;
        final isCollaborator =
        proj.collaborators.any((c) => c.uid == uid);
        return isOwner || isCollaborator;
      }).toList();
    });
  }

  /// Récupère la liste des IDs de plugins activés pour le projet donné.
  Future<List<String>> getActivatedPlugins(String projectId) async {
    final doc = await _projectsRef.doc(projectId).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    final list = data['plugins'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// Active ou désactive un plugin pour le projet donné.
  Future<void> setPluginActivation(
      String projectId, String pluginId, bool enabled) async {
    final docRef = _projectsRef.doc(projectId);
    if (enabled) {
      await docRef.update({
        'plugins': FieldValue.arrayUnion([pluginId])
      });
    } else {
      await docRef.update({
        'plugins': FieldValue.arrayRemove([pluginId])
      });
    }
  }
}
