import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import 'dart:math' hide log;
import 'dart:developer';

final random = Random();
final priorities = ["low", "average", "high"];
final deadlines = ["today", "this week", "this month", "tomorrow", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";
  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/todos"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];
      log("From $baseUrl/todos", name: "task_api_service");
      log("Response: ${response.statusCode}", name: "task_api_service");
      log("Downloaded ${todos.length} tasks", name: "task_api_service");

      return todos.map((todo) {
        final priority = priorities[random.nextInt(priorities.length)];
        final deadline = deadlines[random.nextInt(deadlines.length)];
        return Task(
          id: todo["id"],
          title: todo["todo"],
          deadline: deadline,
          done: todo["completed"],
          priority: priority,
        );
      }).toList();
    } else {
      log("From $baseUrl/todos", name: "task_api_service");
      log("Response: ${response.statusCode}", name: "task_api_service");
      log("An error occurred");
      throw Exception("Data collection error");
    }
  }
}