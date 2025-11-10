// -----------------------------------------------------------------------------
// @Encabezado:   Layout Principal del Empleado
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define el layout principal para la interfaz de
//               empleado. Proporciona la estructura de navegación y contenedor
//               principal para las funcionalidades específicas de empleados,
//               incluyendo marcación de asistencia, consulta de historial y
//               acceso a información personal relevante.
//
// @NombreArchivo: empleado_layout.dart
// @Ubicacion:    lib/views/empleado/empleado_layout.dart
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
import '../../routes.dart';
import 'historial_asistencias_page.dart';
import 'cambiar_contrasena_empleado_page.dart';

class EmpleadoLayout extends StatefulWidget {
  const EmpleadoLayout({super.key});

  @override
  State<EmpleadoLayout> createState() => _EmpleadoLayoutState();
}

class _EmpleadoLayoutState extends State<EmpleadoLayout> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authController = context.watch<AuthController>();
    final currentUser = authController.currentUser;
    final authStatus = authController.status;

    // Si está cargando o inicializando, mostrar indicador de carga
    if (authStatus == AuthStatus.loading || authStatus == AuthStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si no hay usuario autenticado, mostrar error
    if (authStatus == AuthStatus.unauthenticated || currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Sesión No Iniciada',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, inicia sesión nuevamente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // PROTECCIÓN CRÍTICA: Solo verificar rol cuando el usuario está completamente autenticado
    // Esperar a que el estado sea authenticated antes de verificar el rol
    if (authStatus == AuthStatus.authenticated) {
      // Si el usuario NO es empleado, redirigir inmediatamente
      if (!authController.isEmpleado) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Guardar Navigator antes de operaciones asíncronas
          final navigator = Navigator.of(context);
          authController.logout().then((_) {
            if (mounted) {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.mainMenu,
                (route) => false,
              );
            }
          });
        });
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_rounded, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Acceso No Autorizado',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solo los empleados pueden acceder a esta sección.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        );
      }
    }

    // Construir el layout del empleado si todo está correcto
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Historial de Asistencias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Botón de cambiar contraseña
          IconButton(
            icon: Icon(Icons.lock_reset, color: colorScheme.onSurface),
            tooltip: 'Cambiar Contraseña',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CambiarContrasenaEmpleadoPage(),
                ),
              );
            },
          ),
          // Botón de cierre de sesión más visible
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.error),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const HistorialAsistenciasPage(),
    );
  }

  Future<void> _cerrarSesion() async {
    if (!mounted) return;
    
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final confirmacion = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.logout_rounded,
          size: 48,
          color: colorScheme.error,
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmacion == true && mounted) {
      final authController = Provider.of<AuthController>(context, listen: false);
      await authController.logout();
      if (mounted) {
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.mainMenu,
          (route) => false,
        );
      }
    }
  }
}
