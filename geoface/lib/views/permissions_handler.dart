// -----------------------------------------------------------------------------
// @Encabezado:   Manejador de Permisos de la Aplicación
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la pantalla de configuración de permisos
//               necesarios para el funcionamiento de la aplicación GeoFace.
//               Maneja la solicitud de permisos de cámara y ubicación de forma
//               interactiva con animaciones Lottie y una interfaz moderna que
//               guía al usuario paso a paso en la concesión de permisos.
//
// @NombreArchivo: permissions_handler.dart
// @Ubicacion:    lib/views/permissions_handler.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

class PermissionsHandlerScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionsHandlerScreen({
    Key? key,
    required this.onPermissionsGranted,
  }) : super(key: key);

  @override
  State<PermissionsHandlerScreen> createState() => _PermissionsHandlerScreenState();
}

class _PermissionsHandlerScreenState extends State<PermissionsHandlerScreen> 
    with TickerProviderStateMixin {
  
  static const List<PermissionInfo> _permissions = [
    PermissionInfo(
      permission: Permission.camera,
      title: 'Cámara',
      description: 'Para reconocimiento facial',
      icon: Icons.camera_alt_rounded,
      lottieAsset: 'assets/animations/camera_animation.json',
    ),
    PermissionInfo(
      permission: Permission.location,
      title: 'Ubicación',
      description: 'Para validar tu presencia',
      icon: Icons.location_on_rounded,
      lottieAsset: 'assets/animations/location_animation.json',
    ),
  ];

  late final PageController _pageController;
  late final AnimationController _progressController;
  late final AnimationController _buttonController;
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _showSummary = false;
  Map<Permission, PermissionStatus> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _checkPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final Map<Permission, PermissionStatus> statuses = {};
    
    for (final permissionInfo in _permissions) {
      statuses[permissionInfo.permission] = await permissionInfo.permission.status;
    }

    if (mounted) {
      setState(() => _permissionStatus = statuses);
      
      if (_permissions.every((p) => _permissionStatus[p.permission]?.isGranted ?? false)) {
        setState(() => _showSummary = true);
      }
    }
  }

  Future<void> _requestCurrentPermission() async {
    if (_isLoading) return;

    _buttonController.forward();
    setState(() => _isLoading = true);

    final permission = _permissions[_currentPage];
    final status = await permission.permission.request();

    if (mounted) {
      setState(() {
        _permissionStatus[permission.permission] = status;
        _isLoading = false;
      });

      _buttonController.reverse();

      if (status.isGranted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _nextStep();
      }
    }
  }

  void _nextStep() {
    if (_currentPage < _permissions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentPage++);
      _progressController.animateTo((_currentPage + 1) / _permissions.length);
    } else {
      setState(() => _showSummary = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _showSummary 
              ? _buildSummary(theme)
              : _buildPermissionsFlow(theme),
        ),
      ),
    );
  }

  Widget _buildPermissionsFlow(ThemeData theme) {
    return Column(
      children: [
        // Header compacto
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) => LinearProgressIndicator(
                  value: (_currentPage + 1) / _permissions.length,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Configuración de permisos',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // PageView optimizado
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _permissions.length,
            itemBuilder: (context, index) => _buildPermissionPage(
              _permissions[index],
              _permissionStatus[_permissions[index].permission]?.isGranted ?? false,
              theme,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionPage(PermissionInfo info, bool isGranted, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Lottie Animation - Elemento principal
          Expanded(
            flex: 6,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 180,
                        height: 180,
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          fit: BoxFit.contain,
                        ),
                      )
                    : isGranted
                        ? Container(
                            key: const ValueKey('success'),
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 90,
                            ),
                          )
                        : SizedBox(
                            key: ValueKey(info.lottieAsset),
                            width: 300,
                            height: 300,
                            child: Lottie.asset(
                              info.lottieAsset,
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
              ),
            ),
          ),
          
          // Contenido de texto minimalista
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  info.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  info.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Botones en la parte inferior
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badge de estado
                AnimatedOpacity(
                  opacity: isGranted ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Concedido',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botón principal
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) => Transform.scale(
                      scale: 1.0 - (_buttonController.value * 0.05),
                      child: ElevatedButton(
                        onPressed: isGranted
                            ? (_currentPage == _permissions.length - 1
                                ? () => setState(() => _showSummary = true)
                                : _nextStep)
                            : _requestCurrentPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGranted ? Colors.green : theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isGranted
                              ? (_currentPage == _permissions.length - 1 ? 'FINALIZAR' : 'CONTINUAR')
                              : 'CONCEDER PERMISO',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Header de éxito
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Todo listo!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Permisos configurados correctamente',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Lista compacta de permisos
          Expanded(
            flex: 2,
            child: Column(
              children: _permissions.map((permission) {
                final isGranted = _permissionStatus[permission.permission]?.isGranted ?? false;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        permission.icon,
                        color: isGranted ? Colors.green : theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          permission.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Botón final
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onPermissionsGranted,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'COMENZAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionInfo {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final String lottieAsset;

  const PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    required this.lottieAsset,
  });
}