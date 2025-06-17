import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/empleado_controller.dart';
import '../../models/empleado.dart';

class GestionUsuariosEmpleadosPage extends StatefulWidget {
  const GestionUsuariosEmpleadosPage({super.key});

  @override
  State<GestionUsuariosEmpleadosPage> createState() => _GestionUsuariosEmpleadosPageState();
}

class _GestionUsuariosEmpleadosPageState extends State<GestionUsuariosEmpleadosPage> {
  // Esta variable espera un Future que devuelva una lista, lo cual es correcto.
  late Future<List<Empleado>> _empleadosFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // --- LA CORRECCIÓN ESTÁ AQUÍ ---
    // Se cambia la llamada a 'fetchEmpleados()' que es el método que devuelve Future<List<Empleado>>.
    // El método 'getEmpleados()' se mantiene para la compatibilidad con otras vistas.
    _empleadosFuture = Provider.of<EmpleadoController>(context, listen: false).fetchEmpleados();
  }

  Future<void> _refreshData() async {
    // Cuando se refresca, se vuelve a llamar a _loadData que asigna el nuevo futuro.
    setState(() => _loadData());
  }

  // --- ACCIONES DE LA UI ---

  void _handleAssignUser(Empleado empleado) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Asignación'),
        content: Text(
          'Se creará un usuario para "${empleado.nombreCompleto}".\n\n'
          'Correo: ${empleado.dni}@geoface.com\n'
          'Contraseña inicial: ${empleado.dni}\n\n'
          'El empleado podrá cambiar su contraseña después de iniciar sesión.\n\n'
          '¿Desea continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Crear Usuario')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = Provider.of<EmpleadoController>(context, listen: false);
      final success = await controller.assignUserToEmpleado(empleado: empleado);
      _showFeedback(
        success ? 'Usuario asignado correctamente.' : controller.errorMessage ?? 'Ocurrió un error.',
        isError: !success,
      );
      if (success) _refreshData();
    }
  }

  void _handleResetPassword(Empleado empleado) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer Contraseña'),
        content: Text(
          'Se enviará un correo a "${empleado.dni}@geoface.com" con instrucciones para restablecer la contraseña. ¿Está seguro?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Enviar Correo')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = Provider.of<EmpleadoController>(context, listen: false);
      final success = await controller.resetEmpleadoPassword(empleado: empleado);
      _showFeedback(
        success ? 'Correo de restablecimiento enviado.' : controller.errorMessage ?? 'Ocurrió un error.',
        isError: !success,
      );
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se escucha al controlador para reaccionar a cambios en el estado 'loading'.
    final empleadoController = context.watch<EmpleadoController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Empleado>>(
          future: _empleadosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                )
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No hay empleados registrados.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  )
                )
              );
            }

            final empleados = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: empleados.length,
              itemBuilder: (context, index) {
                final empleado = empleados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: empleado.tieneUsuario ? Colors.green : Theme.of(context).colorScheme.secondary,
                      child: Icon(
                        empleado.tieneUsuario ? Icons.check_circle_outline : Icons.person_add_alt_1,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(empleado.nombreCompleto),
                    subtitle: Text('DNI: ${empleado.dni}'),
                    trailing: empleado.tieneUsuario
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'reset_password') {
                                _handleResetPassword(empleado);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'reset_password',
                                child: ListTile(
                                  leading: Icon(Icons.lock_reset),
                                  title: Text('Restablecer Contraseña'),
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: empleadoController.loading ? null : () => _handleAssignUser(empleado),
                            child: empleadoController.loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Asignar'),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}