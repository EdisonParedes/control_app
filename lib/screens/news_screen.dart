import 'package:app/screens/new_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/services/user_session.dart';

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

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _cargarDatosFuturo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            if (context.read<UserSession>().esAdmin() ||
                context.read<UserSession>().esRepresentante())
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: _buildNewNewsButton(context),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('news')
                        .orderBy('date', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No hay noticias disponibles.'),
                    );
                  }

                  final noticias = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: noticias.length,
                    itemBuilder: (context, index) {
                      final noticia =
                          noticias[index].data() as Map<String, dynamic>;
                      final title = noticia['title'] ?? '';
                      //final description = noticia['description'] ?? '';
                      final source = noticia['source'] ?? '';
                      final date = _parseDate(noticia['date']);

                      return ListTile(
                        leading: _iconoConColor(noticia['type'] ?? ''),
                        title: Text(title),
                        subtitle: Text(
                          '${_formatDate(date)} - Fuente: $source',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    final duration = DateTime.now().difference(date);

    if (duration.inMinutes < 60) {
      return 'Hace ${duration.inMinutes} minutos';
    } else if (duration.inHours < 24) {
      return 'Hace ${duration.inHours} horas';
    } else {
      return 'Hace ${duration.inDays} días';
    }
  }

  Widget _buildNewNewsButton(BuildContext context) {
    return SizedBox(
      width: 180,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewNewsScreen()),
          );
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

Icon _iconoConColor(String tipo) {
  switch (tipo) {
    case 'Emergencia':
      return Icon(Icons.warning, color: Colors.red);
    case 'Seguridad':
      return Icon(Icons.security, color: Colors.blue);
    case 'Evento':
      return Icon(Icons.event, color: Colors.green);
    case 'Comunidad':
      return Icon(Icons.people, color: Colors.orange);
    default:
      return Icon(Icons.article, color: Colors.grey);
  }
}
