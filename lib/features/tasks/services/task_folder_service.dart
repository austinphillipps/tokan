import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_folder_model.dart';

class TaskFolderService {
  final CollectionReference _collection =
  FirebaseFirestore.instance.collection('taskFolders');

  Stream<List<TaskFolder>> getFolders(String projectId) {
    return _collection
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => TaskFolder.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  Future<TaskFolder> createFolder(TaskFolder folder) async {
    final doc = await _collection.add(folder.toMap());
    folder.id = doc.id;
    return folder;
  }

  Future<void> updateFolder(TaskFolder folder) async {
    await _collection.doc(folder.id).update(folder.toMap());
  }

  Future<void> deleteFolder(String id) async {
    await _collection.doc(id).delete();
  }
}