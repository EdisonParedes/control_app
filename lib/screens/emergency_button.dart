import 'dart:convert';
import 'package:app/services/serverkey.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart'; // Paquete para obtener la ubicación
import 'package:app/services/location_permission_service.dart'; // Importa el servicio de permisos
import 'package:app/screens/map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final msgServer = FirebaseMessaging.instance;
  LatLng currentPosition = LatLng(0.0, 0.0);
  bool isLongPressing = false; 
  Future<void>? _progressFuture;
  double progress = 0.0;

  double latitude = 0;
  double longitude = 0;

  final get = get_server_key();  // Server Key de Firebase

  @override
  void initState() {
    super.initState();

    // Configura la recepción de mensajes cuando la app esté en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación recibida en primer plano: ${message.notification?.title}');
      // Muestra la notificación local cuando la app está en primer plano
      _showNotification(
        message.notification?.title ?? 'Alerta',
        message.notification?.body ?? 'Mensaje de emergencia',
      );
    });
  }

  Future<void> _sendEmergencyNotifications() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final message = 'Emergencia activada en la comunidad Llimpe Grande.';
    String serverKey = await get.server_token();

    // Intentar obtener la ubicación, pero no bloquear si no se obtiene
    Position? position;
    try {
      position = await LocationPermissionService.requestLocationPermission();
    } catch (e) {
      print('Error al obtener ubicación: $e');
    }

    // Si no se obtuvo la ubicación, usar valores predeterminados
    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;
    } else {
      latitude = 0.0;
      longitude = 0.0;
    }

    String locationMessage = '$message';

    // Obtener el nombre del usuario actual (supongo que el usuario está autenticado)
    User? user = FirebaseAuth.instance.currentUser;
    String userName = user?.displayName ?? 'Usuario';

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final token = data.containsKey('fcmToken') ? data['fcmToken'] : null;

      if (token != null && token.toString().isNotEmpty) {
        // Enviar la notificación con el nombre del usuario
        await sendPushMessage(
          token,
          '$message - $userName',
          latitude,
          longitude,
          serverKey,
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notificaciones de emergencia enviadas')),
    );
  }

  // Función para mostrar la notificación local
  Future<void> _showNotification(String title, String body) async {
    String userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Usuario'; // Obtener nombre del usuario

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'emergency_channel',
          'Emergency Notifications',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Mostrar la notificación local con el nombre del usuario
    await EmergencyButton.flutterLocalNotificationsPlugin.show(
      0,
      '$title - $userName', // Incluye el nombre del usuario en el título
      body,
      platformDetails,
    );
  }

  Future<void> sendPushMessage(
    String token,
    String message,
    double latitude,
    double longitude,
    String serverKey,
  ) async {
    print('-------- FCM TOKEN ------ $token');
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

  // Función de long press para enviar la notificación de emergencia después de 10 segundos
  void _handleLongPress() {
    if (!isSending) {
      setState(() => isSending = true);
      Future.delayed(Duration(seconds: 10), () async {
        await _sendEmergencyNotifications();
        setState(() => isSending = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _handleLongPress,
      child: FloatingActionButton(
        backgroundColor: Colors.red,
        child: Icon(Icons.warning),
        onPressed: () {},
      ),
    );
  }
}

// Función estática o de nivel superior para manejar la notificación cuando la app esté en segundo plano o cerrada
Future<void> backgroundNotificationHandler(
  NotificationResponse notificationResponse,
) async {
  print('Notificación de fondo: ${notificationResponse.payload}');
  // Aquí puedes manejar la notificación de fondo
}
