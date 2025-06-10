import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/news_type_model.dart';

class NewsTypeController {
  final NewsTypeModel model;
  final TextEditingController typeController = TextEditingController();

  NewsTypeController(this.model);

  Future<void> loadTypes(VoidCallback onUpdate) async {
    final snapshot = await FirebaseFirestore.instance.collection('news_types').get();
    model.types = snapshot.docs.map((doc) => {'id': doc.id, 'name': doc['name']}).toList();
    onUpdate();
  }

  Future<void> addType(VoidCallback onUpdate) async {
    final text = typeController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('news_types').add({'name': text});
    typeController.clear();
    await loadTypes(onUpdate);
  }

  Future<void> deleteType(String id, VoidCallback onUpdate) async {
    await FirebaseFirestore.instance.collection('news_types').doc(id).delete();
    await loadTypes(onUpdate);
  }
}
