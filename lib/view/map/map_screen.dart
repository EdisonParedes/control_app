import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../controllers/map_controller.dart'; // Asegúrate de tenerlo

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool fromNotification;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.fromNotification = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapScreenController(
      destination: LatLng(widget.latitude, widget.longitude),
      fromNotification: widget.fromNotification,
      onUpdate: () => setState(() {}),
    );
    _controller.init();
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
            value: _controller.selectedMapStyle,
            dropdownColor: Colors.black,
            onChanged: (value) => _controller.updateMapStyle(value),
            items: _controller.mapStyles.entries.map((entry) {
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
      body: _controller.currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _controller.mapController,
              options: MapOptions(
                initialCenter: _controller.currentPosition!,
                initialZoom: 15,
                minZoom: 5,
                maxZoom: 25,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                  additionalOptions: {
                    'accessToken': _controller.mapboxAccessToken,
                    'id': _controller.selectedMapStyle,
                  },
                ),
                MarkerLayer(
                  markers: _controller.getMarkers(),
                ),
                if (_controller.showPolyline())
                  PolylineLayer(
                    polylines: [_controller.getPolyline()],
                  ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140.0),
        child: FloatingActionButton(
          onPressed: _controller.centerMap,
          tooltip: 'Centrar mapa',
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
