import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  // Constructor para recibir las coordenadas
  MapScreen({required this.latitude, required this.longitude});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final double? latitude = 0;
  final double? longitude = 0;
  final String mapboxAccessToken =
      "pk.eyJ1IjoiZWRpc29uMDkiLCJhIjoiY204bmtoc3U2MDFsaDJscHdybmVpNGN0MiJ9.aQLrHV8J2vAp8at0jCbrQg"; // Reemplaza con tu clave de Mapbox

  late LatLng
  currentPosition; // Usamos 'late' porque las coordenadas se pasan en el constructor

  final MapController _mapController = MapController();
  String selectedMapStyle = 'satellite-v9'; // Estilo de mapa por defecto

  final Map<String, String> mapStyles = {
    'Calles': 'streets-v12',
    'Satélite': 'satellite-v9',
  };

  @override
  void initState() {
    super.initState();
    // Usamos las coordenadas pasadas al constructor
    currentPosition = LatLng(widget.latitude, widget.longitude);
  }

  void _centerMap() {
    _mapController.move(currentPosition, 15);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Mapa de Seguridad',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          DropdownButton<String>(
            value: selectedMapStyle,
            dropdownColor: Colors.black,
            onChanged: (String? newValue) {
              setState(() {
                selectedMapStyle = newValue!;
              });
            },
            items:
                mapStyles.entries
                    .map<DropdownMenuItem<String>>(
                      (entry) => DropdownMenuItem(
                        value: entry.value,
                        child: Text(
                          entry.key,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
      body:
          currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: currentPosition,
                  minZoom: 5,
                  maxZoom: 25,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                    additionalOptions: {
                      'accessToken': mapboxAccessToken,
                      'id': selectedMapStyle,
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentPosition,
                        width: 150,
                        height: 50,
                        child: Column(
                          children: [
                            Text(
                              'Usted está aquí',
                              style: TextStyle(
                                color:
                                    selectedMapStyle == 'streets-v12'
                                        ? Colors.black
                                        : Colors
                                            .white, // Cambiar el color según el mapa
                                fontSize: 10,
                              ),
                            ),
                            Icon(
                              Icons.person_3,
                              color:
                                  selectedMapStyle == 'streets-v12'
                                      ? Colors.black
                                      : Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: _centerMap,
              child: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
    );
  }
}
