import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../services/task_local_database.dart';
import '../services/task_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("tasks");

  TaskIdGenerator.init(TaskLocalDatabase.getTasks());

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
  int allTasksCount = 0;
  int doneTasksCount = 0;

  int refreshKey = 0; // Licznik odświeżeń

  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((task) => task.done).length;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    content: Text("Are you sure you want to delete all tasks?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await TaskLocalDatabase.deleteAllTasks();
                          setState(() {
                            refreshKey++;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("All the tasks were deleted!"),
                            ),
                          );

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
                  "Today you have $allTasksCount task(s)",
                  style: TextStyle(fontSize: 24),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 30),
                child: Text(
                  "You have done $doneTasksCount task(s)",
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
          TaskListScreen(
            key: ValueKey(refreshKey),
            selectedFilter: selectedFilter,
            onTasksLoaded: updateCounters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
            setState(() {
              refreshKey++;
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final String selectedFilter;
  final ValueChanged<List<Task>> onTasksLoaded;

  const TaskListScreen({
    super.key,
    required this.selectedFilter,
    required this.onTasksLoaded,
  });

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

  Future<void> addTask(Task task) async {
    await TaskLocalDatabase.addTask(task);
    await loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        List<Task> tasks = snapshot.data ?? [];

        if (widget.selectedFilter == "done") {
          tasks = tasks.where((task) => task.done).toList();
        } else if (widget.selectedFilter == "active") {
          tasks = tasks.where((task) => !task.done).toList();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onTasksLoaded(tasks);
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Dismissible(
              key: ValueKey(task.id),
              direction: DismissDirection.endToStart,

              onDismissed: (direction) async {
                setState(() {
                  tasks.removeAt(index);
                });

                TaskLocalDatabase.deleteTask(task.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Task "${task.title}" was deleted!')),
                );
              },

              child: TaskCard(
                title: task.title,
                subtitle:
                    "deadline: ${task.deadline} | priority: ${task.priority}",
                done: task.done,
                onChanged: (value) async {
                  final updatedTask = Task(
                    id: task.id,
                    title: task.title,
                    deadline: task.deadline,
                    priority: task.priority,
                    done: value ?? false,
                  );
                  await TaskLocalDatabase.updateTask(updatedTask);
                  setState(() {
                    tasksFuture = loadTasks();
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
                    await TaskLocalDatabase.updateTask(updatedTask);
                    setState(() {
                      tasksFuture = loadTasks();
                    });
                  }
                },
              ),
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
                  id: TaskIdGenerator.nextId(),
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

class TaskIdGenerator {
  static int _lastId = 0;

  static void init(List<Task> tasks) {
    if (tasks.isEmpty) {
      _lastId = 0;
    } else {
      _lastId = tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b);
    }
  }

  static int nextId() {
    _lastId++;
    return _lastId;
  }
}