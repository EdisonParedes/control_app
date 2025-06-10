import 'package:app/services/firebase_service.dart';
import 'package:app/view/news/add_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/controllers/news_controller.dart';
import 'package:app/services/user_session.dart';
import 'package:app/models/news_model.dart';
import 'package:provider/provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<News>> _noticias;
  // ignore: unused_field
  late List<String> _tiposNoticia;
  late NewsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NewsController(
      FirebaseService(),
      context.read<UserSession>(),
    );
    _noticias = _controller.obtenerNoticias();
    _controller.getTiposNoticia().then((tipos) {
      setState(() {
        _tiposNoticia = tipos;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final esRepresentante = context.read<UserSession>().esRepresentante();

    return Scaffold(
      body: Column(
        children: [
          if (esRepresentante)
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: _buildNewNewsButton(context),
            ),
          Expanded(
            child: FutureBuilder<List<News>>(
              future: _noticias,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final noticias = snapshot.data ?? [];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.separated(
                      itemCount: noticias.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final noticia = noticias[index];
                        return ListTile(
                          title: Text(noticia.title),
                          subtitle: Text(
                            '${_formatDate(noticia.date)} - Fuente: ${noticia.source}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          leading: _iconoConColor(noticia.type ?? ''),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final duration = DateTime.now().difference(date);

    if (duration.inMinutes < 60) {
      return 'Hace ${duration.inMinutes} minutos';
    } else if (duration.inHours < 24) {
      return 'Hace ${duration.inHours} horas';
    } else {
      return 'Hace ${duration.inDays} días';
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
