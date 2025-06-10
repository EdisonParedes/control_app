import 'package:flutter/material.dart';
import '../../../controllers/status_controller.dart';
import '../../../models/status_model.dart';

class StatusManager extends StatefulWidget {
  final VoidCallback onRefresh;
  final bool isRepresentative;

  const StatusManager({
    super.key,
    required this.onRefresh,
    required this.isRepresentative,
  });

  @override
  State<StatusManager> createState() => _StatusManagerState();
}

class _StatusManagerState extends State<StatusManager> {
  final StatusModel model = StatusModel();
  late final StatusController controller;

  @override
  void initState() {
    super.initState();
    controller = StatusController(model);
    controller.loadStatuses(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRepresentative) {
      return const Center(
        child: Text('No tienes permiso para administrar estados.'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Administrar tipos de estado',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller.newStatusController,
          decoration: InputDecoration(
            labelText: 'Nuevo estado',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await controller.addStatus(() => setState(() {}));
                widget.onRefresh();
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: model.statusList.length,
          itemBuilder: (context, index) {
            final status = model.statusList[index];
            final isEditing = model.editingStatusId == status['id'];

            return ListTile(
              title: isEditing
                  ? TextField(
                      controller: controller.editStatusController,
                      decoration: const InputDecoration(labelText: 'Editar estado'),
                    )
                  : Text(status['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await controller.updateStatus(status['id'], () => setState(() {}));
                        widget.onRefresh();
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          controller.setEditingStatus(status['id'], status['name']);
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await controller.deleteStatus(status['id'], () => setState(() {}));
                      widget.onRefresh();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
