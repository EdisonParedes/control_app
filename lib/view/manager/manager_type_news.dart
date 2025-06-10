import 'package:flutter/material.dart';
import '../../../controllers/news_type_controller.dart';
import '../../../models/news_type_model.dart';

class ManagerTypeNews extends StatefulWidget {
  final VoidCallback onActualizar;

  const ManagerTypeNews({super.key, required this.onActualizar});

  @override
  State<ManagerTypeNews> createState() => _ManagerTypeNewsState();
}

class _ManagerTypeNewsState extends State<ManagerTypeNews> {
  final NewsTypeModel model = NewsTypeModel();
  late final NewsTypeController controller;

  @override
  void initState() {
    super.initState();
    controller = NewsTypeController(model);
    controller.loadTypes(() => setState(() {}));
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
          controller: controller.typeController,
          decoration: InputDecoration(
            labelText: 'Nuevo Tipo de Noticias',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await controller.addType(() => setState(() {}));
                widget.onActualizar();
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: model.types.length,
          itemBuilder: (context, index) {
            final type = model.types[index];
            return ListTile(
              title: Text(type['name']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await controller.deleteType(type['id'], () => setState(() {}));
                  widget.onActualizar();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
