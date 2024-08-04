import 'dart:io';

class Task {
  final String title;
  final String description;
  final File? image;

  Task({
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

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      description: map['description'],
      image: map['imagePath'] != null ? File(map['imagePath']) : null,
    );
  }
}
