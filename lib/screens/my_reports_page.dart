import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  bool isLoading = true; // Controlar el estado de carga
  bool hasReports = false; // Variable para verificar si hay reportes

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    // Cargar los reportes del usuario
    final snapshot =
        await FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

    // Si hay datos, cambiar el estado
    setState(() {
      hasReports = snapshot.docs.isNotEmpty;
      isLoading = false; // Detener el cargador
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Reportes')),
        body: const Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reportes')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasReports
              ? StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('reports')
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No tienes reportes enviados.'),
                    );
                  }

                  final reports = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final title = report['title'] ?? 'Sin título';
                      final status = report['status'] ?? 'Desconocido';
                      final createdAt = DateTime.parse(report['createdAt']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text('Estado: $status'),
                          trailing: Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          ),
                        ),
                      );
                    },
                  );
                },
              )
              : const Center(child: Text('No tienes reportes enviados.')),
    );
  }
}
