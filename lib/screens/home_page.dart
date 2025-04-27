import 'package:app/screens/map_screen.dart';
import 'package:app/screens/news_screen.dart';
import 'package:app/screens/reports_screen.dart';
import 'package:app/screens/entryExitScreen.dart';
import 'package:app/screens/NewReport_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'emergency_button.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;
  double? latitude = -1.3605118;
  double? longitude = -78.5879038;

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _getCurrentLocation(); // Llamamos a esta función para obtener la ubicación.
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      setState(() {
        _userRole = doc.data()?['rol'] ?? 'invitado';
        _isLoading = false;
      });
    }
  }

  // Función para obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          latitude = -1.3605118;
          longitude = -78.5879038;
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      debugPrint("Error al obtener la ubicación: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Validamos si la latitud y longitud están disponibles, y si no, mostramos un cargador.
    if (_isLoading || latitude == null || longitude == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filtrar items según rol
    List<BottomNavigationBarItem> navigationItems = [];
    List<Widget> screenWidgets = [];

    if (_userRole == 'residente') {
      navigationItems.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.report),
          label: 'Reportes',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.newspaper),
          label: 'Noticias',
        ),
      ]);
      screenWidgets.addAll([
        NewReportPage(),
        MapScreen(
          latitude: latitude!,
          longitude: longitude!,
        ), // Pasamos las coordenadas a MapScreen
        const NewsScreen(),
      ]);
    }

    if (_userRole == 'admin' || _userRole == 'representante') {
      navigationItems.addAll([
        const BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg),
          label: 'Ing/Sal',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.report),
          label: 'Reportes',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.newspaper),
          label: 'Noticias',
        ),
      ]);
      screenWidgets.addAll([
        EntryExitScreen(),
        NewReportPage(),
        MapScreen(
          latitude: latitude!,
          longitude: longitude!,
        ), // Pasamos las coordenadas a MapScreen
        const NewsScreen(),
      ]);
    }
    // Siempre debe estar disponible el perfil
    navigationItems.add(
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
    );
    screenWidgets.add(const ProfileScreen());

    return Scaffold(
      body: screenWidgets[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: navigationItems,
      ),
      floatingActionButton: EmergencyButton(),
    );
  }
}
