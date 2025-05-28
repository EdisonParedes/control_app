import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<List<String>> obtenerMotivosVisita() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('reason_visit').get();

    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  static Future<List<String>> obtenerRoles() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('roles').get();

    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  static Future<List<String>> obtenerTipoNoticias() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('news_types').get();

    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }
}

