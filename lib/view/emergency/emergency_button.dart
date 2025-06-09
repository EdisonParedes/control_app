import 'dart:convert';
import 'dart:async';
import 'package:app/view/entry_exit/visitor_approval_screen.dart';
import 'package:app/services/serverkey.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/services/location_permission_service.dart';
import 'package:app/view/map/map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/services/user_session.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class EmergencyButton extends StatefulWidget {
  @override
  _EmergencyButtonState createState() => _EmergencyButtonState();

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationHandler,
    );
  }
}

class _EmergencyButtonState extends State<EmergencyButton> {
  bool isSending = false;
  bool isCompleted = false;
  LatLng currentPosition = LatLng(0.0, 0.0);
  double latitude = 0;
  double longitude = 0;
  final get = get_server_key();
  Timer? holdTimer;
  DateTime? pressStartTime;

  @override
  void initState() {
    super.initState();

    context.read<UserSession>().cargarDatosUsuario();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      
      // Evitar mostrar la notificación si el usuario es quien la envió
      String senderId = data['senderId'] ?? '';
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (senderId == currentUserId) return;

      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        double latitude = double.tryParse(data['latitude'] ?? '0') ?? 0;
        double longitude = double.tryParse(data['longitude'] ?? '0') ?? 0;

        if (latitude != 0 && longitude != 0) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder:
                  (_) => MapScreen(latitude: latitude, longitude: longitude, fromNotification: true,),
            ),
          );
        }
      } else if (data.containsKey('visitorName') &&
          data.containsKey('visitorCi') &&
          data.containsKey('reason') &&
          data.containsKey('requestId')) {
        String visitorName = data['visitorName'];
        String visitorCi = data['visitorCi'];
        String reason = data['reason'];
        String requestId = data['requestId'];

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder:
                (_) => VisitorApprovalScreen(
                  visitorName: visitorName,
                  visitorCi: visitorCi,
                  reason: reason,
                  requestId: requestId,
                ),
          ),
        );
      } else {
        // Notificación genérica
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.notification?.body ?? 'Notificación recibida',
            ),
          ),
        );
      }
    });
  }

  Future<void> _sendEmergencyNotifications() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final message = 'Emergencia activada en la comunidad Llimpe Grande.';
    String serverKey = await get.server_token();

    Position? position;
    try {
      position = await LocationPermissionService.requestLocationPermission();
    } catch (e) {
      print('Error al obtener ubicación: $e');
    }

    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;
    }

    User? user = FirebaseAuth.instance.currentUser;
    String userName = 'Usuario';
    String userId = user!.uid;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      userName = '${data['nombre'] ?? 'Usuario'} ${data['apellido'] ?? ''}';
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final token = data['fcmToken'];
      if (token != null && token.toString().isNotEmpty) {
        await sendPushMessage(
          token,
          '$message - $userName',
          latitude,
          longitude,
          serverKey,
          userId,
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notificaciones de emergencia enviadas')),
      );
    }
  }

  Future<void> sendPushMessage(
    String token,
    String message,
    double latitude,
    double longitude,
    String serverKey,
    String user,
  ) async {
    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/apps-d19d9/messages:send',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode({
        'message': {
          'token': token,
          'notification': {'title': '¡Alerta de Emergencia!', 'body': message},
          'data': {
            "latitude": latitude.toString(),
            "longitude": longitude.toString(),
            "story_id": "story_12345",
            "senderId": user,
          },
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Notificación enviada correctamente');
    } else {
      print('Error al enviar notificación: ${response.body}');
    }
  }

  void _startHoldTimer() {
    setState(() {
      isSending = true;
      isCompleted = false;
    });

    holdTimer = Timer(Duration(seconds: 10), () async {
      await _sendEmergencyNotifications();

      if (mounted) {
        setState(() {
          isSending = false;
          isCompleted = true;
        });

        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            setState(() => isCompleted = false);
          }
        });
      }
    });
  }

  void _cancelHoldTimer() {
    if (holdTimer != null && holdTimer!.isActive) {
      holdTimer!.cancel();
      print('Botón soltado antes de los 10 segundos. Emergencia cancelada.');
    }

    setState(() {
      isSending = false;
      isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHoldTimer(),
      onLongPressEnd: (_) => _cancelHoldTimer(),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color:
              isCompleted
                  ? Colors.green
                  : (isSending ? Colors.orange : Colors.red),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Center(
          child:
              isSending
                  ? SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                  : Icon(
                    isCompleted ? Icons.check : Icons.warning,
                    color: Colors.white,
                    size: 40,
                  ),
        ),
      ),
    );
  }
}

// Manejo de notificación en segundo plano
Future<void> backgroundNotificationHandler(
  NotificationResponse notificationResponse,
) async {
  print('Notificación de fondo: ${notificationResponse.payload}');
}
