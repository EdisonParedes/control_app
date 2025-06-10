import 'package:app/services/firebase_service.dart';
import 'package:app/services/user_session.dart';
import 'package:app/models/news_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsController {
  // ignore: unused_field
  final FirebaseService _firebaseService;
  // ignore: unused_field
  final UserSession _userSession;

  NewsController(this._firebaseService, this._userSession);

  Future<List<String>> getTiposNoticia() async {
    return await FirebaseService.getNewsTypes();
  }

  Future<void> guardarNoticia(News noticia) async {
    final docRef = FirebaseFirestore.instance.collection('news').doc();
    await docRef.set(noticia.toMap());
  }

  Future<List<News>> obtenerNoticias() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('news')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => News.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
