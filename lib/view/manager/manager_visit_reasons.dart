import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../controllers/visit_reason_controller.dart';
import '../../../models/visit_reason_model.dart';

class ManagerVisitReasons extends StatefulWidget {
  final VoidCallback onActualizar;

  const ManagerVisitReasons({super.key, required this.onActualizar});

  @override
  State<ManagerVisitReasons> createState() => _ManagerVisitReasonsState();
}

class _ManagerVisitReasonsState extends State<ManagerVisitReasons> {
  final model = VisitReasonModel();
  late VisitReasonController controller;
  List<QueryDocumentSnapshot> motivos = [];

  @override
  void initState() {
    super.initState();
    controller = VisitReasonController(model);
    _loadMotivos();
  }

  Future<void> _loadMotivos() async {
    motivos = await controller.cargarMotivos();
    setState(() {});
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
          controller: controller.motivoController,
          decoration: InputDecoration(
            labelText: 'Nuevo motivo',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await controller.agregarMotivo(() async {
                  await _loadMotivos();
                  widget.onActualizar();
                });
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: motivos.length,
          itemBuilder: (context, index) {
            final doc = motivos[index];
            return ListTile(
              title: Text(doc['name']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await controller.eliminarMotivo(doc.id, () async {
                    await _loadMotivos();
                    widget.onActualizar();
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
