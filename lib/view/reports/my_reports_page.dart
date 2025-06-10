import 'package:app/services/user_session.dart';
import 'package:app/services/firebase_service.dart';
import 'package:app/view/manager/manager_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final MyReportsController _controller = MyReportsController();

  @override
  void initState() {
    super.initState();
    _controller.init(context, setState);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Reportes')),
        body: const Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reportes')),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_controller.isRepresentante)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _controller.showStatusManager,
                          icon: const Icon(Icons.settings),
                          label: const Text('Administrar'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _controller.hasReports
                      ? StreamBuilder<QuerySnapshot>(
                          stream: _controller.reportsQuery.snapshots(),
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
                                final createdAt = timestamp is Timestamp
                                    ? timestamp.toDate()
                                    : DateTime.now();

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    title: Text(title),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Estado: $status'),
                                        if (_controller.isRepresentante &&
                                            _controller.estados.contains(status))
                                          DropdownButton<String>(
                                            value: status,
                                            onChanged: (newValue) {
                                              if (newValue != null && newValue != status) {
                                                _controller.updateStatus(reportId, newValue);
                                              }
                                            },
                                            items: _controller.estados.map((estado) {
                                              return DropdownMenuItem(
                                                value: estado,
                                                child: Text(estado),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                    trailing: Text(
                                        '${createdAt.day}/${createdAt.month}/${createdAt.year}'),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : const Center(child: Text('No tienes reportes enviados.')),
                ),
              ],
            ),
    );
  }
}

// ------------------- Controller ----------------------

class MyReportsController {
  late BuildContext _context;
  late void Function(VoidCallback) _setState;
  User? user;
  bool isLoading = true;
  bool hasReports = false;
  bool isRepresentante = false;
  List<String> estados = [];
  late Query reportsQuery;

  void init(BuildContext context, void Function(VoidCallback) setState) {
    _context = context;
    _setState = setState;
    user = FirebaseAuth.instance.currentUser;
    isRepresentante = context.read<UserSession>().esRepresentante();
    _initializeReportsQuery();
    _loadStatuses();
  }

  void _initializeReportsQuery() async {
    if (user == null) return;

    try {
      reportsQuery = isRepresentante
          ? FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true)
          : FirebaseFirestore.instance
              .collection('reports')
              .where('userId', isEqualTo: user!.uid)
              .orderBy('createdAt', descending: true);

      final snapshot = await reportsQuery.get();
      _setState(() {
        hasReports = snapshot.docs.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      _setState(() {
        hasReports = false;
        isLoading = false;
      });
    }
  }

  Future<void> updateStatus(String reportId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(_context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a "$newStatus"')),
      );
    } catch (e) {
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el estado')),
      );
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final fetchedStatuses = await FirebaseService.getStatus();
      _setState(() {
        estados = fetchedStatuses;
      });
    } catch (e) {
      _setState(() {
        estados = ['Pendiente', 'En revisión', 'Resuelto'];
      });
    }
  }

  void showStatusManager() {
    showModalBottomSheet(
      context: _context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: StatusManager(
          onRefresh: _loadStatuses,
          isRepresentative: isRepresentante,
        ),
      ),
    );
  }
}
