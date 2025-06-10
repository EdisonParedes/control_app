import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/status_model.dart';

class StatusController {
  final StatusModel model;
  final TextEditingController newStatusController = TextEditingController();
  final TextEditingController editStatusController = TextEditingController();

  StatusController(this.model);

  Future<void> loadStatuses(VoidCallback onUpdate) async {
    final snapshot = await FirebaseFirestore.instance.collection('status').get();
    model.statusList = snapshot.docs.map((doc) => {'id': doc.id, 'name': doc['name']}).toList();
    onUpdate();
  }

  Future<void> addStatus(VoidCallback onUpdate) async {
    final text = newStatusController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('status').add({'name': text});
    newStatusController.clear();
    await loadStatuses(onUpdate);
  }

  Future<void> deleteStatus(String id, VoidCallback onUpdate) async {
    await FirebaseFirestore.instance.collection('status').doc(id).delete();
    await loadStatuses(onUpdate);
  }

  Future<void> updateStatus(String id, VoidCallback onUpdate) async {
    final newName = editStatusController.text.trim();
    if (newName.isEmpty) return;

    await FirebaseFirestore.instance.collection('status').doc(id).update({'name': newName});
    model.editingStatusId = null;
    editStatusController.clear();
    await loadStatuses(onUpdate);
  }

  void setEditingStatus(String id, String name) {
    model.editingStatusId = id;
    editStatusController.text = name;
  }
}
