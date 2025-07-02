// lib/services/task_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final String? currentUserId;

  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
  // Utilisez l'opérateur ? pour obtenir l'uid ou null
        currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Stream<List<CustomTask>> getTasksStream() {
    if (currentUserId == null) {
      // Si aucun utilisateur n'est connecté, on renvoie un flux vide.
      return Stream.empty();
    }
    return _firestore
        .collection('tasks')
        .where('createdBy', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return CustomTask.fromMap(data, doc.id);
    }).toList());
  }

  Future<void> saveTask(CustomTask task) async {
    if (currentUserId == null) {
      // Vous pouvez aussi lancer une exception ici si besoin
      throw Exception("Aucun utilisateur connecté");
    }
    final tasksCollection = _firestore.collection('tasks');
    if (task.id.isEmpty) {
      if (task.status.isEmpty) task.status = "à venir";
      DocumentReference docRef = await tasksCollection.add(task.toMap(currentUserId!));
      task.id = docRef.id;
    } else {
      await tasksCollection.doc(task.id).update(task.toMap(currentUserId!));
    }
  }
}
