import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/usuario.dart';
import 'add_edit_admin_page.dart';

class AdministradoresPage extends StatefulWidget {
  const AdministradoresPage({Key? key}) : super(key: key);

  @override
  State<AdministradoresPage> createState() => _AdministradoresPageState();
}

class _AdministradoresPageState extends State<AdministradoresPage> {
  late Future<List<Usuario>> _administradoresFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Usamos el UserController para obtener los datos
    _administradoresFuture = Provider.of<UserController>(context, listen: false).getAdministradores();
  }

  Future<void> _refreshData() async {
    // Recarga los datos y actualiza la UI
    setState(() {
      _loadData();
    });
  }

  // Navega a la página de edición/creación y refresca la lista si hay cambios
  void _navigateAndRefresh(Widget page) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
    if (result == true) {
      _refreshData();
    }
  }
  
  // Muestra un diálogo de confirmación para activar/desactivar un usuario
  void _toggleStatus(Usuario admin) async {
    final actionText = admin.activo ? 'desactivar' : 'activar';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar Acción'),
        content: Text('¿Está seguro de que desea $actionText a "${admin.nombreUsuario}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionText == 'desactivar' ? Colors.red : Colors.green,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<UserController>(context, listen: false).toggleUserStatus(admin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Administrador ${actionText}do correctamente.'), backgroundColor: Colors.green),
          );
        }
        _refreshData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario actual para evitar que se edite a sí mismo
    final currentUser = Provider.of<AuthController>(context, listen: false).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Administradores'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Usuario>>(
          future: _administradoresFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay administradores registrados.\nPresiona el botón (+) para agregar el primero.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            final admins = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
              itemCount: admins.length,
              itemBuilder: (context, index) {
                final admin = admins[index];
                final isSelf = currentUser?.id == admin.id;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: admin.activo ? Theme.of(context).colorScheme.primary : Colors.grey[400],
                      child: const Icon(Icons.shield_outlined, color: Colors.white),
                    ),
                    title: Text(
                      admin.nombreUsuario,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: !admin.activo ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(admin.correo),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isSelf)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            tooltip: 'Editar nombre',
                            onPressed: () => _navigateAndRefresh(AddEditAdminPage(admin: admin)),
                          ),
                        // El Switch es más intuitivo que un icono de toggle
                        Switch(
                          value: admin.activo,
                          onChanged: isSelf ? null : (value) => _toggleStatus(admin),
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(const AddEditAdminPage()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Admin'),
        tooltip: 'Agregar Administrador',
      ),
    );
  }
}