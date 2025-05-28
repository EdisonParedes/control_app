import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  bool isLoading = true;
  bool hasReports = false;
  late final User? _user;
  late Query _reportsQuery;
  String? _userRole;
  final List<String> estados = ['Pendiente', 'En revisión', 'Resuelto'];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_user == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .get();

      _userRole = userDoc.data()?['role'] ?? 'residente';

      _reportsQuery =
          (_userRole == 'representante')
              ? FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('createdAt', descending: true)
              : FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: _user.uid)
                  .orderBy('createdAt', descending: true);

      final snapshot = await _reportsQuery.get();
      setState(() {
        hasReports = snapshot.docs.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasReports = false;
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String reportId, String newStatus) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {'status': newStatus},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
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
                stream: _reportsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final reports = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final title = report['title'] ?? 'Sin título';
                      final status = report['status'] ?? 'Desconocido';
                      final reportId = report.id;
                      final timestamp = report['createdAt'];
                      final createdAt =
                          timestamp is Timestamp
                              ? timestamp.toDate()
                              : DateTime.now();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estado: $status'),
                              if (_userRole == 'representante')
                                DropdownButton<String>(
                                  value: status,
                                  onChanged: (newValue) {
                                    if (newValue != null &&
                                        newValue != status) {
                                      _updateStatus(reportId, newValue);
                                    }
                                  },
                                  items:
                                      estados.map((estado) {
                                        return DropdownMenuItem(
                                          value: estado,
                                          child: Text(estado),
                                        );
                                      }).toList(),
                                ),
                            ],
                          ),
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
