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

class _PermissionsHandlerScreenState extends State<PermissionsHandlerScreen> with TickerProviderStateMixin {
  final List<PermissionInfo> _permissions = [
    PermissionInfo(
      permission: Permission.camera,
      title: 'Cámara',
      description: 'Usamos la cámara para el reconocimiento facial al registrar tu asistencia.',
      icon: Icons.camera_alt_rounded,
      lottieAsset: 'assets/animations/camera_animation.json',
    ),
    PermissionInfo(
      permission: Permission.location,
      title: 'Ubicación',
      description: 'Verificamos tu ubicación para validar que estés en las instalaciones de la empresa.',
      icon: Icons.location_on_rounded,
      lottieAsset: 'assets/animations/location_animation.json',
    ),
  ];

  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  int _currentPage = 0;
  bool _isLoading = false;
  bool _showSummary = false;
  Map<Permission, PermissionStatus> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _updateProgressValue();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _updateProgressValue() {
    final newValue = (_currentPage + 1) / _permissions.length;
    _progressAnimationController.animateTo(newValue);
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    Map<Permission, PermissionStatus> statuses = {};

    for (var permissionInfo in _permissions) {
      final status = await permissionInfo.permission.status;
      statuses[permissionInfo.permission] = status;
    }

    setState(() {
      _permissionStatus = statuses;
      _isLoading = false;
    });

    _checkAllPermissionsGranted();
  }

  Future<void> _requestCurrentPermission() async {
    if (_isLoading) return;

    final permissionInfo = _permissions[_currentPage];

    setState(() {
      _isLoading = true;
    });

    final status = await permissionInfo.permission.request();

    setState(() {
      _permissionStatus[permissionInfo.permission] = status;
      _isLoading = false;
    });

    if (status.isGranted) {
      // Un pequeño delay para que el usuario vea el cambio de estado antes de pasar a la siguiente página.
      await Future.delayed(const Duration(milliseconds: 500));
      _goToNextPage();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _permissions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _showSummary = true;
      });
    }
  }

  void _checkAllPermissionsGranted() {
    bool allGranted = _permissions.every((p) => _permissionStatus[p.permission]?.isGranted ?? false);

    if (allGranted) {
      // Si todos los permisos ya estaban concedidos desde el inicio,
      // mostramos directamente el resumen.
      setState(() {
        _showSummary = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: _showSummary
            ? _buildPermissionsSummary(theme, isDarkMode)
            : _buildPermissionsFlow(theme, isDarkMode),
      ),
    );
  }

  Widget _buildPermissionsFlow(ThemeData theme, bool isDarkMode) {
    return Column(
      children: [
        // Progress bar y Logo
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            color: theme.primaryColor,
                            minHeight: 8,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Logo y texto superior
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 32,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Configuración de permisos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        // PageView for permissions
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _permissions.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
                _updateProgressValue();
              });
            },
            itemBuilder: (context, index) {
              final permissionInfo = _permissions[index];
              final status = _permissionStatus[permissionInfo.permission];
              final isGranted = status?.isGranted ?? false;

              return _buildPermissionPage(
                context,
                permissionInfo,
                isGranted,
                isDarkMode,
                index == _permissions.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }
  
  // =======================================================================
  // ==================== WIDGET DE PÁGINA REFACTORIZADO ===================
  // =======================================================================
  Widget _buildPermissionPage(
    BuildContext context,
    PermissionInfo info,
    bool isGranted,
    bool isDarkMode,
    bool isLastPermission,
  ) {
    final theme = Theme.of(context);

    // Se utiliza Column + Expanded para crear un layout flexible que no necesita scroll.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          // SECCIÓN DE CONTENIDO: Ocupa todo el espacio disponible empujando los botones hacia abajo.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contenedor de la animación para darle un espacio predominante.
                Expanded(
                  flex: 3, // Le da más peso a la animación.
                  child: Center(
                    child: _isLoading
                        ? Lottie.asset(
                            'assets/animations/loading.json', // Asegúrate de tener esta animación
                            width: 150,
                            height: 150,
                          )
                        : isGranted
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(40),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 100,
                                ),
                              )
                            : Lottie.asset(
                                info.lottieAsset,
                                // El tamaño se adapta al espacio disponible.
                                fit: BoxFit.contain,
                              ),
                  ),
                ),
                // Contenedor de texto.
                Expanded(
                  flex: 2, // Le da espacio al texto pero menos que a la animación.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // SECCIÓN DE BOTONES: Se ancla en la parte inferior.
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge de estado "Permiso Concedido"
              AnimatedOpacity(
                opacity: isGranted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Permiso concedido',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón principal
              ElevatedButton(
                onPressed: isGranted
                    ? (isLastPermission
                        ? () => setState(() => _showSummary = true)
                        : _goToNextPage)
                    : _requestCurrentPermission,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: isGranted ? Colors.green : theme.primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isGranted
                      ? (isLastPermission ? 'VER RESUMEN' : 'CONTINUAR')
                      : 'CONCEDER PERMISO',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Texto informativo
              Text(
                'Este permiso es obligatorio para el funcionamiento de la app.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSummary(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Encabezado
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Todo listo!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Has configurado todos los permisos necesarios. La aplicación está lista para usarse.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Lista de permisos
          Expanded(
            child: ListView.separated(
              itemCount: _permissions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final permission = _permissions[index];
                final status = _permissionStatus[permission.permission];
                final isGranted = status?.isGranted ?? false;
                
                return _buildPermissionListItem(permission, isGranted, theme, isDarkMode);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botón de continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onPermissionsGranted,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: theme.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'COMENZAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionListItem(
    PermissionInfo info, 
    bool isGranted, 
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!)
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              info.icon,
              color: isGranted ? Colors.green : theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isGranted ? 'Concedido' : 'Requerido',
              style: TextStyle(
                fontSize: 12,
                color: isGranted ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
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

  PermissionInfo({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.lottieAsset = '',
  });
}