import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManagerTypeNews extends StatefulWidget {
  final VoidCallback onActualizar;

  const ManagerTypeNews({super.key, required this.onActualizar});

  @override
  State<ManagerTypeNews> createState() => _ManagertypeNewstate();
}

class _ManagertypeNewstate extends State<ManagerTypeNews> {
  final TextEditingController _nuevotypeNewsController = TextEditingController();
  List<QueryDocumentSnapshot> _typeNews = [];

  @override
  void initState() {
    super.initState();
    _cargarTypeNews();
  }

  Future<void> _cargarTypeNews() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('news_types').get();
    setState(() {
      _typeNews = snapshot.docs;
    });
  }

  Future<void> _agregarTipoNews() async {
    final texto = _nuevotypeNewsController.text.trim();
    if (texto.isEmpty) return;

    await FirebaseFirestore.instance.collection('news_types').add({
      'name': texto,
    });
    _nuevotypeNewsController.clear();
    _cargarTypeNews();
    widget.onActualizar();
  }

  Future<void> _eliminartypeNews(String docId) async {
    await FirebaseFirestore.instance
        .collection('news_types')
        .doc(docId)
        .delete();
    _cargarTypeNews();
    widget.onActualizar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Administrar Tipos de Noticias',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nuevotypeNewsController,
          decoration: InputDecoration(
            labelText: 'Nuevo Tipo de Noticias',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _agregarTipoNews,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _typeNews.length,
          itemBuilder: (context, index) {
            final doc = _typeNews[index];
            return ListTile(
              title: Text(doc['name']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminartypeNews(doc.id),
              ),
            );
          },
        ),
      ],
    );
  }
}
