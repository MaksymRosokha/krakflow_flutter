import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../services/task_api_service.dart';
import '../services/task_local_database.dart';
import '../services/task_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("tasks");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filter = "all";
  String selectedFilter = "all";

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = TaskRepository.tasks;
    if (selectedFilter == "done") {
      filteredTasks = TaskRepository.tasks.where((task) => task.done).toList();
    } else if (selectedFilter == "active") {
      filteredTasks = TaskRepository.tasks.where((task) => !task.done).toList();
    } else if (selectedFilter == "all") {
      filteredTasks = TaskRepository.tasks;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Confirmation"),
                    content: Text(
                      "Are you sure you want to delete all tasks?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            TaskRepository.tasks.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("All the tasks were deleted!"),
                              ),
                            );
                          });
                          Navigator.pop(context);
                        },
                        child: Text("Delete"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 30),
                child: Text(
                  "Today you have ${TaskRepository.tasks.length} task(s)",
                  style: TextStyle(fontSize: 24),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 30),
                child: Text(
                  "You have done ${TaskRepository.tasks.where((t) => t.done).toList().length} task(s)",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Today's tasks:",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedFilter = "all";
                  });
                },
                child: Text(
                  "All",
                  style: TextStyle(
                    color: selectedFilter == "all"
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedFilter = "active";
                  });
                },
                child: Text(
                  "Active",
                  style: TextStyle(
                    color: selectedFilter == "active"
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedFilter = "done";
                  });
                },
                child: Text(
                  "Done",
                  style: TextStyle(
                    color: selectedFilter == "done"
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return Dismissible(
                key: ValueKey(task.title),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Task \"${task.title}\" was deleted!"),
                    ),
                  );
                  TaskRepository.tasks.remove(task);
                },
                child: TaskCard(
                  title: task.title,
                  subtitle:
                      "deadline: ${task.deadline} | priority: ${task.priority}",
                  done: task.done,
                  onChanged: (value) {
                    setState(() {
                      task.done = value!;
                    });
                  },
                  onTap: () async {
                    final Task? updatedTask = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskScreen(task: task),
                      ),
                    );
                    if (updatedTask != null) {
                      setState(() {
                        TaskRepository.tasks[index] = updatedTask;
                      });
                    }
                  },
                ),
              );
            },
          ),
          TaskListScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

// class TaskListScreen extends StatelessWidget {
//   const TaskListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Task>>(
//       future: TaskApiService.fetchTasks(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//         if (snapshot.hasError) {
//           return Center(
//             child: Text("Error: ${snapshot.error}"),
//           );
//         }
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(
//             child: Text("No tasks"),
//           );
//         }
//
//         final tasks = snapshot.data!;
//         return ListView(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           children: tasks.map((task) {
//             return TaskCard(
//               title: task.title,
//               subtitle: "deadline: ${task.deadline} | priority: ${task.priority}",
//               done: task.done,
//               onChanged: (value) {
//                   task.done = value!;
//               },
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
// }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}
class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;
  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }
  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Błąd: ${snapshot.error}"),
          );
        }
        final tasks = snapshot.data ?? [];
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
                title: task.title,
                subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                done: task.done,
                onChanged: (value) {
// zmiana checkboxa
            },
            onTap: () {
// edycja zadania
            },
            );
          },
        );
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onChanged;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: done, onChanged: onChanged),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
            color: done
                ? Color.fromARGB(255, 150, 150, 150)
                : Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text(
            subtitle,
            style: TextStyle(
              color: done
                  ? Color.fromARGB(255, 150, 150, 150)
                  : Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();
  final bool done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("New task")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Task title",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Task deadline",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Task priority",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  id: 0,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: done,
                  priority: priorityController.text,
                );
                Navigator.pop(context, newTask);
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  EditTaskScreen({super.key, required this.task}) {
    titleController.text = task.title;
    deadlineController.text = task.deadline;
    priorityController.text = task.priority;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update task")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Task title",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Task deadline",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Task priority",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                task.title = titleController.text;
                task.deadline = deadlineController.text;
                task.priority = priorityController.text;

                Navigator.pop(context, task);
              },
              child: Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
