// -----------------------------------------------------------------------------
// @Encabezado:   Layout Principal del Administrador
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define el layout principal para la interfaz de
//               administrador. Incluye navegación por pestañas, menú de
//               configuración superior, barra de navegación inferior
//               personalizada, gestión de temas y control del estilo del
//               sistema operativo para una experiencia inmersiva.
//
// @NombreArchivo: admin_layout.dart
// @Ubicacion:    lib/views/admin/admin_layout.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoface/views/admin/api_config_page.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_provider.dart';
import '../../models/usuario.dart';
import '../../routes.dart';
import '../admin/dashboard_page.dart';
import '../admin/sedes_page.dart';
import '../admin/empleados_page.dart';
import '../admin/reportes_page.dart';
import '../admin/administradores_page.dart';
import 'gestion_usuarios_empleados_page.dart';
import '../admin/cambiar_contrasena_page.dart';
import '../admin/notificaciones_page.dart';

/// AdminLayout: El contenedor principal para la interfaz de administrador.
///
/// Este widget Stateful gestiona la navegación principal a través de un TabBarView
/// y una barra de navegación inferior personalizada. También implementa un menú
/// de configuración superior que se despliega de forma elegante y controla
/// el estilo de la UI del sistema operativo para una experiencia inmersiva.
class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> with SingleTickerProviderStateMixin {
  /// Controlador para sincronizar el TabBarView y la navegación.
  late TabController _tabController;
  
  /// Índice de la pestaña actualmente seleccionada.
  int _selectedIndex = 0;

  /// Caché de las páginas principales para evitar su reconstrucción al cambiar de pestaña.
  late final List<Widget> _pageCache;

  // --- CONFIGURACIÓN DE NAVEGACIÓN ---
  // Define los títulos e íconos para la navegación principal, facilitando su mantenimiento.
  final List<String> _titles = ['Dashboard', 'Sedes', 'Empleados', 'Reportes'];
  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.location_city_rounded,
    Icons.people_rounded,
    Icons.assessment_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _titles.length, vsync: this);

    // Añade un listener para actualizar el estado cuando el controlador cambia de índice.
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _selectedIndex != _tabController.index) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });

    // Inicializa el caché de páginas. El DashboardPage recibe una función de callback
    // para poder navegar a otras pestañas desde su interior.
    _pageCache = [
      DashboardPage(onNavigateToTab: _onItemTapped),
      const SedesPage(),
      const EmpleadosPage(),
      const ReportesPage(),
    ];
  }

  @override
  void dispose() {
    // Es crucial liberar los recursos del controlador para evitar fugas de memoria.
    _tabController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE LÓGICA Y NAVEGACIÓN ---

  /// Maneja el toque en un ítem de la barra de navegación.
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.lightImpact(); // Provee una respuesta táctil sutil.
      setState(() => _selectedIndex = index);
      _tabController.animateTo(index);
    }
  }

  /// Muestra el menú de configuración mediante una ruta de página personalizada.
  /// Esto crea una superposición (Overlay) en lugar de un BottomSheet tradicional.
  void _showSettingsMenu(Usuario currentUser) {
    HapticFeedback.mediumImpact(); // Respuesta táctil más notoria.
    Navigator.of(context).push(_createSettingsRoute(currentUser));
  }
  
  /// Construye la ruta de la página del menú con una transición de fundido.
  PageRouteBuilder _createSettingsRoute(Usuario currentUser) {
    return PageRouteBuilder(
      opaque: false, // Permite ver la página anterior debajo.
      barrierDismissible: true, // Cierra el menú al tocar fuera.
      pageBuilder: (context, _, __) => _SettingsMenu(
        currentUser: currentUser,
        onNavigate: (page) {
          Navigator.pop(context); // Cierra el menú primero.
          Navigator.push(context, MaterialPageRoute(builder: (context) => page));
        },
        onToggleTheme: () {
          Navigator.pop(context);
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        onLogout: () {
          Navigator.pop(context);
          _showLogoutConfirmation();
        },
      ),
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Muestra un diálogo de confirmación antes de cerrar la sesión.
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.logout_rounded, size: 48, color: Theme.of(context).colorScheme.error),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!mounted) return;
              final authController = Provider.of<AuthController>(context, listen: false);
              final navigator = Navigator.of(context);
              await authController.logout();
              if (mounted) {
                navigator.pushReplacementNamed(AppRoutes.login);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN DE UI ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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
              Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Sesión No Iniciada',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, inicia sesión nuevamente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
      // Si el usuario NO es admin, redirigir inmediatamente
      if (!authController.isAdmin) {
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
                Icon(Icons.security_rounded, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Acceso No Autorizado',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solo los administradores pueden acceder a esta sección.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

    // AnnotatedRegion controla el estilo de la UI del sistema (barras de estado y navegación).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Estilo de la barra de navegación inferior de Android.
        systemNavigationBarColor: theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        // Estilo de la barra de estado superior.
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        // PROTECCIÓN: Prevenir navegación no autorizada con el botón retroceder
        canPop: authController.isAdmin, // Solo permite retroceder si es admin
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          // Si se intentó retroceder y el usuario no es admin, forzar redirección
          if (!authController.isAdmin && !didPop) {
            if (!mounted) return;
            // Guardar Navigator antes de operaciones asíncronas
            final navigator = Navigator.of(context);
            await authController.logout();
            if (mounted) {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.mainMenu,
                (route) => false,
              );
            }
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(theme, currentUser),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), // Deshabilita el deslizamiento.
            children: _pageCache,
          ),
          bottomNavigationBar: _buildBottomNav(theme),
        ),
      ),
    );
  }

  /// Construye la AppBar con un título animado y el botón de perfil/menú.
  PreferredSizeWidget _buildAppBar(ThemeData theme, Usuario currentUser) {
    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: Text(_titles[_selectedIndex], key: ValueKey<String>(_titles[_selectedIndex])),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(Icons.face_retouching_natural_rounded, color: theme.colorScheme.primary, size: 28),
      ),
      actions: [
        // Widget interactivo que muestra el perfil y abre el menú.
        GestureDetector(
          onTap: () => _showSettingsMenu(currentUser),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    currentUser.nombreUsuario.isNotEmpty ? currentUser.nombreUsuario[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentUser.nombreUsuario.split(' ').first,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye la barra de navegación inferior personalizada.
  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha:0.2), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) => _buildNavItem(index, theme)),
          ),
        ),
      ),
    );
  }

  /// Construye cada ítem individual de la barra de navegación.
  Widget _buildNavItem(int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          color: Colors.transparent, // Área de toque expandida.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador superior animado.
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSelected ? 4 : 0,
                width: 24,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                _icons[index],
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                _titles[index],
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET PRIVADO PARA EL MENÚ DE CONFIGURACIÓN ---
/// _SettingsMenu: Un widget sin estado que representa el contenido del menú desplegable.
/// Se mantiene separado para mejorar la legibilidad y reutilización.
class _SettingsMenu extends StatelessWidget {
  final Usuario currentUser;
  final Function(Widget) onNavigate;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  const _SettingsMenu({
    required this.currentUser,
    required this.onNavigate,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.pop(context), // Cierra el menú al tocar el fondo.
      child: Material(
        color: Colors.black.withValues(alpha:0.6),
        child: Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {}, // Evita que el menú se cierre al tocar dentro de él.
            child: Container(
              margin: const EdgeInsets.only(top: kToolbarHeight + 40, left: 16, right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 20, spreadRadius: 5)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileHeader(theme),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  _buildMenuSection(context, "Mi Cuenta", [
                    _buildOptionTile(Icons.notifications_rounded, "Notificaciones", () => onNavigate(const NotificacionesPage()), theme),
                    _buildOptionTile(Icons.password_rounded, "Cambiar Contraseña", () => onNavigate(const CambiarContrasenaPage()), theme),
                  ]),
                  _buildMenuSection(context, "Administración", [
                    _buildOptionTile(Icons.admin_panel_settings_rounded, "Administradores", () => onNavigate(const AdministradoresPage()), theme),
                    _buildOptionTile(Icons.assignment_ind_rounded, "Gestionar Usuario", () => onNavigate(const GestionUsuariosEmpleadosPage()), theme),
                    _buildOptionTile(Icons.api_rounded, "API Reconocimiento", () => onNavigate(const ApiConfigPage()), theme),
                  ]),
                  _buildMenuSection(context, "Aplicación", [
                    _buildOptionTile(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, isDarkMode ? 'Modo Claro' : 'Modo Oscuro', onToggleTheme, theme),
                    _buildOptionTile(Icons.logout_rounded, "Cerrar Sesión", onLogout, theme, isDestructive: true),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la cabecera del menú con la información del perfil del usuario.
  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            currentUser.nombreUsuario.isNotEmpty ? currentUser.nombreUsuario[0].toUpperCase() : 'A',
            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentUser.nombreUsuario, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(currentUser.correo, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye una sección del menú con un título y una lista de opciones.
  Widget _buildMenuSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  /// Construye cada opción individual del menú como un ListTile.
  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap, ThemeData theme, {bool isDestructive = false}) {
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}