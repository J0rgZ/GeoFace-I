// -----------------------------------------------------------------------------
// @Encabezado:   Página de Notificaciones
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página de notificaciones para el
//               administrador. Permite ver las notificaciones del día y
//               solicitar permisos de notificaciones.
//
// @NombreArchivo: notificaciones_page.dart
// @Ubicacion:    lib/views/admin/notificaciones_page.dart
// @FechaInicio:  25/06/2025
// @FechaFin:     25/06/2025
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/notificacion_controller.dart';
import '../../models/notificacion.dart';

/// NotificacionesPage: Página de notificaciones para el administrador
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    final controller = Provider.of<NotificacionController>(context, listen: false);
    
    // Solicita permisos si aún no se han concedido
    final tienePermisos = await controller.verificarPermisos();
    if (!tienePermisos) {
      // No solicitamos automáticamente, esperamos a que el usuario lo haga
    }
    
    // Carga las notificaciones del día
    await controller.cargarNotificacionesDeHoy();
  }

  Future<void> _solicitarPermisos() async {
    final controller = Provider.of<NotificacionController>(context, listen: false);
    final concedidos = await controller.solicitarPermisos();
    
    if (!mounted) return;
    
    if (concedidos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permisos de notificaciones concedidos'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permisos de notificaciones denegados. Puedes activarlos en la configuración del dispositivo.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    final controller = Provider.of<NotificacionController>(context, listen: false);
    await controller.marcarTodasComoLeidas();
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas las notificaciones han sido marcadas como leídas'),
      ),
    );
  }

  Future<void> _refresh() async {
    final controller = Provider.of<NotificacionController>(context, listen: false);
    await controller.cargarNotificacionesDeHoy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          Consumer<NotificacionController>(
            builder: (context, controller, _) {
              if (controller.notificacionesNoLeidas > 0) {
                return IconButton(
                  icon: Badge(
                    label: Text('${controller.notificacionesNoLeidas}'),
                    child: const Icon(Icons.mark_email_read_rounded),
                  ),
                  onPressed: _marcarTodasComoLeidas,
                  tooltip: 'Marcar todas como leídas',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificacionController>(
        builder: (context, controller, _) {
          // Si no se han solicitado permisos, mostrar pantalla de permisos
          if (!controller.permisosConcedidos) {
            return _buildPermisosScreen(context, theme, controller);
          }

          // Si está cargando, mostrar indicador
          if (controller.loading && controller.notificacionesDeHoy.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hay error, mostrarlo
          if (controller.errorMessage != null && controller.notificacionesDeHoy.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar notificaciones',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Contenido principal
          return RefreshIndicator(
            onRefresh: _refresh,
            color: colorScheme.primary,
            child: CustomScrollView(
              slivers: [
                // Lista de notificaciones
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Notificaciones del Día',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (controller.notificacionesDeHoy.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay notificaciones hoy',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Las notificaciones aparecerán aquí cuando los empleados marquen asistencia',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final notificacion = controller.notificacionesDeHoy[index];
                        return _buildNotificacionTile(context, theme, notificacion, controller);
                      },
                      childCount: controller.notificacionesDeHoy.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermisosScreen(
    BuildContext context,
    ThemeData theme,
    NotificacionController controller,
  ) {
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Permisos de Notificaciones',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Para recibir notificaciones cuando los empleados marquen asistencia, necesitamos permisos de notificaciones.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _solicitarPermisos,
              icon: const Icon(Icons.notifications_rounded),
              label: const Text('Solicitar Permisos'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Cargar notificaciones sin permisos (solo en la app)
                controller.cargarNotificacionesDeHoy();
              },
              child: const Text('Continuar sin permisos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificacionTile(
    BuildContext context,
    ThemeData theme,
    Notificacion notificacion,
    NotificacionController controller,
  ) {
    final colorScheme = theme.colorScheme;
    final fechaFormat = DateFormat('HH:mm');
    final icon = _getIconForTipo(notificacion.tipo);
    final color = _getColorForTipo(notificacion.tipo, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          notificacion.titulo,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: notificacion.leida ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notificacion.mensaje),
            if (notificacion.sedeNombre != null) ...[
              const SizedBox(height: 4),
              Text(
                'Sede: ${notificacion.sedeNombre}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              fechaFormat.format(notificacion.fecha),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: notificacion.leida
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () async {
          if (!notificacion.leida) {
            await controller.marcarComoLeida(notificacion.id);
          }
        },
      ),
    );
  }

  IconData _getIconForTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.entrada:
        return Icons.login_rounded;
      case TipoNotificacion.salida:
        return Icons.logout_rounded;
      case TipoNotificacion.ausencia:
        return Icons.person_off_rounded;
      case TipoNotificacion.tardanza:
        return Icons.schedule_rounded;
      case TipoNotificacion.resumenDia:
        return Icons.today_rounded;
      case TipoNotificacion.resumenSede:
        return Icons.location_city_rounded;
    }
  }

  Color _getColorForTipo(TipoNotificacion tipo, ColorScheme colorScheme) {
    switch (tipo) {
      case TipoNotificacion.entrada:
        return Colors.green;
      case TipoNotificacion.salida:
        return Colors.blue;
      case TipoNotificacion.ausencia:
        return Colors.red;
      case TipoNotificacion.tardanza:
        return Colors.orange;
      case TipoNotificacion.resumenDia:
        return colorScheme.primary;
      case TipoNotificacion.resumenSede:
        return colorScheme.primary;
    }
  }
}

