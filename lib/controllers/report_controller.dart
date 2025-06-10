import 'package:app/models/report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> submitReport({
    required String title,
    required String description,
    required String location,
  }) async {
    if (currentUser == null) throw Exception('Usuario no autenticado');

    final report = ReportModel(
      id: '',
      title: title,
      description: description,
      location: location,
      status: 'pendiente',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('reports').add(report.toMap(currentUser!.uid));
  }

  Future<List<ReportModel>> fetchReports({required bool isRepresentative}) async {
    Query query = isRepresentative
        ? _firestore.collection('reports').orderBy('createdAt', descending: true)
        : _firestore.collection('reports')
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('createdAt', descending: true);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ReportModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<QuerySnapshot> getReportsStream({required bool isRepresentative}) {
    Query query = isRepresentative
        ? _firestore.collection('reports').orderBy('createdAt', descending: true)
        : _firestore.collection('reports')
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  Future<void> updateStatus(String reportId, String newStatus) async {
    await _firestore.collection('reports').doc(reportId).update({'status': newStatus});
  }
}
