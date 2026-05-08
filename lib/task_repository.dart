import "../models/task.dart";
import '../services/task_api_service.dart';

class TaskRepository {
  static List<Task> tasks = [
    Task(
      title: "Write unit tests",
      deadline: "next week",
      done: true,
      priority: "high",
    ),
    Task(
      title: "Fix UI bugs",
      deadline: "today",
      done: false,
      priority: "average",
    ),
    Task(
      title: "Prepare presentation",
      deadline: "Friday",
      done: false,
      priority: "high",
    ),
    Task(
      title: "Review code",
      deadline: "this week",
      done: false,
      priority: "low",
    ),
  ];
}