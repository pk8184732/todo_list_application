import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database_helper.dart'; // Ensure correct path

class UpdateScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const UpdateScreen({Key? key, required this.task}) : super(key: key);

  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.task['title'];
    descriptionController.text = widget.task['description'];
    if (widget.task['imagePath'] != null) {
      _image = File(widget.task['imagePath']);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _updateTask() async {
    setState(() {
      _isLoading = true;
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
     CircularProgressIndicator();
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final updatedTask = {
      'id': widget.task['id'],
      'title': titleController.text,
      'description': descriptionController.text,
      'imagePath': _image?.path ?? widget.task['imagePath'],
      'isComplete': widget.task['isComplete'],
    };

    try {
      final rowsAffected = await DatabaseHelper().updateTask(updatedTask);
      if (rowsAffected > 0) {
        Fluttertoast.showToast(
          msg: "Task updated successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Navigator.pop(
          context,
          '/wifi_screen', // Adjust if the route name is different
        );
      }
    } catch (e) {
      print("Error updating task: $e");
      CircularProgressIndicator();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF014101A),
      appBar: AppBar(
        title: const Text(
          "Update Task",
          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w300),
        ),
        backgroundColor: const Color(0xF0231933),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(18.0),
              children: [
                const SizedBox(height: 120),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xF054219B),
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(height: 50),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Enter Title",
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xF02E2738)),
                    ),
                    fillColor: const Color(0xF039353F),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Enter Description",
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xF02E2738)),
                    ),
                    fillColor: const Color(0xF039353F),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 55.0, horizontal: 12.0),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(const Color(0xF02E2738)),
                  ),
                  onPressed: _updateTask, // Call the _updateTask method
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.file_present_sharp),
                      SizedBox(width: 8),
                      Text(
                        "Update Task",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
