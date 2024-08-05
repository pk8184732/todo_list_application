import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../todo_details/database_helper.dart';
import '../todo_details/details_screen.dart';
import '../todo_details/update/update_screen.dart';

class WifiConnectionScreen extends StatefulWidget {
  const WifiConnectionScreen({Key? key}) : super(key: key);

  @override
  _WifiConnectionScreenState createState() => _WifiConnectionScreenState();
}

class _WifiConnectionScreenState extends State<WifiConnectionScreen> {
  List<Map<String, dynamic>> _tasks = [];
  String? _currentAddress;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadTasks();
    _getCurrentLocation();
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
      print("Connectivity Status: $result, isConnected: $isConnected");
    });
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseHelper().getTasks();
    setState(() {
      _tasks = tasks;
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
        return AlertDialog(
          backgroundColor: Color(0xFF14111E),
          titleTextStyle: TextStyle(color: Colors.white,fontSize: 19),
          title: Text('Delete Task',),
          content: Text('Do you want to delete this task?',style: TextStyle(color: Colors.white),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel',style: TextStyle(color: Colors.white),),
            ),
            TextButton(
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

  void _toggleCompletion(int taskId) async {
    setState(() {
      final index = _tasks.indexWhere((task) => task['id'] == taskId);
      if (index != -1) {
        final isComplete = _tasks[index]['isComplete'] == 1;
        _tasks[index]['isComplete'] = isComplete ? 0 : 1;
        DatabaseHelper().updateTask(_tasks[index]);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _getAddressFromLatLng(position);
      print("Current location: $position");
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
      Placemark place = placemarks.first;
      setState(() {
        _currentAddress = "${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
      print("Current address: $_currentAddress");
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141A1E),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF231F33),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DetailsScreen(),
            ),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "Task List",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w300,
          ),
        ),
        backgroundColor: const Color(0xFF231F33),
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
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? "Connected" : "Disconnected",
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            final isComplete = task['isComplete'] == 1;

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              color: const Color(0xFF1F1B24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task['imagePath'] != null)
                      Image.file(
                        File(task['imagePath']),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 16.0),
                    Text(
                      task['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      task['description'],
                      style: TextStyle(color: Colors.white70),
                    ),
                    if (_currentAddress != null) ...[
                      const SizedBox(height: 8.0),
                      Divider(color: Colors.white24),
                      Text(
                        _currentAddress!,
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.only(left: 172),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Checkbox(
                            value: isComplete,
                            onChanged: (bool? value) {
                              if (value != null) {
                                _toggleCompletion(task['id']);
                              }
                            },
                          ),
                          Expanded(
                            child: Row(
                              children: [
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
                          PopupMenuButton<String>(color: Color(0xFF19162A),
                            onSelected: (String value) {
                              if (value == 'delete') {
                                _showDeleteConfirmationDialog(task['id']);
                              } else if (value == 'update') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateScreen(task: task),
                                  ),
                                ).then((_) {
                                  // Refresh the task list when returning from UpdateScreen
                                  _loadTasks();
                                });
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(textStyle: TextStyle(color: Colors.white,
                                  backgroundColor: Color(0xFF19162A)),
                                value: 'update',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('Update',style: TextStyle(color: Colors.white),),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',textStyle: TextStyle(color: Colors.white,),
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.white,),
                                    const SizedBox(width: 8),
                                    Text('Delete',style: TextStyle(color: Colors.white),),
                                  ],
                                ),
                              ),
                            ],
                            child: Icon(Icons.more_vert, color: Colors.white,),
                          ),
                        ],
                      ),
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









//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
//
// import '../todo_details/database_helper.dart';
// import '../todo_details/details_screen.dart';
// import '../todo_details/update/update_screen.dart';
//
// class WifiConnectionScreen extends StatefulWidget {
//   const WifiConnectionScreen({Key? key}) : super(key: key);
//
//   @override
//   _WifiConnectionScreenState createState() => _WifiConnectionScreenState();
// }
//
// class _WifiConnectionScreenState extends State<WifiConnectionScreen> {
//   List<Map<String, dynamic>> _tasks = [];
//   String? _currentAddress;
//   bool isConnected = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkConnectivity();
//     _loadTasks();
//     _getCurrentLocation();
//     Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       _updateConnectionStatus(result);
//     });
//   }
//
//   Future<void> _checkConnectivity() async {
//     ConnectivityResult result = await Connectivity().checkConnectivity();
//     _updateConnectionStatus(result);
//   }
//
//   void _updateConnectionStatus(ConnectivityResult result) {
//     setState(() {
//       isConnected = result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;
//       print("Connectivity Status: $result, isConnected: $isConnected");
//     });
//   }
//
//   Future<void> _loadTasks() async {
//     try {
//       final tasks = await DatabaseHelper().getTasks();
//       setState(() {
//         _tasks = tasks;
//       });
//     } catch (e) {
//       print("Error loading tasks: $e");
//     }
//   }
//
//   Future<void> _deleteTask(int taskId) async {
//     try {
//       await DatabaseHelper().deleteTask(taskId);
//       _loadTasks(); // Reload tasks after deletion
//     } catch (e) {
//       print("Error deleting task: $e");
//     }
//   }
//
//   Future<void> _showDeleteConfirmationDialog(int taskId) async {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Color(0xFF14111E),
//           titleTextStyle: TextStyle(color: Colors.white, fontSize: 19),
//           title: Text('Delete Task'),
//           content: Text('Do you want to delete this task?', style: TextStyle(color: Colors.white)),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: Text('Cancel', style: TextStyle(color: Colors.white)),
//             ),
//             TextButton(
//               onPressed: () {
//                 _deleteTask(taskId);
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: Text('Delete', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _toggleCompletion(int taskId) async {
//     try {
//       final index = _tasks.indexWhere((task) => task['id'] == taskId);
//       if (index != -1) {
//         final isComplete = _tasks[index]['isComplete'] == 1;
//         final updatedTask = {
//           ..._tasks[index],
//           'isComplete': isComplete ? 0 : 1,
//         };
//         await DatabaseHelper().updateTask(updatedTask);
//         setState(() {
//           _tasks[index] = updatedTask;
//         });
//       }
//     } catch (e) {
//       print("Error updating task: $e");
//     }
//   }
//
//   Future<void> _getCurrentLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       _getAddressFromLatLng(position);
//       print("Current location: $position");
//     } catch (e) {
//       print("Error getting location: $e");
//     }
//   }
//
//   Future<void> _getAddressFromLatLng(Position position) async {
//     try {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       Placemark place = placemarks.first;
//       setState(() {
//         _currentAddress = "${place.locality}, ${place.administrativeArea}, ${place.country}";
//       });
//       print("Current address: $_currentAddress");
//     } catch (e) {
//       print("Error getting address: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF141A1E),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xFF231F33),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const DetailsScreen(),
//             ),
//           );
//         },
//         child: const Icon(
//           Icons.add,
//           color: Colors.white,
//           size: 20,
//         ),
//       ),
//       appBar: AppBar(
//         title: const Text(
//           "Task List",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 25,
//             fontWeight: FontWeight.w300,
//           ),
//         ),
//         backgroundColor: const Color(0xFF231F33),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
//             child: FittedBox(
//               fit: BoxFit.contain,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     isConnected ? Icons.wifi : Icons.wifi_off,
//                     color: isConnected ? Colors.green : Colors.red,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     isConnected ? "Connected" : "Disconnected",
//                     style: TextStyle(
//                       color: isConnected ? Colors.green : Colors.red,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView.builder(
//           itemCount: _tasks.length,
//           itemBuilder: (context, index) {
//             final task = _tasks[index];
//             final isComplete = task['isComplete'] == 1;
//
//             return Card(
//               margin: EdgeInsets.only(bottom: 16.0),
//               color: const Color(0xFF1F1B24),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (task['imagePath'] != null)
//                       Image.file(
//                         File(task['imagePath']),
//                         width: double.infinity,
//                         height: 200,
//                         fit: BoxFit.cover,
//                       ),
//                     const SizedBox(height: 16.0),
//                     Text(
//                       task['title'],
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8.0),
//                     Text(
//                       task['description'],
//                       style: TextStyle(color: Colors.white70),
//                     ),
//                     if (_currentAddress != null) ...[
//                       const SizedBox(height: 8.0),
//                       Divider(color: Colors.white24),
//                       Text(
//                         _currentAddress!,
//                         style: TextStyle(color: Colors.white54),
//                       ),
//                     ],
//                     const SizedBox(height: 8.0),
//                     Row(
//                       children: [
//                         Checkbox(
//                           value: isComplete,
//                           onChanged: (bool? value) {
//                             if (value != null) {
//                               _toggleCompletion(task['id']);
//                             }
//                           },
//                         ),
//                         Expanded(
//                           child: Text(
//                             isComplete ? 'Complete' : 'Incomplete',
//                             style: TextStyle(
//                               color: isComplete ? Colors.green : Colors.red,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         PopupMenuButton<String>(
//                           color: Color(0xFF19162A),
//                           onSelected: (String value) {
//                             if (value == 'delete') {
//                               _showDeleteConfirmationDialog(task['id']);
//                             } else if (value == 'update') {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => UpdateScreen(task: task),
//                                 ),
//                               ).then((_) {
//                                 _loadTasks(); // Refresh the task list when returning from UpdateScreen
//                               });
//                             }
//                           },
//                           itemBuilder: (BuildContext context) => [
//                             PopupMenuItem<String>(
//                               textStyle: TextStyle(color: Colors.white, backgroundColor: Color(0xFF19162A)),
//                               value: 'update',
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.edit, color: Colors.white),
//                                   const SizedBox(width: 8),
//                                   Text('Update', style: TextStyle(color: Colors.white)),
//                                 ],
//                               ),
//                             ),
//                             PopupMenuItem<String>(
//                               value: 'delete',
//                               textStyle: TextStyle(color: Colors.white),
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.delete, color: Colors.white),
//                                   const SizedBox(width: 8),
//                                   Text('Delete', style: TextStyle(color: Colors.white)),
//                                 ],
//                               ),
//                             ),
//                           ],
//                           child: Icon(Icons.more_vert, color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//






// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import '../todo_details/database_helper.dart';
//
// import '../todo_details/details_screen.dart';
// import '../todo_details/update/update_screen.dart';
//
// class WifiConnectionScreen extends StatefulWidget {
//   const WifiConnectionScreen({super.key});
//
//   @override
//   State<WifiConnectionScreen> createState() => _WifiConnectionScreenState();
// }
//
// class _WifiConnectionScreenState extends State<WifiConnectionScreen> {
//   List<Map<String, dynamic>> tasks = [];
//   late StreamSubscription<ConnectivityResult> _connectivitySubscription;
//   bool _isConnected = false;
//   String _currentLocation = "Location not available";
//   final DatabaseHelper _dbHelper = DatabaseHelper();  // Initialize DatabaseHelper
//
//   @override
//   void initState() {
//     super.initState();
//     _loadTasks();
//     _checkConnectivity();
//     _getCurrentLocation();
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       _updateConnectionStatus(result);
//     });
//   }
//
//   @override
//   void dispose() {
//     _connectivitySubscription.cancel();
//     super.dispose();
//   }
//
//   Future<void> _loadTasks() async {
//     try {
//       List<Map<String, dynamic>> loadedTasks = await _dbHelper.getTasks();
//       setState(() {
//         tasks = loadedTasks;
//       });
//       print("Loaded tasks: $tasks");  // Debugging: Print loaded tasks
//     } catch (e) {
//       print("Error loading tasks: $e");
//     }
//   }
//
//   // Future<void> _updateTaskStatus(int index, bool isComplete) async {
//   //   setState(() {
//   //     tasks[index]['isComplete'] = isComplete ? 1 : 0;
//   //   });
//   //
//   //   try {
//   //     await _dbHelper.updateTask(tasks[index]);
//   //   } catch (e) {
//   //     print("Error updating task status: $e");
//   //   }
//   // }
//   Future<void> _updateTaskStatus(int index, bool isComplete) async {
//     // Create a mutable copy of the task map
//     final updatedTask = Map<String, dynamic>.from(tasks[index]);
//     updatedTask['isComplete'] = isComplete ? 1 : 0;
//
//     // Update the state with the new task status
//     setState(() {
//       tasks[index] = updatedTask;
//     });
//
//     // Update the task status in the database
//     try {
//       await _dbHelper.updateTask(updatedTask);
//     } catch (e) {
//       print("Error updating task status: $e");
//     }
//   }
//
//   Future<void> _deleteTask(int index) async {
//     int taskId = tasks[index]['id'];
//     setState(() {
//       tasks.removeAt(index);
//     });
//     try {
//       await _dbHelper.deleteTask(taskId);
//     } catch (e) {
//       print("Error deleting task: $e");
//     }
//   }
//
//   Future<void> _checkConnectivity() async {
//     var connectivityResult = await Connectivity().checkConnectivity();
//     _updateConnectionStatus(connectivityResult);
//   }
//
//   void _updateConnectionStatus(ConnectivityResult result) {
//     setState(() {
//       _isConnected = result != ConnectivityResult.none;
//     });
//   }
//
//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     // Test if location services are enabled.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       setState(() {
//         _currentLocation = "Location services are disabled.";
//       });
//       return;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         setState(() {
//           _currentLocation = "Location permissions are denied";
//         });
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       setState(() {
//         _currentLocation = "Location permissions are permanently denied";
//       });
//       return;
//     }
//
//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//     List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
//     Placemark placemark = placemarks[0];
//
//     setState(() {
//       _currentLocation = "${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}";
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Color(0xFF436878),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => DetailsScreen()),
//           ).then((_) => _loadTasks());
//         },
//         child: Icon(Icons.add, color: Colors.white),
//       ),
//       appBar: AppBar(
//         backgroundColor: Color(0xFF436878),
//         toolbarHeight: 70,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Show Task",
//               style: TextStyle(
//                 fontSize: 23,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             Text(
//               _currentLocation,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {},
//             icon: Column(
//               children: [
//                 Icon(Icons.wifi, color: _isConnected ? Colors.green : Colors.red, size: 30),
//                 Text(
//                   _isConnected ? "Connected" : "Disconnected",
//                   style: TextStyle(fontSize: 15, color: _isConnected ? Colors.green : Colors.red),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: tasks.isEmpty
//           ? Center(
//         child: Text(
//           'No tasks available',
//           style: TextStyle(fontSize: 18, color: Colors.black),
//         ),
//       )
//           : ListView.builder(
//         itemCount: tasks.length,
//         itemBuilder: (context, index) {
//           final task = tasks[index];
//           return Card(
//             margin: EdgeInsets.all(10),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             elevation: 5,
//             child: Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (task['imagePath'] != null)
//                     Container(
//                       height: 200,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(10),
//                         image: DecorationImage(
//                           image: FileImage(File(task['imagePath'])),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                   SizedBox(height: 10),
//                   if (task['title'] != null)
//                     Text(
//                       task['title'],
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   SizedBox(height: 5),
//                   if (task['description'] != null)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           task['description'],
//                           style: TextStyle(fontSize: 16),
//                         ),
//                         SizedBox(height: 10),
//                         Text(
//                           'Location: $_currentLocation',
//                           style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                         ),
//                       ],
//                     ),
//                   SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           Checkbox(
//                             value: task['isComplete'] == 1,
//                             onChanged: (bool? value) {
//                               _updateTaskStatus(index, value!);
//                             },
//                           ),
//                           Text(
//                             task['isComplete'] == 1 ? 'Complete' : 'Incomplete',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: task['isComplete'] == 1 ? Colors.green : Colors.red,
//                             ),
//                           ),
//                         ],
//                       ),
//                       PopupMenuButton<String>(
//                         onSelected: (String value) {
//                           if (value == 'Delete') {
//                             _deleteTask(index);
//                           } else if (value == 'Update') {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => UpdateScreen(
//                                   index: index,
//                                   task: task,
//                                 ),
//                               ),
//                             ).then((_) => _loadTasks());
//                           }
//                         },
//                         itemBuilder: (BuildContext context) {
//                           return {'Delete', 'Update'}.map((String choice) {
//                             return PopupMenuItem<String>(
//                               value: choice,
//                               child: Text(choice),
//                             );
//                           }).toList();
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
