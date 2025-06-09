import 'package:app/services/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/services/firebase_service.dart';
import 'package:app/screens/manager_status.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  bool isLoading = true;
  bool hasReports = false;
  late final User? _user;
  late final bool _isRepresentante;
  late Query _reportsQuery;
  List<String> estados = [];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadStatuses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isRepresentante = context.read<UserSession>().esRepresentante();
    _initializeReportsQuery();
  }

  void _initializeReportsQuery() async {
    if (_user == null) return;

    try {
      _reportsQuery =
          _isRepresentante
              ? FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('createdAt', descending: true)
              : FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: _user.uid)
                  .orderBy('createdAt', descending: true);

      final snapshot = await _reportsQuery.get();
      if (mounted) {
        setState(() {
          hasReports = snapshot.docs.isNotEmpty;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasReports = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String reportId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a "$newStatus"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el estado')),
        );
      }
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final fetchedStatuses = await FirebaseService.getStatus();
      if (mounted) {
        setState(() {
          estados = fetchedStatuses;
        });
      }
    } catch (e) {
      print('Error loading statuses: $e');
      if (mounted) {
        setState(() {
          estados = ['Pendiente', 'En revisión', 'Resuelto']; // fallback
        });
      }
    }
  }

  void _showStatusManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: StatusManager(
              onRefresh: _loadStatuses,
              isRepresentative: _isRepresentante,
            ),
          ),
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
              : Column(
                children: [
                  if (_isRepresentante)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: _showStatusManager,
                            icon: const Icon(Icons.settings),
                            label: const Text('Administrar'),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child:
                        hasReports
                            ? StreamBuilder<QuerySnapshot>(
                              stream: _reportsQuery.snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final reports = snapshot.data!.docs;

                                return ListView.builder(
                                  itemCount: reports.length,
                                  itemBuilder: (context, index) {
                                    final report = reports[index];
                                    final title =
                                        report['title'] ?? 'Sin título';
                                    final status =
                                        report['status'] ?? 'Desconocido';
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Estado: $status'),
                                            if (_isRepresentante &&
                                                estados.contains(status))
                                              DropdownButton<String>(
                                                value: status,
                                                onChanged: (newValue) {
                                                  if (newValue != null &&
                                                      newValue != status) {
                                                    _updateStatus(
                                                      reportId,
                                                      newValue,
                                                    );
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
                            : const Center(
                              child: Text('No tienes reportes enviados.'),
                            ),
                  ),
                ],
              ),
    );
  }
}
