import 'package:app/screens/new_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de importar Provider
import 'package:app/services/user_session.dart'; // Asegúrate de importar UserSession

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<void> _cargarDatosFuturo;

  @override
  void initState() {
    super.initState();
    _cargarDatosFuturo = context.read<UserSession>().cargarDatosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _cargarDatosFuturo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(40),
          children: [
            Consumer<UserSession>(
              builder: (context, userSession, child) {
                // Verifica si el usuario tiene el rol necesario
                if (userSession.esAdmin() || userSession.esRepresentante()) {
                  return Positioned(
                    top: 60,
                    right: 20,
                    child: _buildNewNewsButton(context),
                  );
                }
                return const SizedBox(); // No muestra nada si no es autorizado
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Robo en zona centro'),
              subtitle: const Text('Hace 2 horas - Fuente: Policía'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Nueva cámara instalada'),
              subtitle: const Text('Hace 1 día - Municipalidad'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewNewsButton(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed:
            () => {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewNewsScreen()),
              ),
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
