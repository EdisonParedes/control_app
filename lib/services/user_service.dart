import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/model/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUserByUID(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id; // Asegura que uid esté incluido

      return UserModel.fromMap(data);
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }
}
