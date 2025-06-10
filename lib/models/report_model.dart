import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String status;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ReportModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap(String userId) {
    return {
      'title': title,
      'description': description,
      'location': location,
      'status': 'pendiente',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'userId': userId,
    };
  }
}
