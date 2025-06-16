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
import 'package:image/image.dart' as img; // Para procesar la imagen
import 'dart:typed_data'; // Para Uint8List
import 'package:geoface/services/azure_face_service.dart'; // CAMBIO: Importar Azure Service
import 'package:lottie/lottie.dart'; // CAMBIO: Importar Lottie

// Enum para un control más claro del flujo de la UI
enum MarcacionFlowState {
  inicializando,
  errorServicios,
  verificacionFacial,
  ingresoDNI,
  verificandoIdentidad,
  confirmacion,
  jornadaCompletada,
}

class MarcarAsistenciaPage extends StatefulWidget {
  const MarcarAsistenciaPage({super.key});

  @override
  State<MarcarAsistenciaPage> createState() => _MarcarAsistenciaPageState();
}

class _MarcarAsistenciaPageState extends State<MarcarAsistenciaPage> with WidgetsBindingObserver {
  // --- Estado y Controladores ---
  MarcacionFlowState _flowState = MarcacionFlowState.inicializando;
  CameraController? _cameraController;
  final TextEditingController _dniController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  // CAMBIO: Instanciar AzureFaceService
  late AzureFaceService _azureFaceService;

  // --- Datos del Flujo ---
  Empleado? _empleado;
  Sede? _sede;
  Asistencia? _asistenciaDelDia;
  Position? _currentPosition;
  bool _isDentroDelRadio = false;
  bool _esEntrada = true;

  // --- Banderas de estado ---
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Preparando servicios...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // CAMBIO: Inicializar el servicio de Azure con tus credenciales
    _azureFaceService = AzureFaceService(
      azureEndpoint: 'https://geofaceid.cognitiveservices.azure.com',
      apiKey: 'lA9d0Yecp7LtWRVvumio95p7Ih5BYKYGzvqI3S5A6rN1823aQ8XxJQQJ99BEACYeBjFXJ3w3AAAKACOGvSQn',
    );
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
    try {
      await Future.wait([_initializeCamera(), _getCurrentLocation()]);
      setState(() {
        _flowState = MarcacionFlowState.verificacionFacial;
        _statusMessage = "Servicios listos.";
      });
    } catch (e) {
      setState(() {
        _flowState = MarcacionFlowState.errorServicios;
        _statusMessage = e.toString();
      });
    }
  }

  // CAMBIO: Lógica real de verificación facial
  Future<void> _handleFaceVerification() async {
    if (_isProcessing || !_isCameraInitialized) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final XFile photoFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await _processImageToBytes(photoFile);
      
      bool rostroDetectado = await _azureFaceService.detectarRostroEnImagen(imageBytes);

      if (rostroDetectado) {
        if (mounted) {
          setState(() {
            _flowState = MarcacionFlowState.ingresoDNI;
            _cameraController?.dispose(); // Liberamos la cámara
          });
        }
      } else {
        _showInfoDialog(
          "Rostro no Detectado",
          "No se pudo detectar un rostro en la imagen. Por favor, asegúrate de que tu cara esté bien iluminada y centrada en el marco.",
          Icons.sentiment_very_dissatisfied,
          Colors.orange,
        );
      }
    } catch (e) {
      _showInfoDialog(
        "Error de Verificación",
        "Ocurrió un error al contactar con el servicio de reconocimiento facial. Revisa tu conexión a internet.",
        Icons.cloud_off,
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  
  // --- Método de ayuda para procesar la imagen (necesario para Azure) ---
  Future<Uint8List> _processImageToBytes(XFile photoFile) async {
    final bytes = await photoFile.readAsBytes();
    final imgLib = img.decodeImage(bytes);
    if (imgLib == null) throw Exception("No se pudo decodificar la imagen");
    // Redimensionar si es necesario para optimizar la subida
    final resizedImg = img.copyResize(imgLib, width: 640);
    return Uint8List.fromList(img.encodeJpg(resizedImg, quality: 90));
  }

  Future<void> _handleIdentityVerification() async {
    if (_isProcessing || _dniController.text.trim().isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _flowState = MarcacionFlowState.verificandoIdentidad;
    });

    try {
      final dni = _dniController.text.trim();
      
      _empleado = await _firebaseService.getEmpleadoByDNI(dni);
      if (_empleado == null) throw Exception("No se encontró empleado con DNI $dni.");

      final asistenciaCompleta = await _firebaseService.getCompletedAsistenciaForToday(_empleado!.id);
      if (asistenciaCompleta != null) {
        _asistenciaDelDia = asistenciaCompleta;
        setState(() => _flowState = MarcacionFlowState.jornadaCompletada);
        return;
      }

      final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);
      await asistenciaController.checkAsistenciaActiva(_empleado!.id);
      _asistenciaDelDia = asistenciaController.asistenciaActiva;
      _esEntrada = _asistenciaDelDia == null;

      _sede = await _firebaseService.getSedeById(_empleado!.sedeId);
      if (_sede == null) throw Exception("Sede del empleado no encontrada.");

      final distancia = LocationHelper.calcularDistancia(
        _currentPosition!.latitude, _currentPosition!.longitude, _sede!.latitud, _sede!.longitud
      );
      _isDentroDelRadio = distancia <= _sede!.radioPermitido;

      if (!_isDentroDelRadio) {
        _showInfoDialog(
          "Fuera de Rango",
          "Estás a ${distancia.toStringAsFixed(0)}m de la sede '${_sede!.nombre}'.\n\nDebes estar dentro de los ${_sede!.radioPermitido}m para poder marcar.",
          Icons.location_off,
          Colors.orange
        );
      }
      
      setState(() => _flowState = MarcacionFlowState.confirmacion);

    } catch (e) {
      _showInfoDialog("Error de Verificación", e.toString(), Icons.error, Colors.red);
      setState(() => _flowState = MarcacionFlowState.ingresoDNI);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleMarkAttendance() async {
    setState(() => _isProcessing = true);
    final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);

    try {
      bool success;
      if (_esEntrada) {
        success = await asistenciaController.registrarEntrada(
          empleadoId: _empleado!.id, 
          sedeId: _empleado!.sedeId, 
          capturaEntrada: "face_capture_placeholder"
        );
      } else {
        success = await asistenciaController.registrarSalida(
          asistenciaId: _asistenciaDelDia!.id,
          capturaSalida: "face_capture_placeholder"
        );
      }

      if (success) {
        _showSuccessDialog();
      } else {
        throw Exception(asistenciaController.errorMessage ?? "Ocurrió un error desconocido.");
      }

    } catch (e) {
      _showInfoDialog("Error al Marcar", e.toString(), Icons.error, Colors.red);
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_flowState == MarcacionFlowState.verificacionFacial) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
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

  // --- UI & WIDGETS ---

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
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_flowState) {
      case MarcacionFlowState.inicializando:
      case MarcacionFlowState.errorServicios:
        return _buildInitialOrErrorView();
      case MarcacionFlowState.verificacionFacial:
        return _buildCameraView(key: const ValueKey('camera'));
      case MarcacionFlowState.ingresoDNI:
      case MarcacionFlowState.verificandoIdentidad:
        return _buildDniInputView(key: const ValueKey('dni'));
      case MarcacionFlowState.confirmacion:
      case MarcacionFlowState.jornadaCompletada:
        return _buildConfirmationView(key: const ValueKey('confirmation'));
      }
  }

  Widget _buildInitialOrErrorView() {
    bool isError = _flowState == MarcacionFlowState.errorServicios;
    return Column(
      key: ValueKey(isError ? 'error' : 'loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // CAMBIO: Usar Lottie en lugar de Icon
        if (!isError)
          Lottie.asset(
            'assets/animations/loading.json',
            width: 150,
            height: 150,
          )
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

  Widget _buildCameraView({required Key key}) {
    return Column(
      key: key,
      children: [
        _buildStepCard(
          icon: Icons.camera_alt_outlined,
          title: "Paso 1: Verificación Facial",
          message: "Coloca tu rostro en el centro del marco para asegurar que eres tú.",
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
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: "Verificar Rostro",
          onPressed: _handleFaceVerification,
          icon: Icons.face_retouching_natural,
          isLoading: _isProcessing
        ),
      ],
    );
  }
  
  Widget _buildDniInputView({required Key key}) {
     return Column(
      key: key,
      children: [
        _buildStepCard(
          icon: Icons.badge_outlined,
          title: "Paso 2: Identificación",
          message: "Ingresa tu número de DNI para buscar tu perfil y verificar tu jornada.",
          color: Colors.deepPurpleAccent,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _dniController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Número de DNI',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person_search_outlined),
          ),
          onSubmitted: (_) => _handleIdentityVerification(),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: "Verificar Identidad",
          onPressed: _handleIdentityVerification,
          icon: Icons.arrow_forward_ios,
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  Widget _buildConfirmationView({required Key key}) {
    bool jornadaCompleta = _flowState == MarcacionFlowState.jornadaCompletada;

    return Column(
      key: key,
      children: [
        Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(_empleado?.nombreCompleto ?? "N/A", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("DNI: ${_empleado?.dni ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
                const Divider(height: 32),
                _buildInfoRow(Icons.work_outline, "Cargo", _empleado?.cargo ?? 'N/A'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.business_outlined, "Sede", _sede?.nombre ?? 'N/A'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        _buildStatusCard(
          title: jornadaCompleta
            ? 'Jornada Finalizada'
            : (_esEntrada ? 'Listo para Marcar Entrada' : 'Listo para Marcar Salida'),
          icon: jornadaCompleta
            ? Icons.check_circle_outline
            : (_esEntrada ? Icons.login : Icons.logout),
          color: jornadaCompleta
            ? Colors.teal
            : (_esEntrada ? Colors.green : Colors.orange),
          children: [
            if (jornadaCompleta && _asistenciaDelDia != null)
              _buildInfoRow(Icons.access_time, 'Entrada', DateFormat('hh:mm a').format(_asistenciaDelDia!.fechaHoraEntrada)),
            if (jornadaCompleta && _asistenciaDelDia != null)
              _buildInfoRow(Icons.access_time_filled, 'Salida', DateFormat('hh:mm a').format(_asistenciaDelDia!.fechaHoraSalida!)),
            if(!jornadaCompleta)
              _buildLocationStatus(),
          ],
        ),
        const SizedBox(height: 24),

        if (!jornadaCompleta)
          _buildActionButton(
            label: _esEntrada ? "Marcar Entrada" : "Marcar Salida",
            onPressed: _isDentroDelRadio ? _handleMarkAttendance : null,
            icon: _esEntrada ? Icons.login : Icons.logout,
            color: _esEntrada ? Colors.green : Colors.orange,
            isLoading: _isProcessing,
          ),
      ],
    );
  }
  
  // --- WIDGETS DE COMPONENTES REUTILIZABLES ---
  
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
  
  Widget _buildLocationStatus() {
    return Row(
      children: [
        Icon(
          _isDentroDelRadio ? Icons.check_circle : Icons.highlight_off,
          color: _isDentroDelRadio ? Colors.green : Colors.red,
          size: 20
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isDentroDelRadio ? 'Ubicación Verificada' : 'Fuera del Radio Permitido',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isDentroDelRadio ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ),
      ],
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

  // --- DIÁLOGOS DE FEEDBACK ---
  void _showInfoDialog(String title, String content, IconData icon, Color color) {
    showDialog(context: context, builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(title)]), 
        content: Text(content), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar"))
        ]));
  }
  
  void _showSuccessDialog() {
    showDialog(barrierDismissible: false, context: context, builder: (context) => AlertDialog(
      // AQUÍ ESTABA EL ERROR
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