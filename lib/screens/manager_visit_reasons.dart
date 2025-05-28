import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManagerVisitReasons extends StatefulWidget {
  final VoidCallback onActualizar;

  const ManagerVisitReasons({super.key, required this.onActualizar});

  @override
  State<ManagerVisitReasons> createState() => _ManagerVisitReasonsState();
}

class _ManagerVisitReasonsState extends State<ManagerVisitReasons> {
  final TextEditingController _nuevoMotivoController = TextEditingController();
  List<QueryDocumentSnapshot> _motivos = [];

  @override
  void initState() {
    super.initState();
    _cargarMotivos();
  }

  Future<void> _cargarMotivos() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('reason_visit').get();
    setState(() {
      _motivos = snapshot.docs;
    });
  }

  Future<void> _agregarMotivo() async {
    final texto = _nuevoMotivoController.text.trim();
    if (texto.isEmpty) return;

    await FirebaseFirestore.instance.collection('reason_visit').add({
      'name': texto,
    });
    _nuevoMotivoController.clear();
    _cargarMotivos();
    widget.onActualizar();
  }

  Future<void> _eliminarMotivo(String docId) async {
    await FirebaseFirestore.instance
        .collection('reason_visit')
        .doc(docId)
        .delete();
    _cargarMotivos();
    widget.onActualizar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Administrar Motivos de Visita',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nuevoMotivoController,
          decoration: InputDecoration(
            labelText: 'Nuevo motivo',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _agregarMotivo,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _motivos.length,
          itemBuilder: (context, index) {
            final doc = _motivos[index];
            return ListTile(
              title: Text(doc['name']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminarMotivo(doc.id),
              ),
            );
          },
        ),
      ],
    );
  }
}
