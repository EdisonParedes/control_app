import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/visit_reason_model.dart';
import '../services/visit_reason_service.dart';

class VisitReasonController {
  final VisitReasonModel model;
  final TextEditingController motivoController = TextEditingController();

  VisitReasonController(this.model);

  Future<List<QueryDocumentSnapshot>> cargarMotivos() async {
    return await VisitReasonService.obtenerMotivos();
  }

  Future<void> agregarMotivo(VoidCallback onSuccess) async {
    final texto = motivoController.text.trim();
    if (texto.isEmpty) return;
    await VisitReasonService.agregarMotivo(texto);
    motivoController.clear();
    onSuccess();
  }

  Future<void> eliminarMotivo(String docId, VoidCallback onSuccess) async {
    await VisitReasonService.eliminarMotivo(docId);
    onSuccess();
  }
}
