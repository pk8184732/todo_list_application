import 'dart:io';

class ToDoModel {
  final String title;
  final String description;
  final File? image;

  ToDoModel({
    required this.title,
    required this.description,
    this.image,
  });


  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imagePath': image?.path,
    };
  }

  factory ToDoModel.fromMap(Map<String, dynamic> map) {
    return ToDoModel(
      title: map['title'],
      description: map['description'],
      image: map['imagePath'] != null ? File(map['imagePath']) : null,
    );
  }
}
