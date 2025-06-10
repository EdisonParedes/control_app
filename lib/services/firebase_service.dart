import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  /// Fetches all visit reasons from Firestore.
  static Future<List<String>> getVisitReasons() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('reason_visit').get();

      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching visit reasons: $e');
      return [];
    }
  }

  /// Fetches all roles from Firestore.
  static Future<List<String>> getRoles() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('roles').get();

      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching roles: $e');
      return [];
    }
  }

  /// Fetches all news types from Firestore.
  static Future<List<String>> getNewsTypes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('news_types').get();

      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching news types: $e');
      return [];
    }
  }

  /// Fetches all news types from Firestore.
  static Future<List<String>> getStatus() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('status').get();

    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }
  
}
