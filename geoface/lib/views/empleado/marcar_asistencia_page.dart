// <-- CAMBIO: Añadimos las importaciones para http y json
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geoface/services/firebase_service.dart';
import 'package:geoface/models/sede.dart';
import 'package:geoface/models/asistencia.dart';
import 'package:geoface/utils/location_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:geoface/controllers/asistencia_controller.dart';
import 'package:geoface/models/empleado.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
// import 'package:geoface/services/azure_face_service.dart'; // <-- CAMBIO: Ya no se necesita
import 'package:lottie/lottie.dart';

// <-- CAMBIO: Modificamos el enum para reflejar el nuevo flujo sin ingreso de DNI manual
enum MarcacionFlowState {
  inicializando,
  errorServicios,
  verificacionFacial,
  verificandoIdentidad, // Este estado ahora cubre la llamada a la API y la búsqueda en Firebase
  confirmacion,
  jornadaCompletada,
}

class MarcarAsistenciaPage extends StatefulWidget {
  const MarcarAsistenciaPage({super.key});

  @override
  State<MarcarAsistenciaPage> createState() => _MarcarAsistenciaPageState();
}

class _MarcarAsistenciaPageState extends State<MarcarAsistenciaPage>
    with WidgetsBindingObserver {
  // --- Estado y Controladores ---
  MarcacionFlowState _flowState = MarcacionFlowState.inicializando;
  CameraController? _cameraController;
  final TextEditingController _dniController = TextEditingController(); // Lo mantenemos para uso interno
  final FirebaseService _firebaseService = FirebaseService();
  // late AzureFaceService _azureFaceService; // <-- CAMBIO: Se elimina Azure

  // <-- CAMBIO: Añadimos la URL de nuestra API de Colab
  final String _recognitionApiUrl = "https://5758-34-125-156-88.ngrok-free.app/identificar";


  // --- Datos del Flujo ---
  Empleado? _empleado;
  Sede? _sede;
  Asistencia? _asistenciaDelDia;
  Position? _currentPosition;
  bool _isDentroDelRadio = false;
  bool _esEntrada = true;
  bool _isFaceVerified = false;
  Uint8List? _capturedImageBytes;

  // --- Banderas de estado ---
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Preparando servicios...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _azureFaceService = ...; // <-- CAMBIO: Se elimina la inicialización de Azure
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _dniController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE INICIALIZACIÓN Y FLUJO ---

  Future<void> _initializeServices() async {
    // ... (sin cambios aquí)
    try {
      await Future.wait([_initializeCamera(), _getCurrentLocation()]);
      if (!mounted) return;
      setState(() {
        _flowState = MarcacionFlowState.verificacionFacial;
        _statusMessage = "Servicios listos.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _flowState = MarcacionFlowState.errorServicios;
        _statusMessage = e.toString();
      });
    }
  }

  // <-- CAMBIO: REEMPLAZAMOS COMPLETAMENTE LA FUNCIÓN DE VERIFICACIÓN FACIAL
  Future<void> _handleFaceVerification() async {
    if (_isProcessing || !_isCameraInitialized || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _flowState = MarcacionFlowState.verificandoIdentidad;
      _statusMessage = "Identificando rostro...";
    });

    try {
      // 1. Tomar y procesar la foto
      final XFile photoFile = await _cameraController!.takePicture();
      _capturedImageBytes = await _processImageToBytes(photoFile);

      // 2. Preparar y enviar la petición
      var request = http.MultipartRequest('POST', Uri.parse(_recognitionApiUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'face_image',
          _capturedImageBytes!,
          filename: 'face_capture.jpg',
        ),
      );
      
      // Añadimos un timeout para manejar servidores lentos o caídos
      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      // 3. Procesar la respuesta del servidor
      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        // --- CASO DE ÉXITO ---
        final String? empleadoId = data['empleadoId'];
        if (empleadoId == null || !mounted) {
          throw Exception("Respuesta exitosa pero sin ID de empleado.");
        }
        await _handleIdentityVerification(empleadoId: empleadoId);

      } else {
        // --- CASOS DE ERROR CONTROLADOS POR LA API (statusCode 404, etc.) ---
        final String errorMessage = data['error'] ?? "Error desconocido.";

        if (errorMessage.contains("Desconocido")) {
          // El rostro fue detectado pero no coincide con nadie
          _showCustomInfoDialog(
            title: "Empleado No Registrado",
            content: "Tu rostro fue detectado, pero no te encontramos en nuestra base de datos. Por favor, contacta a Recursos Humanos si crees que esto es un error.",
            lottieAsset: 'assets/animations/not-found.json', // <-- Necesitarás una animación para esto
          );
        } else if (errorMessage.contains("No se detectó un rostro")) {
          // La calidad de la imagen es mala
          _showCustomInfoDialog(
            title: "Rostro No Detectado",
            content: "No pudimos encontrar un rostro claro en la foto. Asegúrate de tener buena iluminación, mirar de frente a la cámara y no tener el rostro cubierto.",
            lottieAsset: 'assets/animations/bad-quality.json', // <-- Necesitarás una animación para esto
          );
        } else {
          // Otro error enviado por la API
          _showCustomInfoDialog(
            title: "Error de Verificación",
            content: errorMessage,
            lottieAsset: 'assets/animations/not-found.json',
          );
        }
        
        // En cualquier caso de error controlado, volvemos a la cámara
        if (mounted) {
          setState(() {
            _flowState = MarcacionFlowState.verificacionFacial;
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      // --- CASO DE ERROR DE CONEXIÓN O TIMEOUT ---
      // Esto se activa si el servidor está apagado, no hay internet, o la petición tarda demasiado.
      _showCustomInfoDialog(
        title: "Servicio en Mantenimiento",
        content: "No pudimos conectar con el servicio de reconocimiento facial. Por favor, inténtalo de nuevo más tarde o revisa tu conexión a internet.",
        lottieAsset: 'assets/animations/maintenance.json', // <-- Necesitarás una animación para esto
      );
      if (mounted) {
        setState(() {
          _flowState = MarcacionFlowState.verificacionFacial;
          _isProcessing = false;
        });
      }
    }
  }

  // <-- CAMBIO: REEMPLAZA TU DIÁLOGO DE INFO POR ESTE, MÁS VISUAL Y VERSÁTIL
  void _showCustomInfoDialog({
    required String title,
    required String content,
    required String lottieAsset,
  }) {
    if (!mounted) return;

    // Pequeña validación por si el archivo lottie no existe
    final assetExists = true; // En un proyecto real, podrías verificar si el archivo existe
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetExists)
              SizedBox(
                width: 120,
                height: 120,
                child: Lottie.asset(lottieAsset, repeat: false),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text("Entendido"),
          )
        ],
      ),
    );
  }

  
  Future<Uint8List> _processImageToBytes(XFile photoFile) async {
    // ... (sin cambios aquí)
    final bytes = await photoFile.readAsBytes();
    final imgLib = img.decodeImage(bytes);
    if (imgLib == null) throw Exception("No se pudo decodificar la imagen");
    final resizedImg = img.copyResize(imgLib, width: 640);
    return Uint8List.fromList(img.encodeJpg(resizedImg, quality: 90));
  }

  // <-- CAMBIO: MODIFICAMOS ESTA FUNCIÓN PARA QUE ACEPTE UN ID DIRECTAMENTE
  Future<void> _handleIdentityVerification({String? empleadoId}) async {
    // El estado ya se cambió en la función anterior.
    // Solo actualizamos el mensaje.
    if(mounted) setState(() => _statusMessage = "Verificando datos de jornada...");

    try {
      if (empleadoId == null) throw Exception("ID de empleado no proporcionado.");
      
      // 1. Verificar empleado usando el ID
      _empleado = await _firebaseService.getEmpleadoById(empleadoId);
      if (_empleado == null) throw Exception("Empleado reconocido (ID: $empleadoId), pero no encontrado en la base de datos.");

      if (_empleado!.activo != true) {
        throw Exception("Este empleado no se encuentra activo. Contacte a RR.HH.");
      }
      
      _dniController.text = _empleado!.dni; // Guardamos el DNI para mostrarlo
      _isFaceVerified = true; // El rostro se verificó con éxito

      // El resto de la lógica es la misma que ya tenías...
      // 2. Verificar sede
      _sede = await _firebaseService.getSedeById(_empleado!.sedeId);
      if (_sede == null) throw Exception("La sede asignada no fue encontrada.");
      
      if (_sede!.activa != true) {
        throw Exception("La sede '${_sede!.nombre}' no se encuentra activa.");
      }

      // 3. Verificar estado de asistencia
      final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);
      final status = await asistenciaController.checkEmpleadoAsistenciaStatus(_empleado!.id);
      
      switch (status) {
        case AsistenciaStatus.debeMarcarEntrada:
          _esEntrada = true;
          _asistenciaDelDia = null;
          break;
        case AsistenciaStatus.debeMarcarSalida:
          _esEntrada = false;
          _asistenciaDelDia = asistenciaController.asistenciaActiva;
          break;
        case AsistenciaStatus.jornadaCompleta:
          _asistenciaDelDia = await _firebaseService.getCompletedAsistenciaForToday(_empleado!.id);
          setState(() => _flowState = MarcacionFlowState.jornadaCompletada);
          return;
        case AsistenciaStatus.error:
          throw Exception(asistenciaController.errorMessage ?? "Error al verificar estado de asistencia");
      }

      // 4. Verificar ubicación
      final distancia = LocationHelper.calcularDistancia(
        _currentPosition!.latitude, _currentPosition!.longitude, 
        _sede!.latitud, _sede!.longitud
      );
      _isDentroDelRadio = distancia <= _sede!.radioPermitido;
      
      setState(() => _flowState = MarcacionFlowState.confirmacion);

    } catch (e) {
      // Si algo falla aquí, volvemos a la cámara para que reintente
      _showInfoDialog("Error de Verificación", e.toString(), Icons.error, Colors.red);
      setState(() => _flowState = MarcacionFlowState.verificacionFacial);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleMarkAttendance() async {
    // ... (sin cambios aquí)
    setState(() => _isProcessing = true);
    final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);

    // TODO: Subir _capturedImageBytes a Firebase Storage y obtener URL.
    final String capturaString = "face_capture_placeholder";

    try {
      bool success;
      if (_esEntrada) {
        success = await asistenciaController.registrarEntrada(
          empleadoId: _empleado!.id, 
          sedeId: _empleado!.sedeId, 
          capturaEntrada: capturaString
        );
      } else {
        success = await asistenciaController.registrarSalida(
          empleadoId: _empleado!.id,
          capturaSalida: capturaString
        );
      }

      if (success) {
        _showSuccessDialog();
      } else {
        throw Exception(asistenciaController.errorMessage ?? "Ocurrió un error desconocido al registrar.");
      }

    } catch (e) {
      _showInfoDialog("Error al Marcar", e.toString(), Icons.error, Colors.red);
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }
  
  // --- Manejo del ciclo de vida y permisos (sin cambios) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_flowState == MarcacionFlowState.verificacionFacial) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    // ... (sin cambios aquí)
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No hay cámaras disponibles.");
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }
  
  Future<void> _getCurrentLocation() async {
    // ... (sin cambios aquí)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Los servicios de ubicación están desactivados.");
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception("Permiso de ubicación denegado.");
    }
    if (permission == LocationPermission.deniedForever) throw Exception("Permiso de ubicación denegado permanentemente.");
    
    _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Registro de Asistencia'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: _buildCurrentView(),
          ),
        ),
      ),
    );
  }

  // <-- CAMBIO: Actualizamos el constructor de vistas para el nuevo flujo
  Widget _buildCurrentView() {
    switch (_flowState) {
      case MarcacionFlowState.inicializando:
      case MarcacionFlowState.errorServicios:
        return _buildInitialOrErrorView(key: ValueKey(_flowState));

      case MarcacionFlowState.verificacionFacial:
        return _buildCameraView(key: const ValueKey('camera'));

      case MarcacionFlowState.verificandoIdentidad:
        // Mostramos una vista de carga mientras la API y Firebase trabajan
        return _buildProcessingView(key: const ValueKey('processing'));
      
      // Se elimina el caso de ingresoDNI

      case MarcacionFlowState.confirmacion:
      case MarcacionFlowState.jornadaCompletada:
        return _buildConfirmationView(key: const ValueKey('confirmation'));
      }
  }

  // --- Widgets de construcción de vistas ---
  Widget _buildInitialOrErrorView({required Key key}) {
    bool isError = _flowState == MarcacionFlowState.errorServicios;
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isError)
          Lottie.asset('assets/animations/loading.json', width: 150, height: 150)
        else
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
        const SizedBox(height: 24),
        Text(isError ? 'Ocurrió un Error' : 'Preparando Cámara y GPS...', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(_statusMessage, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        if (isError) OutlinedButton.icon(onPressed: _initializeServices, icon: const Icon(Icons.refresh), label: const Text("Reintentar")),
      ],
    );
  }
  
  // <-- CAMBIO: Añadimos una nueva vista de "Procesando"
  Widget _buildProcessingView({required Key key}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/animations/face-detection.json', width: 150, height: 150),
        const SizedBox(height: 24),
        Text(
          _statusMessage,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Por favor, espera un momento...",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }


  Widget _buildCameraView({required Key key}) {
    return Column(
      key: key,
      children: [
        // <-- CAMBIO: Actualizamos el mensaje
        _buildStepCard(
          icon: Icons.camera_alt_outlined,
          title: "Reconocimiento Facial",
          message: "Coloca tu rostro en el centro del marco y presiona el botón para marcar tu asistencia.",
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 24),
        Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 2)
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: (_isCameraInitialized && _cameraController != null)
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 24),
        // <-- CAMBIO: Actualizamos el texto del botón
        _buildActionButton(
          label: "Identificar y Marcar Asistencia",
          onPressed: _handleFaceVerification,
          icon: Icons.face_retouching_natural,
          isLoading: _isProcessing
        ),
      ],
    );
  }
  
      
  Widget _buildConfirmationView({required Key key}) {
    
    bool jornadaCompleta = _flowState == MarcacionFlowState.jornadaCompletada;

    return Column(
      key: key,
      children: [
        _buildEmpleadoInfoCard(),
        const SizedBox(height: 24),
        
        if (jornadaCompleta)
          _buildStatusCard(
            title: 'Jornada Finalizada por Hoy',
            icon: Icons.check_circle,
            color: Colors.teal,
            children: [
              Text(
                "Ya has registrado tu entrada y salida el día de hoy. ¡Buen trabajo!",
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.login, 'Hora de Entrada', DateFormat('hh:mm a').format(_asistenciaDelDia!.fechaHoraEntrada)),
              _buildInfoRow(Icons.logout, 'Hora de Salida', DateFormat('hh:mm a').format(_asistenciaDelDia!.fechaHoraSalida!)),
            ],
          )
        else
          _buildStatusCard(
            title: _esEntrada ? 'Listo para Marcar Entrada' : 'Listo para Marcar Salida',
            icon: _esEntrada ? Icons.login : Icons.logout,
            color: _esEntrada ? Colors.green : Colors.orange,
            children: [
              _buildStatusCheckRow(
                  label: "Reconocimiento Facial", 
                  success: _isFaceVerified,
                  icon: Icons.face_retouching_natural
              ),
              _buildStatusCheckRow(
                  label: "Ubicación de Sede", 
                  success: _isDentroDelRadio,
                  icon: Icons.location_on_outlined
              ),
              _buildStatusCheckRow(
                  label: "Fecha y Hora", 
                  success: true,
                  icon: Icons.today_outlined,
                  value: DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
              ),
            ],
          ),
        const SizedBox(height: 32),

        if (!jornadaCompleta)
          _buildActionButton(
            label: _esEntrada ? "Confirmar Entrada" : "Confirmar Salida",
            onPressed: _isDentroDelRadio && _isFaceVerified ? _handleMarkAttendance : null,
            icon: Icons.check_circle_outline,
            color: _esEntrada ? Colors.green : Colors.orange,
            isLoading: _isProcessing,
          ),
      ],
    );
  }
  
  // --- El resto de los widgets de componentes reutilizables no necesitan cambios ---
  
  Widget _buildStepCard({required IconData icon, required String title, required String message, required Color color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: color.withOpacity(0.9))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Divider(height: 24),
            ...children
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCheckRow({
    required String label,
    required bool success,
    required IconData icon,
    String? value,
  }) {
    final Color color = success ? Colors.green.shade700 : Colors.red.shade700;
    final IconData statusIcon = success ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Icon(statusIcon, color: color, size: 20),
                  ],
                ),
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButton({required String label, VoidCallback? onPressed, required IconData icon, Color? color, bool isLoading = false}) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: effectiveOnPressed,
        icon: isLoading ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text("$label:", style: TextStyle(color: Colors.grey.shade700)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]
      ),
    );
  }

  Widget _buildEmpleadoInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              _empleado?.nombreCompleto ?? "N/A",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "DNI: ${_empleado?.dni ?? 'N/A'}",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.work_outline, "Cargo", _empleado?.cargo ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.business_outlined, "Sede", _sede?.nombre ?? 'N/A'),
          ],
        ),
      ),
    );
  }


  void _showInfoDialog(String title, String content, IconData icon, Color color) {
    // ... (sin cambios aquí)
    if (!mounted) return;
    showDialog(context: context, builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title)]), 
        content: Text(content), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar"))
        ]));
  }
  
  void _showSuccessDialog() {
    // ... (sin cambios aquí)
    if (!mounted) return;
    showDialog(barrierDismissible: false, context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 28), SizedBox(width: 12), Text("¡Éxito!")]),
      content: const Text("Tu asistencia ha sido registrada correctamente."),
      actions: [
        FilledButton(onPressed: () {
          Navigator.of(context)..pop()..pop();
        }, child: const Text("Finalizar"))
      ]));
  }
}