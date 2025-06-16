import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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

class _RegistroBiometricoScreenState extends State<RegistroBiometricoScreen> with WidgetsBindingObserver {
  late BiometricoController _controller;
  bool _isLoading = false;
  bool _hasExistingBiometric = false;
  String? _biometricoId;
  String? _biometricoUrl;
  bool _showPreview = true;
  bool _isCameraActive = false;
  
  // Para seleccionar imágenes de la galería
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Provider.of<BiometricoController>(context, listen: false);
    
    // Inicializar después del build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
      
      // Verificar biométricos existentes
      _checkExistingBiometric();
    });
  }

  @override
  void dispose() {
    // Asegurar que la cámara se detenga de manera limpia
    _disposeCamera();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Método para disponer de la cámara correctamente
  Future<void> _disposeCamera() async {
    try {
      if (_isCameraActive) {
        await _controller.stopCamera();
        _isCameraActive = false;
      }
    } catch (e) {
      debugPrint('Error al disponer de la cámara: ${e.toString()}');
    }
  }
  
  @override
  void didUpdateWidget(RegistroBiometricoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si cambió el empleado, actualizar datos
    if (oldWidget.empleado.id != widget.empleado.id) {
      // Reiniciar estado
      setState(() {
        _hasExistingBiometric = false;
        _biometricoId = null;
        _biometricoUrl = null;
        _selectedImageFile = null;
      });
      
      // Verificar biométricos para el nuevo empleado
      _checkExistingBiometric();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manejar cambios en el ciclo de vida de la app
    if (state == AppLifecycleState.resumed) {
      if (_showPreview && !_isCameraActive) {
        _initController();
      }
    } else if (state == AppLifecycleState.inactive ||
               state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached) {
      _disposeCamera();
    }
  }

  // Inicializar cámara con mejor manejo de errores
  Future<void> _initController() async {
    try {
      if (_isCameraActive) return; // Evitar inicialización múltiple
      
      setState(() => _isLoading = true);
      await _controller.initCamera();
      _isCameraActive = true;
    } catch (e) {
      debugPrint('Error al inicializar la cámara: ${e.toString()}');
      _showErrorDialog('Error al inicializar', 
        'No se pudo inicializar la cámara. Por favor, intenta de nuevo.');
      _isCameraActive = false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Verificar si el empleado ya tiene un biométrico registrado
  Future<void> _checkExistingBiometric() async {
    try {
      setState(() => _isLoading = true);
      
      final biometrico = await _controller.getBiometricoByEmpleadoId(widget.empleado.id);
      
      if (mounted) {
        setState(() {
          _hasExistingBiometric = biometrico != null;
          _biometricoId = biometrico?.id;
          _biometricoUrl = biometrico?.datoFacial;
        });
      }
      
    } catch (e) {
      debugPrint('Error al verificar biométrico: ${e.toString()}');
      if (mounted) {
        setState(() {
          _hasExistingBiometric = false;
          _biometricoId = null;
          _biometricoUrl = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Seleccionar imagen de la galería con mejor manejo de cámara
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      
      // Detener la cámara antes de seleccionar imagen
      await _disposeCamera();
      
      // Seleccionar imagen de la galería
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _showPreview = false;
        });
      } else if (_showPreview && mounted) {
        // Solo reiniciar la cámara si estamos en modo previsualización
        await _initController();
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen: ${e.toString()}');
      _showErrorDialog('Error', 'No se pudo seleccionar la imagen. Intenta de nuevo.');
      // Reintentar iniciar cámara si estábamos en modo previsualización
      if (_showPreview && mounted) {
        await _initController();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Capturar y guardar biométrico con mejor manejo de errores
  Future<void> _captureAndSaveBiometric() async {
    try {
      setState(() => _isLoading = true);
      
      bool result = false;
      
      if (_selectedImageFile != null) {
        // Usar imagen seleccionada de la galería
        if (_hasExistingBiometric && _biometricoId != null) {
          // Actualizar con imagen de galería
          result = await _controller.updateBiometricoWithFile(
            _biometricoId!, 
            widget.empleado.id, 
            _selectedImageFile!
          );
        } else {
          // Crear nuevo con imagen de galería
          result = await _controller.registerBiometricoWithFile(
            widget.empleado.id, 
            _selectedImageFile!
          );
        }
      } else {
        // Asegurar que la cámara esté inicializada
        if (!_controller.isCameraInitialized) {
          _showErrorDialog('Error', 'La cámara no está inicializada. Intenta de nuevo.');
          return;
        }
        
        // Usar la cámara
        if (_hasExistingBiometric && _biometricoId != null) {
          // Actualizar biométrico existente
          result = await _controller.updateBiometrico(_biometricoId!, widget.empleado.id);
        } else {
          // Crear nuevo biométrico
          result = await _controller.registerBiometrico(widget.empleado.id);
        }
      }
      
      if (result && mounted) {
        // Si fue exitoso, mostrar mensaje y actualizar estado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biométrico registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar imagen seleccionada
        setState(() {
          _selectedImageFile = null;
          _showPreview = true;
        });
        
        // Reiniciar la cámara si estábamos en preview
        if (_showPreview) {
          await _initController();
        }
        
        // Refrescar para obtener el ID y URL del biométrico nuevo
        await _checkExistingBiometric();
      } else if (mounted) {
        // Si hubo error, mostrar mensaje de error
        _showErrorDialog('Error', _controller.errorMessage ?? 'No se pudo guardar el biométrico');
      }
      
    } catch (e) {
      debugPrint('Error al procesar imagen: ${e.toString()}');
      _showErrorDialog('Error', 'Error al procesar imagen. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Eliminar biométrico con mejor manejo de errores
  Future<void> _deleteBiometric() async {
    if (_biometricoId == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      final result = await _controller.deleteBiometrico(_biometricoId!, widget.empleado.id);
      
      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biométrico eliminado correctamente'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Actualizar estado después de eliminación
        setState(() {
          _hasExistingBiometric = false;
          _biometricoId = null;
          _biometricoUrl = null;
        });
      } else if (mounted) {
        _showErrorDialog('Error', _controller.errorMessage ?? 'No se pudo eliminar el biométrico');
      }
      
    } catch (e) {
      debugPrint('Error al eliminar biométrico: ${e.toString()}');
      _showErrorDialog('Error', 'Error al eliminar biométrico. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Alternar entre cámara y biométrico existente con mejor manejo
  Future<void> _togglePreview() async {
    if (_hasExistingBiometric && _biometricoUrl != null) {
      // Primero detener la cámara si está activa antes de cambiar estado
      if (_showPreview) {
        await _disposeCamera();
      }
      
      setState(() {
        _showPreview = !_showPreview;
        _selectedImageFile = null;
      });
      
      // Iniciar la cámara si cambiamos a modo preview
      if (_showPreview) {
        await _initController();
      }
    }
  }

  // Mostrar diálogo de error
  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de confirmación para eliminar
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar biométrico'),
        content: const Text('¿Estás seguro de que deseas eliminar el registro biométrico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBiometric();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Asegurar limpieza al salir
      onWillPop: () async {
        await _disposeCamera();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registro Biométrico'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 2,
          actions: [
            if (_hasExistingBiometric && _biometricoUrl != null)
              IconButton(
                icon: Icon(_showPreview ? Icons.photo : Icons.camera_alt),
                tooltip: _showPreview ? 'Ver biométrico actual' : 'Usar cámara',
                onPressed: _togglePreview,
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildEmployeeInfoBar(),
                  Expanded(
                    child: _buildMediaSection(),
                  ),
                  _buildStatusBar(),
                  _buildActionButtons(),
                ],
              ),
              // Capa de carga con Lottie
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.asset(
                        'assets/animations/loading.json',
                        animate: true,
                        repeat: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Información del empleado en la parte superior
  Widget _buildEmployeeInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            child: Text(
              widget.empleado.nombreCompleto.isNotEmpty 
                  ? widget.empleado.nombreCompleto[0].toUpperCase() 
                  : '?',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.empleado.nombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${widget.empleado.id}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sección principal (cámara o imagen) optimizada
  Widget _buildMediaSection() {
    // Si tenemos una imagen seleccionada, mostrarla
    if (_selectedImageFile != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Image.file(
              _selectedImageFile!,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () async {
                  setState(() {
                    _selectedImageFile = null;
                    _showPreview = true;
                  });
                  await _initController(); // Reiniciar la cámara
                },
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Imagen seleccionada de la galería',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // Si no estamos mostrando la previsualización pero tenemos biométrico, mostrar la imagen actual
    if (!_showPreview && _biometricoUrl != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Image.network(
              _biometricoUrl!,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error cargando imagen: $error');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar imagen',
                        style: TextStyle(color: Colors.red[300]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Biométrico registrado actual',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // Por defecto, mostrar la cámara con mejor manejo de errores
    return Consumer<BiometricoController>(
      builder: (context, controller, _) {
        if (!controller.isCameraInitialized) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.asset(
                    'assets/animations/loading.json',
                    animate: true,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Inicializando cámara...'),
              ],
            ),
          );
        }
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Vista previa de la cámara
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: controller.cameraController != null && controller.cameraController!.value.isInitialized
                ? ClipRRect(
                    child: AspectRatio(
                      aspectRatio: controller.cameraController?.value.aspectRatio ?? 1.0,
                      child: CameraPreview(controller.cameraController!),
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        'Cámara no disponible',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
            ),
            
            // Marco guía para la cara
            Container(
              width: 240,
              height: 290,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
            
            // Texto de instrucción
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Coloca tu rostro dentro del óvalo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Barra de estado
  Widget _buildStatusBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hasExistingBiometric 
                  ? Colors.green.withOpacity(0.2) 
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _hasExistingBiometric ? Icons.check_circle : Icons.face,
              color: _hasExistingBiometric ? Colors.green : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasExistingBiometric
                      ? 'Biométrico registrado'
                      : 'No hay biométrico registrado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _hasExistingBiometric ? Colors.green : Colors.blue,
                    fontSize: 14,
                  ),
                ),
                if (_biometricoId != null)
                  Text(
                    'ID: ${_biometricoId!.length > 8 ? _biometricoId!.substring(0, 8) + '...' : _biometricoId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedImageFile == null) // Solo mostrar cuando no hay imagen seleccionada
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.photo_library),
                color: Theme.of(context).primaryColor,
                tooltip: 'Seleccionar de galería',
                onPressed: _pickImage,
              ),
            ),
        ],
      ),
    );
  }

  // Botones de acción
  Widget _buildActionButtons() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botón principal: Registrar o Actualizar
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _captureAndSaveBiometric, // Deshabilitar durante carga
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasExistingBiometric ? Colors.blue : Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasExistingBiometric ? Icons.update : Icons.add_a_photo,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _hasExistingBiometric ? 'ACTUALIZAR BIOMÉTRICO' : 'REGISTRAR BIOMÉTRICO',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Si hay biométrico, mostrar botón eliminar
          if (_hasExistingBiometric)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _showDeleteConfirmDialog, // Deshabilitar durante carga
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.delete_forever, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'ELIMINAR BIOMÉTRICO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}