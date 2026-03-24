import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final List<Task> tasks = [
    Task(title: "Write unit tests", deadline: "next week", done: true, priority:"important"),
    Task(title: "Fix UI bugs", deadline: "today", done: false, priority:"not important"),
    Task(title: "Prepare presentation", deadline: "Friday", done: false, priority:"very important"),
    Task(title: "Review code", deadline: "this week", done: false, priority:"important"),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("KrakFlow")),
        body: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today you have ${tasks.length} tasks",
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      "Today tasks:",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            TaskCard(
              title: tasks[0].title,
              subtitle: "Subtitle for TaskCard1",
              icon: Icons.check,
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(subtitle),
        ),
      ),
    );
  }
}
