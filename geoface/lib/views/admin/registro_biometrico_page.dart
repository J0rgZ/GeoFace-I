// -----------------------------------------------------------------------------
// @Encabezado:   Página de Registro de Datos Biométricos
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página para registrar datos biométricos
//               faciales de empleados. Incluye captura de imágenes con cámara,
//               procesamiento y almacenamiento en Firebase Storage, validación
//               de calidad de imagen, y gestión del estado de registro con
//               animaciones y feedback visual para el usuario.
//
// @NombreArchivo: registro_biometrico_page.dart
// @Ubicacion:    lib/views/admin/registro_biometrico_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

// lib/screens/registro_biometrico_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import '/../controllers/biometrico_controller.dart';
import '/../models/empleado.dart';

class RegistroBiometricoScreen extends StatefulWidget {
  final Empleado empleado;

  const RegistroBiometricoScreen({
    super.key,
    required this.empleado,
  });

  @override
  State<RegistroBiometricoScreen> createState() => _RegistroBiometricoScreenState();
}

class _RegistroBiometricoScreenState extends State<RegistroBiometricoScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late BiometricoController _controller;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = true;
  bool _isProcessing = false;

  List<String> _existingBiometricUrls = [];
  List<File> _capturedImages = [];
  int _captureStep = 0;
  bool _isCaptureMode = false;

  final List<String> _capturePrompts = [
    "Mira directamente a la cámara",
    "Gira tu rostro hacia la izquierda",
    "Ahora gira hacia la derecha"
  ];
  
  final List<String> _captureSubtitles = [
    "Mantén tu rostro centrado en el marco",
    "Perfil izquierdo, mantén la posición",
    "Perfil derecho, último paso"
  ];
  
  final List<IconData> _captureIcons = [
    Icons.face_retouching_natural,
    Icons.arrow_back_rounded,
    Icons.arrow_forward_rounded
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Provider.of<BiometricoController>(context, listen: false);
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingBiometrics();
    });
  }

  @override
  void dispose() {
    _controller.stopCamera();
    _pulseController.dispose();
    _slideController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller.stopCamera();
    } else if (state == AppLifecycleState.resumed && _isCaptureMode && _capturedImages.length < 3) {
      _initCamera();
    }
  }

  // --- LÓGICA DE NEGOCIO ---

  Future<void> _initCamera() async {
    try {
      if (_controller.isCameraInitialized) return;
      setState(() => _isLoading = true);
      await _controller.initCamera();
    } catch (e) {
      _showErrorDialog('Error de Cámara', 'No se pudo iniciar la cámara. Asegúrate de tener los permisos necesarios.');
      setState(() => _isCaptureMode = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkExistingBiometrics() async {
    setState(() => _isLoading = true);
    try {
      final urls = await _controller.getBiometricoUrlsByEmpleadoId(widget.empleado.id);
      if (mounted) {
        setState(() => _existingBiometricUrls = urls);
      }
    } catch (e) {
      debugPrint("Error verificando biométricos: $e");
      _showErrorDialog('Error de Conexión', 'No se pudieron cargar los datos biométricos existentes.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCaptureProcess() {
    setState(() {
      _isCaptureMode = true;
      _capturedImages.clear();
      _captureStep = 0;
    });
    _slideController.forward();
    _initCamera();
  }

  Future<void> _capturePhoto() async {
    if (!_controller.isCameraInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final imageFile = await _controller.takePicture();
      if (imageFile != null) {
        setState(() {
          _capturedImages.add(imageFile);
          if (_captureStep < 2) {
            _captureStep++;
            _slideController.reset();
            _slideController.forward();
          } else {
            _controller.stopCamera();
          }
        });
      }
    } catch (e) {
       _showErrorDialog('Error de Captura', 'No se pudo tomar la foto. Intenta de nuevo.');
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveBiometrics() async {
    if (_capturedImages.length != 3) return;

    setState(() => _isProcessing = true);
    try {
      bool success = await _controller.registerOrUpdateBiometricoWithMultipleFiles(
        widget.empleado.id, 
        _capturedImages
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Registro biométrico guardado con éxito"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {
          _isCaptureMode = false;
          _capturedImages.clear();
        });
        _slideController.reset();
        await _checkExistingBiometrics();
      } else {
        throw Exception(_controller.errorMessage ?? "Error desconocido al guardar.");
      }
    } catch (e) {
       _showErrorDialog('Error al Guardar', e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteBiometrics() async {
    setState(() => _isProcessing = true);
    try {
      bool success = await _controller.deleteBiometricoByEmpleadoId(widget.empleado.id);
      
      if(success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.white),
                SizedBox(width: 12),
                Text("Registro biométrico eliminado"),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {
          _existingBiometricUrls.clear();
          _isCaptureMode = false;
        });
      } else {
        throw Exception(_controller.errorMessage ?? "No se pudo eliminar el registro.");
      }
    } catch (e) {
      _showErrorDialog('Error al Eliminar', e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  
  void _resetCapture() {
    setState(() {
      _capturedImages.clear();
      _captureStep = 0;
    });
    _slideController.reset();
    _slideController.forward();
    _initCamera();
  }

  // --- WIDGETS AUXILIARES DE UI ---

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          FilledButton(
            child: const Text('Entendido'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    if (_existingBiometricUrls.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar Eliminación'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar permanentemente este registro biométrico? Esta acción no se puede deshacer.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          OutlinedButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteBiometrics();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        if (_isCaptureMode) {
          _controller.stopCamera();
          setState(() => _isCaptureMode = false);
          _slideController.reset();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Registro Biométrico'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _isCaptureMode ? Icons.close_rounded : Icons.arrow_back_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              if (_isCaptureMode) {
                _controller.stopCamera();
                setState(() => _isCaptureMode = false);
                _slideController.reset();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              _isLoading
                  ? _buildLoadingIndicator()
                  : _isCaptureMode
                      ? _buildCaptureView(theme)
                      : _buildInitialView(theme),
              
              if (_isProcessing) _buildProcessingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/loading.json',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/loading.json',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'Procesando...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VISTA INICIAL ---
  Widget _buildInitialView(ThemeData theme) {
    bool hasBiometrics = _existingBiometricUrls.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Avatar y estado
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: hasBiometrics 
                  ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                  : [theme.colorScheme.outline.withOpacity(0.3), theme.colorScheme.outline.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasBiometrics ? theme.colorScheme.primary : theme.colorScheme.outline).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              hasBiometrics ? Icons.verified_user_rounded : Icons.account_circle_outlined,
              size: 60,
              color: hasBiometrics ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Información del empleado
          Text(
            widget.empleado.nombreCompleto,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "ID: ${widget.empleado.id}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Estado del registro
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  hasBiometrics ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 48,
                  color: hasBiometrics ? Colors.green.shade600 : theme.colorScheme.primary,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  hasBiometrics 
                    ? "Registro Completado"
                    : "Sin Registro Biométrico",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasBiometrics ? Colors.green.shade700 : theme.colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  hasBiometrics
                    ? "Se registraron ${_existingBiometricUrls.length} imágenes biométricas"
                    : "Este empleado necesita completar su registro biométrico",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          if (hasBiometrics) ...[
            const SizedBox(height: 32),
            
            // Vista previa de imágenes
            Text(
              "Vista Previa",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _existingBiometricUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 0.8,
                        child: Image.network(
                          _existingBiometricUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            color: theme.colorScheme.errorContainer,
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          loadingBuilder: (c, child, progress) => progress == null
                              ? child
                              : Container(
                                  color: theme.colorScheme.surfaceVariant,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          
          // Botones de acción
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(hasBiometrics ? Icons.refresh_rounded : Icons.camera_alt_rounded),
              label: Text(
                hasBiometrics ? "ACTUALIZAR REGISTRO" : "INICIAR REGISTRO",
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              onPressed: _startCaptureProcess,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
          if (hasBiometrics) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                label: Text(
                  "Eliminar Registro",
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _showDeleteConfirmDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- VISTA DE CAPTURA ---
  Widget _buildCaptureView(ThemeData theme) {
    bool isFinished = _capturedImages.length == 3;
    return Column(
      children: [
        // Header de instrucciones
        SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                if (!isFinished) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _captureIcons[_captureStep],
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Paso ${_captureStep + 1} de 3",
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _capturePrompts[_captureStep],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _captureSubtitles[_captureStep],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "¡Captura Completa!",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              "Revisa las imágenes y guarda tu registro",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Indicador de progreso mejorado
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    bool isCaptured = index < _capturedImages.length;
                    bool isCurrent = index == _captureStep && !isFinished;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: isCurrent ? 60 : 50,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: isCaptured
                            ? LinearGradient(
                                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                              )
                            : null,
                        color: isCaptured 
                            ? null 
                            : theme.colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isCaptured ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        
        // Vista de cámara
        Expanded(
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_controller.isCameraInitialized && !isFinished)
                  CameraPreview(_controller.cameraController!),
                
                if (!isFinished) ...[
                  // Marco de guía con animación
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 280,
                          height: 350,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(180),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Puntos de referencia
                  Positioned(
                    top: 120,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
                
                if (isFinished)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _capturedImages.asMap().entries.map((entry) {
                        int idx = entry.key;
                        File file = entry.value;
                        return Hero(
                          tag: 'captured_image_$idx',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                file,
                                width: 90,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Controles inferiores
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: isFinished
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text("REINTENTAR"),
                        onPressed: _resetCapture,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_alt_rounded),
                        label: const Text("GUARDAR"),
                        onPressed: _saveBiometrics,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _capturePhoto,
                              borderRadius: BorderRadius.circular(40),
                              child: const Center(
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}