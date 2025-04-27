import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotification {
  late FirebaseMessaging _firebaseMessaging;

  initNotification() {
    _firebaseMessaging = FirebaseMessaging.instance;

    _firebaseMessaging.requestPermission();
    _firebaseMessaging.getToken().then((token) {
      print('====== FCM TOKEN =====');
      print(token);
    });
  }
}
