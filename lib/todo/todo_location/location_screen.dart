import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';

import '../todo_details/database_helper.dart';
import '../todo_details/details_screen.dart';

class LocationScreen extends StatefulWidget {
  final int taskId;
  final String title;
  final String description;
  final String? imagePath;

  const LocationScreen({
    Key? key,
    required this.taskId,
    required this.title,
    required this.description,
    this.imagePath,
  }) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _currentPosition;
  String? _currentAddress;
  Set<int> _completedTaskIds = {};
  List<Map<String, dynamic>> _tasks = [];
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadTasks();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      isConnected = result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
      print("Connectivity Status: $result, isConnected: $isConnected"); // Debug print
    });
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromLatLng(position);
      print("Current location: $_currentPosition");
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        "${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
      print("Current address: $_currentAddress");
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper().getTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  void _toggleCompletion(int taskId) {
    setState(() {
      if (_completedTaskIds.contains(taskId)) {
        _completedTaskIds.remove(taskId);
      } else {
        _completedTaskIds.add(taskId);
      }
    });
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      await DatabaseHelper().deleteTask(taskId);
      _loadTasks(); // Reload tasks after deletion
    } catch (e) {
      print("Error deleting task: $e");
    }
  }

  Future<void> _showDeleteConfirmationDialog(int taskId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(backgroundColor: Color(0xFF14111E),
          title: Text('Delete Task',style: TextStyle(color: Colors.white,fontSize: 19),),
          content: Text('Do you want to delete this task?',style: TextStyle(color: Colors.white),),
          actions: <Widget>[
            TextButton(style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Color(0xFF14111E))),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel',style: TextStyle(color: Colors.white),),
            ),
            TextButton(style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Color(0xF0231933))),
              onPressed: () {
                _deleteTask(taskId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xF0231933),
        title: const Text("Task Location",style: TextStyle(color: Colors.white,),),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  Text(
                    isConnected ? "Connected" : "Disconnected",
                    style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xF0131018),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xF0231933),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DetailsScreen(),
              ));
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            final isComplete = _completedTaskIds.contains(task['id']);
            return Card(color: Color(0xF01A1621),
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        task['imagePath'] != null
                            ? ClipOval(
                          child: Image.file(
                            File(task['imagePath']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(Icons.image, size: 50),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'],
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(task['description'],style: TextStyle(color: Colors.white),),
                              if (_currentAddress != null) ...[
                                const SizedBox(height: 8), // Space between description and address
                                Divider(height: 1, thickness: 0.5, color: Colors.grey), // Very thin divider
                                Text(
                                  _currentAddress!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8), // Space between description/address and status
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(side: BorderSide(color: Colors.white),
                                          value: isComplete,
                                          onChanged: (bool? value) {
                                            _toggleCompletion(task['id']);
                                          },
                                        ),
                                        Text(
                                          isComplete ? 'Complete' : 'Incomplete',
                                          style: TextStyle(
                                            color: isComplete ? Colors.white : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    child: PopupMenuButton<String>(color: Color(0xF0231933),
                                      onSelected: (String value) {
                                        if (value == 'delete') {
                                          _showDeleteConfirmationDialog(task['id']);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text('Delete',style: TextStyle(color: Colors.white),),
                                            ],
                                          ),
                                        ),
                                      ],
                                      child: Icon(Icons.more_vert,color: Colors.white,),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}







