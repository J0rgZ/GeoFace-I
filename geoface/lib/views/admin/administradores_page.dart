// -----------------------------------------------------------------------------
// @Encabezado:   Página de Gestión de Administradores
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página para gestionar usuarios
//               administradores del sistema. Incluye visualización de lista
//               de administradores, creación de nuevos administradores,
//               edición de datos existentes, gestión de estados y navegación
//               a formularios de administración con animaciones y estados
//               de carga.
//
// @NombreArchivo: administradores_page.dart
// @Ubicacion:    lib/views/admin/administradores_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/administrador_controller.dart';
import '../../models/usuario.dart';
import 'add_edit_admin_page.dart';

class AdministradoresPage extends StatefulWidget {
  const AdministradoresPage({super.key});

  @override
  State<AdministradoresPage> createState() => _AdministradoresPageState();
}

class _AdministradoresPageState extends State<AdministradoresPage>
    with TickerProviderStateMixin {
  late Future<List<Usuario>> _administradoresFuture;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _loadData() {
    _administradoresFuture = Provider.of<AdministradorController>(context, listen: false)
        .getAdministradores();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  void _navigateAndRefresh(Widget page) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Widget _buildStatsCard(List<Usuario> admins) {
    final activos = admins.where((a) => a.activo).length;
    final inactivos = admins.length - activos;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resumen de Administradores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Activos',
                  activos.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
              Expanded(
                child: _buildStatItem(
                  'Inactivos',
                  inactivos.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
              Expanded(
                child: _buildStatItem(
                  'Total',
                  admins.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _toggleStatus(Usuario admin) async {
    final actionText = admin.activo ? 'desactivar' : 'activar';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: admin.activo ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                admin.activo ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: admin.activo ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Confirmar Acción')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de que desea $actionText al administrador?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      admin.nombreUsuario,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: Icon(admin.activo ? Icons.block : Icons.check),
            label: Text(actionText.toUpperCase()),
            style: FilledButton.styleFrom(
              backgroundColor: admin.activo ? Theme.of(context).colorScheme.error : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = Provider.of<AdministradorController>(context, listen: false);
      final success = await controller.toggleAdminStatus(admin);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Administrador ${actionText}do correctamente',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        _refreshData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${controller.errorMessage}')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildAdminCard(Usuario admin, ThemeData theme, ColorScheme colorScheme, int index, bool isSelf) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: admin.activo
                  ? Colors.green.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: admin.activo
                  ? null
                  : LinearGradient(
                      colors: [
                        colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: admin.activo
                          ? LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                colorScheme.onSurface.withValues(alpha: 0.38),
                                colorScheme.onSurface.withValues(alpha: 0.26),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: admin.activo
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información del administrador
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del administrador
                        Text(
                          admin.nombreUsuario,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: admin.activo
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                            decoration: !admin.activo ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Badges en una fila flexible
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (isSelf)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  'TÚ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: admin.activo
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: admin.activo
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    admin.activo ? Icons.check_circle : Icons.cancel,
                                    size: 14,
                                    color: admin.activo
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    admin.activo ? 'Activo' : 'Inactivo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: admin.activo
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Email
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                admin.correo,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateAndRefresh(AddEditAdminPage(admin: admin));
                      } else if (value == 'toggle_status') {
                        _toggleStatus(admin);
                      }
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[];
                      
                      // Solo mostrar opción de activar/desactivar si no eres tú mismo
                      if (!isSelf) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: admin.activo 
                                        ? Colors.red.shade50 
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    admin.activo ? Icons.block : Icons.check_circle,
                                    size: 20,
                                    color: admin.activo ? Colors.red.shade700 : Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      admin.activo ? 'Desactivar' : 'Activar',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      admin.activo 
                                          ? 'El administrador quedará inactivo' 
                                          : 'El administrador quedará activo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                        
                        // Separador y opción de editar
                        items.add(const PopupMenuDivider());
                        items.add(
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 12),
                                const Text('Editar Administrador'),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Si es el usuario actual, mostrar solo información
                        items.add(
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No puedes modificar tu propio estado',
                                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return items;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = Provider.of<AuthController>(context, listen: false).currentUser;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Gestión de Administradores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: FutureBuilder<List<Usuario>>(
          future: _administradoresFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando administradores...',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar datos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _refreshData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off_outlined,
                        size: 80,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No hay administradores',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay administradores registrados.\nPresiona el botón (+) para agregar el primero.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final admins = snapshot.data!;
            return Column(
              children: [
                _buildStatsCard(admins),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: admins.length,
                    itemBuilder: (context, index) {
                      final admin = admins[index];
                      final isSelf = currentUser?.id == admin.id;
                      return _buildAdminCard(admin, theme, colorScheme, index, isSelf);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _navigateAndRefresh(const AddEditAdminPage()),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text(
            'Nuevo Admin',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          tooltip: 'Agregar Administrador',
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
