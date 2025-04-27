import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/auth/login_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPage();
}

class _RegisterPage extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confpasswordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedRol; // Nuevo campo para el dropdown
  
  void setupFCMTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': newToken});
        print('Token actualizado: $newToken');
      }
    });
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Obtener token de FCM
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'nombre': _nameController.text.trim(),
            'apellido': _lastnameController.text.trim(),
            'telefono': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'rol': _selectedRol,
            'fcmToken': fcmToken, // Guardar token
            'createdAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado correctamente")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar: ${e.message}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Registro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                'Nombre',
                _nameController,
                hintText: 'Ingresa tu nombre',
                validator: _validateNotEmpty,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Apellido',
                _lastnameController,
                hintText: 'Ingresa tu apellido',
                validator: _validateNotEmpty,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Teléfono',
                _phoneController,
                hintText: 'Ingresa tu teléfono',
                validator: _validatePhone,
              ),
              const SizedBox(height: 20),
              _buildRolDropdown(),
              const SizedBox(height: 20),
              _buildTextField(
                'Correo Electrónico',
                _emailController,
                hintText: 'Ingresa tu correo',
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Contraseña',
                _passwordController,
                hintText: 'Ingresa una contraseña',
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Confirmar Contraseña',
                _confpasswordController,
                hintText: 'Confirma tu contraseña',
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : _buildRegisterButton(),
              const SizedBox(height: 20),
              _buildRegisterPageRedirect(),
            ],
          ),
        ),
      ),
    );
  }

  // Validadores
  String? _validateNotEmpty(String? value) =>
      value!.isEmpty ? 'Este campo no puede estar vacío' : null;
  String? _validateEmail(String? value) =>
      !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)
          ? 'Correo no válido'
          : null;
  String? _validatePhone(String? value) =>
      !RegExp(r'^09\d{8}$').hasMatch(value!)
          ? 'Número de teléfono no válido'
          : null;
  String? _validatePassword(String? value) =>
      value!.length < 8
          ? 'La contraseña debe tener al menos 8 caracteres'
          : null;
  String? _validateConfirmPassword(String? value) =>
      value != _passwordController.text ? 'Las contraseñas no coinciden' : null;
  String? _validateRolDropdown(String? value) =>
      value == null || value.isEmpty ? 'Selecciona un rol' : null;

  // Widgets reutilizables
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRolDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: _selectedRol,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          hint: const Text('Selecciona tu rol'),
          items: const [
            DropdownMenuItem(value: 'residente', child: Text('Residente')),
            DropdownMenuItem(
              value: 'representante',
              child: Text('Representante'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRol = value;
            });
          },
          validator: _validateRolDropdown,
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Registrarse',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildRegisterPageRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes cuenta? '),
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ),
          child: const Text(
            'Inicia sesión',
            style: TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}
