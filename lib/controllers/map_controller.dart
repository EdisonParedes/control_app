import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreenController {
  final LatLng destination;
  final bool fromNotification;
  final VoidCallback onUpdate;

  final String mapboxAccessToken =
      'pk.eyJ1IjoiZWRpc29uMDkiLCJhIjoiY204bmtoc3U2MDFsaDJscHdybmVpNGN0MiJ9.aQLrHV8J2vAp8at0jCbrQg';

  final Map<String, String> mapStyles = {
    'Calles': 'streets-v12',
    'Satélite': 'satellite-v9',
  };

  late final MapController mapController;
  LatLng? currentPosition;
  late LatLng _destinationPosition;
  String selectedMapStyle = 'satellite-v9';

  MapScreenController({
    required this.destination,
    required this.fromNotification,
    required this.onUpdate,
  }) {
    mapController = MapController();
    _destinationPosition = destination;
  }

  void init() async {
    await _getCurrentLocation();
    onUpdate();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    currentPosition = LatLng(position.latitude, position.longitude);
  }

  void updateMapStyle(String? style) {
    if (style != null) {
      selectedMapStyle = style;
      onUpdate();
    }
  }

  void centerMap() {
    if (currentPosition != null) {
      mapController.move(currentPosition!, 15);
    }
  }

  List<Marker> getMarkers() {
    final List<Marker> markers = [];

    if (currentPosition != null) {
      markers.add(
        Marker(
          point: currentPosition!,
          width: 150,
          height: 50,
          child: Column(
            children: [
              Text(
                'Usted está aquí',
                style: TextStyle(
                  color: selectedMapStyle == 'streets-v12'
                      ? Colors.black
                      : Colors.white,
                  fontSize: 10,
                ),
              ),
              Icon(
                Icons.person_pin_circle,
                color: selectedMapStyle == 'streets-v12'
                    ? Colors.black
                    : Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    if (fromNotification) {
      markers.add(
        Marker(
          point: _destinationPosition,
          width: 150,
          height: 50,
          child: Column(
            children: const [
              Text(
                'Destino',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              Icon(
                Icons.location_on,
                color: Colors.red,
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  bool showPolyline() {
    return fromNotification && currentPosition != null;
  }

  Polyline getPolyline() {
    return Polyline(
      points: [currentPosition!, _destinationPosition],
      strokeWidth: 4,
      color: const Color(0xFF2196F3),
    );
  }
}
