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
import 'package:geoface/services/azure_face_service.dart';
import 'package:lottie/lottie.dart';

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
  late AzureFaceService _azureFaceService;

  // --- Datos del Flujo ---
  Empleado? _empleado;
  Sede? _sede;
  Asistencia? _asistenciaDelDia;
  Position? _currentPosition;
  bool _isDentroDelRadio = false;
  bool _esEntrada = true;
  bool _isFaceVerified = false;
  Uint8List? _capturedImageBytes; // Para guardar la foto y usarla después

  // --- Banderas de estado ---
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = "Preparando servicios...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> _handleFaceVerification() async {
    if (_isProcessing || !_isCameraInitialized || _cameraController == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final XFile photoFile = await _cameraController!.takePicture();
      _capturedImageBytes = await _processImageToBytes(photoFile);
      
      bool rostroDetectado = await _azureFaceService.detectarRostroEnImagen(_capturedImageBytes!);

      if (rostroDetectado && mounted) {
        setState(() {
          _isFaceVerified = true;
          _flowState = MarcacionFlowState.ingresoDNI;
          _cameraController?.dispose(); 
          _cameraController = null;
        });
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
        "Ocurrió un error al contactar con el servicio de reconocimiento facial. Revisa tu conexión a internet. Detalles: ${e.toString()}",
        Icons.cloud_off,
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  
  Future<Uint8List> _processImageToBytes(XFile photoFile) async {
    final bytes = await photoFile.readAsBytes();
    final imgLib = img.decodeImage(bytes);
    if (imgLib == null) throw Exception("No se pudo decodificar la imagen");
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
      
      // 1. Verificar empleado
      _empleado = await _firebaseService.getEmpleadoByDNI(dni);
      if (_empleado == null) throw Exception("No se encontró empleado con DNI $dni.");

      if (_empleado!.activo != true) {
        throw Exception("Este empleado no se encuentra activo. Por favor, contacte a Recursos Humanos.");
      }

      // 2. Verificar sede
      _sede = await _firebaseService.getSedeById(_empleado!.sedeId);
      if (_sede == null) throw Exception("La sede asignada al empleado no fue encontrada.");
      
      if (_sede!.activa != true) {
        throw Exception("La sede '${_sede!.nombre}' no se encuentra activa. Por favor, contacte a su supervisor.");
      }

      // 3. NUEVA LÓGICA: Verificar estado de asistencia del empleado HOY
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
          // Obtener la asistencia completa para mostrar detalles
          _asistenciaDelDia = await _firebaseService.getCompletedAsistenciaForToday(_empleado!.id);
          setState(() => _flowState = MarcacionFlowState.jornadaCompletada);
          return; // Salir aquí, no continuar con verificación de ubicación
          
        case AsistenciaStatus.error:
          throw Exception(asistenciaController.errorMessage ?? "Error al verificar estado de asistencia");
      }

      // 4. Verificar ubicación (solo si no tiene jornada completa)
      final distancia = LocationHelper.calcularDistancia(
        _currentPosition!.latitude, _currentPosition!.longitude, 
        _sede!.latitud, _sede!.longitud
      );
      _isDentroDelRadio = distancia <= _sede!.radioPermitido;
      
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
          empleadoId: _empleado!.id, // Cambiado: ahora usa empleadoId
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

  Widget _buildCurrentView() {
    switch (_flowState) {
      case MarcacionFlowState.inicializando:
      case MarcacionFlowState.errorServicios:
        return _buildInitialOrErrorView(key: ValueKey(_flowState));
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
            child: (_isCameraInitialized && _cameraController != null)
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
        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Verificando identidad y jornada..."),
              ],
            ),
          )
        else
          Column(
            children: [
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
  
  // --- Widgets de componentes reutilizables (sin cambios) ---
  
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

          // Contenido en columnas: título y (opcional) subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Título
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    // Ícono de estado a la derecha
                    Icon(statusIcon, color: color, size: 20),
                  ],
                ),

                // Subtítulo: fecha/hora (si existe)
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


  // --- DIÁLOGOS DE FEEDBACK ---
  void _showInfoDialog(String title, String content, IconData icon, Color color) {
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