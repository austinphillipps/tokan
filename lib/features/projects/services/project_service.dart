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
    final data = project.toMap()
      ..['ownerId'] = ownerId;
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
    // Projet existant : on met à jour
    final data = project.toMap()
      ..['ownerId'] = project.ownerId;
    await _projectsRef.doc(project.id).update(data);
  }

  Future<void> deleteProject(String projectId) async {
    await _projectsRef.doc(projectId).delete();
  }

  Stream<List<Project>> getProjectsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _projectsRef.snapshots().map((snap) {
      return snap.docs
          .map((d) => Project.fromMap(d.data() as Map<String, dynamic>, d.id))
          .where((proj) {
        if (uid == null) return false;
        final isOwner = proj.ownerId == uid;
        final isCollaborator =
        proj.collaborators.any((c) => c.uid == uid);
        return isOwner || isCollaborator;
      })
          .toList();
    });
  }
}
