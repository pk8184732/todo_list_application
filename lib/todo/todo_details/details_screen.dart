import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../todo_location/location_screen.dart';
import 'database_helper.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
        });
        print("Image picked: ${_image!.path}");
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  void _saveTask() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_image == null) {
        Fluttertoast.showToast(
          msg: "Please select an image",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final task = {
        'title': titleController.text,
        'description': descriptionController.text,
        'imagePath': _image?.path,
      };

      try {
        int taskId = await DatabaseHelper().insertTask(task);
        print("Task ID: $taskId");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationScreen(
              taskId: taskId,
              title: task['title']!,
              description: task['description']!,
              imagePath: task['imagePath'],
            ),
          ),
        );
      } catch (e) {
        print("Error saving task: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save task')),
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Please fill in all required fields",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF014101A),
      appBar: AppBar(
        title: const Text(
          "Add Task",
          style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w300),
        ),
        backgroundColor: const Color(0xF0231933),
      ),
      body: Form(
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
              onPressed: _saveTask,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.file_present_sharp),
                  SizedBox(width: 8),
                  Text(
                    "Save Task",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
