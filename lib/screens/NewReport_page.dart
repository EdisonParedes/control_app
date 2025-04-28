import 'package:app/screens/home_page.dart';
import 'package:app/screens/myReportsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});

  @override
  State<NewReportPage> createState() => _NewReportPageState();
}

class _NewReportPageState extends State<NewReportPage> {
  final TextEditingController _incidentNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  void _submitReport() async {
    final incidentName = _incidentNameController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (incidentName.isEmpty || description.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
        return;
      }

      final now = DateTime.now();
      final reportData = {
        'title': incidentName,
        'description': description,
        'location': location,
        'coordinates': '', // Aquí puedes luego agregar coordenadas reales
        'status': 'pendiente',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'userId': user.uid,
      };

      await FirebaseFirestore.instance.collection('reports').add(reportData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado exitosamente')),
      );

      _incidentNameController.clear();
      _descriptionController.clear();
      _locationController.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NewReportPage()),
      );
    } catch (e) {
      print('Error al enviar el reporte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al enviar el reporte')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text('Noticias'), // El título que quieras
        actionsPadding: EdgeInsets.only(right: 10, top: 10),
        actions: [
          _buildListReportsButton(context), // AQUÍ agregas el botón
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Text(
                  'Nuevo Reporte',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Nombre del Incidente',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _incidentNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Ej. Robo en la vía pública',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Descripción',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Detalles del incidente',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ubicación',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Ej. Calle 123, Ciudad',
                ),
              ),
              const SizedBox(height: 20),
              Align(child: _buildNewReportButton(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewReportButton(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Enviar Reporte',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildListReportsButton(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed:
            () => {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyReportsPage()),
              ),
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Lista de Reportes',
          style: TextStyle(color: Colors.white70,
          fontSize: 12),
        ),
      ),
    );
  }
}
