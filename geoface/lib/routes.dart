// -----------------------------------------------------------------------------
// @Encabezado:   Configuración de Rutas de la Aplicación
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define las rutas de navegación de la aplicación
//               GeoFace. Contiene la configuración de rutas nombradas y el
//               método `generateRoute` que maneja la navegación entre diferentes
//               pantallas de la aplicación, incluyendo el menú principal,
//               autenticación, dashboard administrativo y páginas de gestión.
//
// @NombreArchivo: routes.dart
// @Ubicacion:    lib/routes.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

// FILE: routes.dart
import 'package:flutter/material.dart';
import 'views/auth/login_page.dart';
import 'views/admin/dashboard_page.dart';
import 'views/admin/empleados_page.dart';
import 'views/admin/sedes_page.dart';
import 'views/admin/reportes_page.dart';
import 'views/admin/empleado_detail_page.dart';
import 'views/admin/registro_biometrico_page.dart';
import 'views/admin/sede_detail_page.dart';
import 'views/empleado/marcar_asistencia_page.dart';
import 'views/admin/admin_layout.dart';
import 'views/admin/gestion_usuarios_empleados_page.dart';
import 'models/empleado.dart';


class AppRoutes {
  static const String mainMenu = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String empleados = '/empleados';
  static const String empleadoDetail = '/empleado-detail';
  static const String sedes = '/sedes';
  static const String sedeDetail = '/sede-detail';
  static const String reportes = '/reportes';
  static const String marcarAsistencia = '/marcar-asistencia';
  static const String biometrico = '/biometricos';
  static const String gestionUsuariosEmpleados = '/gestion-usuarios-empleados';
  static const String adminLayout = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Widget de error genérico para rutas con argumentos faltantes
    Widget errorRoute(String routeName) => Scaffold(
          appBar: AppBar(title: const Text('Error de Navegación')),
          body: Center(
            child: Text('Error: Faltan argumentos para la ruta $routeName'),
          ),
        );

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case empleados:
        return MaterialPageRoute(builder: (_) => const EmpleadosPage());
      case gestionUsuariosEmpleados:
        return MaterialPageRoute(builder: (_) => const GestionUsuariosEmpleadosPage());
      case empleadoDetail:
        // MEJORA: Verificación segura de argumentos.
        final args = settings.arguments;
        if (args is Map<String, dynamic> && args.containsKey('empleadoId')) {
          return MaterialPageRoute(
              builder: (_) => EmpleadoDetailPage(empleadoId: args['empleadoId']));
        }
        return MaterialPageRoute(builder: (_) => errorRoute(settings.name!));

      case sedes:
        return MaterialPageRoute(builder: (_) => const SedesPage());
      
      case sedeDetail:
        // MEJORA: Verificación segura de argumentos.
        final args = settings.arguments;
        if (args is Map<String, dynamic> && args.containsKey('sedeId')) {
          return MaterialPageRoute(
              builder: (_) => SedeDetailPage(sedeId: args['sedeId']));
        }
        return MaterialPageRoute(builder: (_) => errorRoute(settings.name!));

      case reportes:
        return MaterialPageRoute(builder: (_) => const ReportesPage());
      
      case marcarAsistencia:
        // Esta ruta ahora no espera argumentos, lo cual es más lógico.
        return MaterialPageRoute(
          builder: (_) => MarcarAsistenciaPage()
        );
      
      case biometrico:
        // MEJORA: Verificación segura de argumentos.
        final args = settings.arguments;
        if (args is Map<String, dynamic> && args.containsKey('empleado') && args['empleado'] is Empleado) {
          return MaterialPageRoute(builder: (_) => RegistroBiometricoScreen(empleado: args['empleado']));
        }
        return MaterialPageRoute(builder: (_) => errorRoute(settings.name!));
        
      case adminLayout:
        return MaterialPageRoute(builder: (_) => const AdminLayout());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Ruta no definida para ${settings.name}'),
            ),
          ),
        );
    }
  }
}