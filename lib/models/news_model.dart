import 'package:cloud_firestore/cloud_firestore.dart';

class News {
  final String id;
  final String title;
  final String description;
  final String source;
  final String? type;
  final DateTime date;
  final String userId;

  News({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    this.type,
    required this.date,
    required this.userId,
  });

  factory News.fromFirestore(Map<String, dynamic> data, String id) {
    return News(
      id: id,
      title: data['title'],
      description: data['description'],
      source: data['source'],
      type: data['type'],
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'source': source,
      'type': type,
      'date': FieldValue.serverTimestamp(),
      'userId': userId,
    };
  }
}
