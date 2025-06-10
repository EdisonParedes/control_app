import 'package:app/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:app/models/user_model.dart';
import 'package:app/view/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPage();
}

class _RegisterPage extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confpasswordController = TextEditingController();
  final _ciController = TextEditingController();

  final AuthController _authController = AuthController();
  String? _selectedRol;
  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userModel = UserModel(
        uid: '',
        name: _nameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        rol: _selectedRol!,
        ci: _ciController.text.trim(),
      );

      await _authController.register(userModel, _passwordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado correctamente")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Validaciones
  String? _validateNotEmpty(String? value) =>
      value!.isEmpty ? 'Este campo no puede estar vacío' : null;
  String? _validateEmail(String? value) =>
      !RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)
          ? 'Correo no válido'
          : null;
  String? _validatePhone(String? value) =>
      !RegExp(r'^09\d{8}$').hasMatch(value!) ? 'Número de teléfono no válido' : null;
  String? _validatePassword(String? value) =>
      value!.length < 8 ? 'La contraseña debe tener al menos 8 caracteres' : null;
  String? _validateConfirmPassword(String? value) =>
      value != _passwordController.text ? 'Las contraseñas no coinciden' : null;
  String? _validateRolDropdown(String? value) =>
      value == null || value.isEmpty ? 'Selecciona un rol' : null;

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
            DropdownMenuItem(value: 'representante', child: Text('Representante')),
          ],
          onChanged: (value) => setState(() => _selectedRol = value),
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
        child: const Text('Registrar', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Registro',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 30),
              _buildTextField('Nombre', _nameController, hintText: 'Ingresa tu nombre', validator: _validateNotEmpty),
              const SizedBox(height: 20),
              _buildTextField('Apellido', _lastnameController, hintText: 'Ingresa tu apellido', validator: _validateNotEmpty),
              const SizedBox(height: 20),
              _buildTextField('Cédula', _ciController, hintText: 'Ingresa su Cédula', validator: _validateNotEmpty),
              const SizedBox(height: 20),
              _buildTextField('Teléfono', _phoneController, hintText: 'Ingresa tu teléfono', validator: _validatePhone),
              const SizedBox(height: 20),
              _buildRolDropdown(),
              const SizedBox(height: 20),
              _buildTextField('Correo Electrónico', _emailController, hintText: 'Ingresa tu correo', validator: _validateEmail),
              const SizedBox(height: 20),
              _buildTextField('Contraseña', _passwordController, hintText: 'Ingresa una contraseña', obscureText: true, validator: _validatePassword),
              const SizedBox(height: 20),
              _buildTextField('Confirmar Contraseña', _confpasswordController, hintText: 'Confirma tu contraseña', obscureText: true, validator: _validateConfirmPassword),
              const SizedBox(height: 30),
              _isLoading ? const CircularProgressIndicator() : _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }
}
