import 'package:hive_ce/hive.dart';
import '../models/task.dart';

class TaskLocalDatabase {
// pobieramy box otworzony przez nas w main
  static Box get _box => Hive.box("tasks");
  static List<Task> getTasks() {
// zwraca wszystkie wartości zapisane w boxie
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
  }
  static Future<void> addTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }
  static Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }
  static Future<void> deleteTask(int id) async {
// usuwa zadanie zapisane pod danym kluczem
    await _box.delete(id);
  }
  static Future<void> deleteAllTasks() async {
    await _box.clear();
  }
  static bool isEmpty() {
    return _box.isEmpty;
  }
}
