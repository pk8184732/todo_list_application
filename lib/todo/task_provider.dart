import 'dart:io';
import 'package:flutter/material.dart';
import 'package:todo_list_application/todo/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    notifyListeners();
  }

// You can add other methods for task manipulation as needed
}





