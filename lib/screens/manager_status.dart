import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _newStatusController = TextEditingController();
  List<QueryDocumentSnapshot> _statusList = [];
  String? _editingStatusId;
  final TextEditingController _editStatusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('status').get();
    setState(() {
      _statusList = snapshot.docs;
    });
  }

  Future<void> _addStatus() async {
    final text = _newStatusController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('status').add({'name': text});

    _newStatusController.clear();
    await _loadStatuses();
    widget.onRefresh();
  }

  Future<void> _deleteStatus(String docId) async {
    await FirebaseFirestore.instance.collection('status').doc(docId).delete();
    await _loadStatuses();
    widget.onRefresh();
  }

  Future<void> _updateStatus(String docId, String newName) async {
    if (newName.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('status').doc(docId).update({
      'name': newName.trim(),
    });

    _editingStatusId = null;
    _editStatusController.clear();
    await _loadStatuses();
    widget.onRefresh();
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
          controller: _newStatusController,
          decoration: InputDecoration(
            labelText: 'Nuevo estado',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addStatus,
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _statusList.length,
          itemBuilder: (context, index) {
            final doc = _statusList[index];
            final currentId = doc.id;
            final currentName = doc['name'];

            final isEditing = _editingStatusId == currentId;

            return ListTile(
              title:
                  isEditing
                      ? TextField(
                        controller: _editStatusController..text = currentName,
                        decoration: const InputDecoration(
                          labelText: 'Editar estado',
                        ),
                      )
                      : Text(currentName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed:
                          () => _updateStatus(
                            currentId,
                            _editStatusController.text,
                          ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          _editingStatusId = currentId;
                          _editStatusController.text = currentName;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteStatus(currentId),
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
