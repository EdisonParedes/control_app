import 'package:cloud_firestore/cloud_firestore.dart';

class VisitReasonService {
  static Future<List<QueryDocumentSnapshot>> obtenerMotivos() async {
    final snapshot = await FirebaseFirestore.instance.collection('reason_visit').get();
    return snapshot.docs;
  }

  static Future<void> agregarMotivo(String motivo) async {
    await FirebaseFirestore.instance.collection('reason_visit').add({'name': motivo});
  }

  static Future<void> eliminarMotivo(String docId) async {
    await FirebaseFirestore.instance.collection('reason_visit').doc(docId).delete();
  }
}
