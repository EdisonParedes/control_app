import 'package:app/view/auth/login_page.dart';
import 'package:app/view/qr/generate_QR_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _rolController = TextEditingController();
  final TextEditingController _ciController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          _nameController.text = data['name'] ?? '';
          _lastnameController.text = data['lastname'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _rolController.text = data['rol'] ?? '';
          _ciController.text = data['ci'] ?? '';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar los datos: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, bool> _showFields = {
    'Nombre': false,
    'Apellido': false,
    'Email': false,
    'Teléfono': false,
    'Rol': false,
    'CI': false,
  };

  Map<String, bool> _editFields = {
    'Nombre': false,
    'Apellido': false,
    'Teléfono': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Icon(Icons.person, size: 80),
                    Center(child: _buildGenerateQRButton(context)),
                    const SizedBox(height: 20),
                    _buildTextField('Nombre', _nameController),
                    const SizedBox(height: 20),
                    _buildTextField('Apellido', _lastnameController),
                    const SizedBox(height: 20),
                    _buildTextField('CI', _ciController),
                    const SizedBox(height: 10),
                    _buildTextField('Email', _emailController),
                    const SizedBox(height: 20),
                    _buildTextField('Teléfono', _phoneController),
                    const SizedBox(height: 20),
                    _buildTextField('Rol', _rolController),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        children: [
                          _buildSaveButton(),
                          const SizedBox(height: 10),
                          _buildLogOutButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    bool isEditable = _editFields.containsKey(label);
    bool isEditing = _editFields[label] ?? false;
    bool isVisible = _showFields[label] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller:
              isVisible || isEditing
                  ? controller
                  : TextEditingController(
                    text: maskSensitiveData(label, controller.text),
                  ),
          readOnly: !(isEditing),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditable)
                  IconButton(
                    icon: Icon(
                      isEditing ? Icons.cancel : Icons.edit,
                      color: Colors.black45,
                    ),
                    onPressed: () {
                      setState(() {
                        _editFields[label] = !isEditing;
                        if (!isEditing) {
                          _showFields[label] = true; // mostrar al editar
                        }
                      });
                    },
                  ),
                IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black45,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFields[label] = !isVisible;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogOutButton(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildGenerateQRButton(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => GenerateQRScreen(
                    name: _nameController.text.trim(),
                    lastname: _lastnameController.text.trim(),
                    id: _ciController.text.trim(),
                    type: _rolController.text.trim(),
                    phone: _phoneController.text.trim(),
                  ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Generar QR', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                    'name': _nameController.text.trim(),
                    'lastname': _lastnameController.text.trim(),
                    'phone': _phoneController.text.trim(),
                  });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos actualizados correctamente'),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al actualizar: $e')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Guardar',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  String maskSensitiveData(String label, String value) {
    if (label == 'Teléfono' && value.length >= 4) {
      return value.replaceRange(2, value.length - 2, '*' * (value.length - 4));
    } else if (label == 'Email' && value.contains('@')) {
      var parts = value.split('@');
      var username = parts[0];
      var domain = parts[1];
      if (username.length > 2) {
        return '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}@$domain';
      }
    } else if ((label == 'Nombre' || label == 'Apellido') && value.isNotEmpty) {
      if (value.length > 2) {
        return value[0] + '*' * (value.length - 2) + value[value.length - 1];
      }
    } else if (label == 'Rol' && value.isNotEmpty) {
      return value[0] + '*' * (value.length - 2) + value[value.length - 1];
    } else if (label == 'CI' && value.isNotEmpty) {
      return value.replaceRange(2, value.length - 2, '*' * (value.length - 4));
    }
    return value;
  }
}
