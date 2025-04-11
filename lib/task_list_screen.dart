// task_list_screen.dart

import 'package:flutter/material.dart';
import 'google_drive_service.dart';
import 'task_record_screen.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await loadReadingTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load tasks: $e")),
      );
    }
  }

  void _openRecordScreen(Map<String, dynamic> task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskRecordScreen(task: task)),
    );
    _loadTasks(); // Reload after recording in case it was marked complete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reading Tasks')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(child: Text('No tasks available.'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final isCompleted = task['isCompleted'] ?? false;

                    return ListTile(
                      title: Text(task['text'] ?? ''),
                      subtitle: Text('Created: ${task['createdAt'] ?? ''}'),
                      trailing: isCompleted
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                              onPressed: () => _openRecordScreen(task),
                              child: Text('Record'),
                            ),
                    );
                  },
                ),
    );
  }
}
