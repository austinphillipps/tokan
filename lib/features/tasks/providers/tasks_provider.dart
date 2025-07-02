// lib/providers/tasks_provider.dart
import 'package:flutter/material.dart';
import '../models/custom_task_model.dart';
import '../services/task_repository.dart';

class TasksProvider with ChangeNotifier {
  final TaskRepository repository;
  List<CustomTask> _tasks = [];

  TasksProvider({required this.repository}) {
    repository.getTasksStream().listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });
  }

  List<CustomTask> get tasks => _tasks;

  Future<void> saveTask(CustomTask task) async {
    await repository.saveTask(task);
    // Le flux mettra automatiquement à jour _tasks
  }
}
