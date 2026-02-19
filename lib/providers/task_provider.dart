import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/local_storage_service.dart';

class TaskProvider with ChangeNotifier {
  final LocalStorageService _storageService = LocalStorageService();
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _storageService.getTasks();
    } catch (e) {
      debugPrint("Error loading tasks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(String title, String description, DateTime date) async {
    final newTask = Task(title: title, description: description, date: date);
    await _storageService.addTask(newTask);
    await loadTasks();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await _storageService.updateTask(updatedTask);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _storageService.deleteTask(id);
    await loadTasks();
  }

  Future<void> updateTaskContent(Task task) async {
    await _storageService.updateTask(task);
    await loadTasks();
  }
}
