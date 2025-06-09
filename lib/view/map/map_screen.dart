import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool fromNotification; // Nueva variable para diferenciar

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.fromNotification = false, // Si no se pasa, será falso
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final String _mapboxAccessToken =
      "pk.eyJ1IjoiZWRpc29uMDkiLCJhIjoiY204bmtoc3U2MDFsaDJscHdybmVpNGN0MiJ9.aQLrHV8J2vAp8at0jCbrQg";
  final Map<String, String> _mapStyles = {
    'Calles': 'streets-v12',
    'Satélite': 'satellite-v9',
  };

  String _selectedMapStyle = 'satellite-v9';
  late MapController _mapController;

  LatLng? _currentPosition;
  late LatLng _destinationPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _destinationPosition = LatLng(widget.latitude, widget.longitude);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _centerMap() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Seguridad'),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          DropdownButton<String>(
            value: _selectedMapStyle,
            dropdownColor: Colors.black,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMapStyle = value);
              }
            },
            items:
                _mapStyles.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
      body:
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 15,
                  minZoom: 5,
                  maxZoom: 25,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                    additionalOptions: {
                      'accessToken': _mapboxAccessToken,
                      'id': _selectedMapStyle,
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 150,
                        height: 50,
                        child: Column(
                          children: [
                            Text(
                              'Usted está aquí',
                              style: TextStyle(
                                color:
                                    _selectedMapStyle == 'streets-v12'
                                        ? Colors.black
                                        : Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Icon(
                              Icons.person_pin_circle,
                              color:
                                  _selectedMapStyle == 'streets-v12'
                                      ? Colors.black
                                      : Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      // Mostrar el marcador de destino solo si se abre desde la notificación
                      if (widget.fromNotification)
                        Marker(
                          point: _destinationPosition,
                          width: 150,
                          height: 50,
                          child: Column(
                            children: const [
                              Text(
                                'Destino',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Solo mostrar la ruta si se abre desde la notificación
                  if (widget.fromNotification && _currentPosition != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [_currentPosition!, _destinationPosition],
                          strokeWidth: 4,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                ],
              ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: _centerMap,
          tooltip: 'Centrar mapa',
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
