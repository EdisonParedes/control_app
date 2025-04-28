import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        Positioned(top: 60, right: 20, child: _buildNewNewsButton(context)),
        const SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.warning, color: Colors.red),
          title: Text('Robo en zona centro'),
          subtitle: Text('Hace 2 horas - Fuente: Policía'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.info, color: Colors.blue),
          title: Text('Nueva cámara instalada'),
          subtitle: Text('Hace 1 día - Municipalidad'),
        ),
      ],
    );
  }

  Widget _buildNewNewsButton(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed:
            () => {
              /* Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewReportPage()),
              ), */
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Agregar Noticia',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
