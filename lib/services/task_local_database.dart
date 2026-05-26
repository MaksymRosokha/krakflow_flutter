import 'package:hive_ce/hive.dart';
import '../models/task.dart';
import 'dart:developer';

class TaskLocalDatabase {
// pobieramy box otworzony przez nas w main
  static Box get _box => Hive.box("tasks");
  static List<Task> getTasks() {
// zwraca wszystkie wartości zapisane w boxie
    log("Was downloaded the tasks", name: "task_local_database");
    return _box.values.map((item) {
      return Task.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }
  static Future<void> saveTasks(List<Task> tasks) async {
    await _box.clear();
// zapisuje zadanie pod kluczem równym jego id
    for (final task in tasks) {
      await _box.put(task.id, task.toMap());
    }
    log("Tasks were saved", name: "task_local_database");
  }
  static Future<void> addTask(Task task) async {
    await _box.put(task.id, task.toMap());
    log("Task with id: ${task.id} was added", name: "task_local_database");
  }
  static Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
    log("Task with id: ${task.id} was updated", name: "task_local_database");
  }
  static Future<void> deleteTask(int id) async {
// usuwa zadanie zapisane pod danym kluczem
    await _box.delete(id);
    log("Task with id: $id was deleted", name: "task_local_database");
  }
  static Future<void> deleteAllTasks() async {
    await _box.clear();
    log("All tasks were deleted", name: "task_local_database");
  }
  static bool isEmpty() {
    return _box.isEmpty;
  }
}
