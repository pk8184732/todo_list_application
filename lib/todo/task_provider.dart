import 'dart:io';
import 'package:flutter/material.dart';
import 'package:todo_list_application/todo/task.dart';

class TaskProvider with ChangeNotifier {
  List<ToDoModel> _tasks = [];

  List<ToDoModel> get tasks => _tasks;

  void addTask(ToDoModel task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(ToDoModel task) {
    _tasks.remove(task);
    notifyListeners();
  }

// You can add other methods for task manipulation as needed
}





