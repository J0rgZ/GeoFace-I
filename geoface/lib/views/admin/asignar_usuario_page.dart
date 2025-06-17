// FILE: lib/views/admin/asignar_usuario_page.dart

import 'package:flutter/material.dart';

class AsignarUsuarioPage extends StatefulWidget {
  const AsignarUsuarioPage({Key? key}) : super(key: key);

  @override
  State<AsignarUsuarioPage> createState() => _AsignarUsuarioPageState();
}

class _AsignarUsuarioPageState extends State<AsignarUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Estos serían los datos que obtendrías de tu backend/controlador
  // --- DATOS DE EJEMPLO ---
  final List<String> _empleadosSinUsuario = ['Juan Perez', 'Maria Rodriguez', 'Carlos Gomez'];
  final List<String> _usuariosNoAsignados = ['jperez', 'mrodriguez', 'cgomez_user'];
  // --------------------------

  String? _empleadoSeleccionado;
  String? _usuarioSeleccionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Aquí llamarías a tus controladores para cargar la lista de empleados y usuarios.
    // ej: Provider.of<EmpleadoController>(context, listen: false).fetchEmpleadosSinUsuario();
  }

  Future<void> _asignarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // --- LÓGICA DE NEGOCIO ---
      // Aquí llamarías a tu controlador para realizar la asignación.
      // ej: await Provider.of<UserController>(context, listen: false).asignarEmpleado(
      //   empleadoId: _empleadoSeleccionado,
      //   usuarioId: _usuarioSeleccionado,
      // );

      // Simulación de llamada a API
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario asignado al empleado correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar usuario: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Usuario a Empleado'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.assignment_ind, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 24),
              
              // Dropdown para seleccionar empleado
              DropdownButtonFormField<String>(
                value: _empleadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Empleado',
                  prefixIcon: Icon(Icons.person_search),
                  border: OutlineInputBorder(),
                ),
                items: _empleadosSinUsuario.map((String empleado) {
                  return DropdownMenuItem<String>(
                    value: empleado,
                    child: Text(empleado),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _empleadoSeleccionado = newValue;
                  });
                },
                validator: (value) => value == null ? 'Debe seleccionar un empleado' : null,
              ),
              const SizedBox(height: 24),
              const Center(child: Icon(Icons.link, size: 40, color: Colors.grey)),
              const SizedBox(height: 24),
              
              // Dropdown para seleccionar usuario
              DropdownButtonFormField<String>(
                value: _usuarioSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Usuario',
                  prefixIcon: Icon(Icons.account_circle),
                  border: OutlineInputBorder(),
                ),
                items: _usuariosNoAsignados.map((String usuario) {
                  return DropdownMenuItem<String>(
                    value: usuario,
                    child: Text(usuario),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _usuarioSeleccionado = newValue;
                  });
                },
                validator: (value) => value == null ? 'Debe seleccionar un usuario' : null,
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _asignarUsuario,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text('Asignar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}