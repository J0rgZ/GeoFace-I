import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import '../../models/usuario.dart';

class AddEditAdminPage extends StatefulWidget {
  final Usuario? admin; // Si es null, es modo "Crear". Si no, es "Editar".

  const AddEditAdminPage({Key? key, this.admin}) : super(key: key);

  @override
  State<AddEditAdminPage> createState() => _AddEditAdminPageState();
}

class _AddEditAdminPageState extends State<AddEditAdminPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _passwordController;

  bool _isEditMode = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.admin != null;

    _nombreController = TextEditingController(text: _isEditMode ? widget.admin!.nombreUsuario : '');
    _correoController = TextEditingController(text: _isEditMode ? widget.admin!.correo : '');
    _passwordController = TextEditingController(); // Siempre vacío al iniciar
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userController = Provider.of<UserController>(context, listen: false);

    try {
      if (_isEditMode) {
        // --- MODO EDICIÓN ---
        // Creamos una copia del admin con el nuevo nombre
        final updatedAdmin = widget.admin!.copyWith(
          nombreUsuario: _nombreController.text.trim(),
        );
        await userController.updateAdminUser(updatedAdmin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Administrador actualizado con éxito'), backgroundColor: Colors.green),
          );
        }
      } else {
        // --- MODO CREACIÓN ---
        await userController.createAdminUser(
          nombreUsuario: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Administrador creado con éxito'), backgroundColor: Colors.green),
          );
        }
      }
      
      if (mounted) {
        // Devolvemos 'true' para indicar a la página anterior que refresque la lista
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Administrador' : 'Agregar Administrador'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.trim().isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoController,
                readOnly: _isEditMode, // El correo no se puede cambiar después de creado
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  filled: _isEditMode,
                  fillColor: _isEditMode ? Colors.grey.shade200 : null,
                  hintText: _isEditMode ? 'No se puede cambiar' : null,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@') || !value.contains('.')) {
                    return 'Ingrese un correo válido';
                  }
                  return null;
                },
              ),
              if (!_isEditMode) ...[ // Campos de contraseña solo para el modo "Crear"
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: userController.isLoading ? null : _saveForm,
                icon: userController.isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Icon(Icons.save_alt_outlined),
                label: Text(_isEditMode ? 'Guardar Cambios' : 'Crear Administrador'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}