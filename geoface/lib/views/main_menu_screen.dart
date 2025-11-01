// -----------------------------------------------------------------------------
// @Encabezado:   Pantalla Principal del Menú
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la pantalla principal de la aplicación
//               GeoFace, que incluye el menú principal con sincronización de
//               tiempo de servidores, verificación de GPS falso, y navegación
//               a las funciones de marcar asistencia y acceso administrativo.
//               También contiene las clases TimeService y ResponsiveConfig
//               para gestión de tiempo y diseño responsivo.
//
// @NombreArchivo: main_menu_screen.dart
// @Ubicacion:    lib/views/main_menu_screen.dart
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
import 'package:geoface/services/fake_gps_detector_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// La clase TimeService se mantiene como la definiste originalmente.
class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  static const List<Map<String, String>> _timeApis = [
    {
      'url': 'https://www.google.com',
      'name': 'Google HTTP Header',
      'type': 'google-header'
    },
    {
      'url': 'https://timeapi.io/api/Time/current/zone?timeZone=America/Lima',
      'name': 'TimeAPI.io',
      'type': 'timeapi'
    },
    {
      'url': 'http://worldclockapi.com/api/json/est/now',
      'name': 'WorldClock API',
      'type': 'worldclock'
    },
  ];

  DateTime? _baseApiTime;
  final Stopwatch _syncStopwatch = Stopwatch();

  String _currentTimeSource = 'Inicializando...';
  bool _isOnline = false;
  Timer? _syncTimer;

  String get timeSource => _currentTimeSource;
  bool get isOnline => _isOnline;

  Future<DateTime> getCurrentTime() async {
    if (_baseApiTime != null && _syncStopwatch.isRunning) {
      return _baseApiTime!.add(_syncStopwatch.elapsed);
    }

    await _attemptTimeSync();

    if (_baseApiTime != null && _syncStopwatch.isRunning) {
      return _baseApiTime!.add(_syncStopwatch.elapsed);
    }

    _currentTimeSource = 'Sin Conexión - Tiempo Local';
    _isOnline = false;
    return DateTime.now().toUtc().subtract(const Duration(hours: 5));
  }

  Future<void> _attemptTimeSync() async {
    for (final api in _timeApis) {
      try {
        final uri = Uri.parse(api['url']!);
        final response = api['type'] == 'google-header'
            ? await http.head(uri).timeout(const Duration(seconds: 5))
            : await http
                .get(uri, headers: {'Accept': 'application/json'})
                .timeout(const Duration(seconds: 8));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final apiTime = _parseTimeResponse(api, response);

          if (apiTime != null && _isTimeReasonable(apiTime)) {
            _baseApiTime = apiTime;
            _syncStopwatch.reset();
            _syncStopwatch.start();

            _isOnline = true;
            _currentTimeSource = '${api['name']} (Sincronizado)';

            debugPrint('✓ Sincronizado con: ${api['name']}');
            debugPrint('✓ Hora Base API (Lima): ${_baseApiTime.toString()}');

            return;
          }
        }
      } catch (e) {
        debugPrint('✗ Error con ${api['name']}: $e');
        continue;
      }
    }

    debugPrint('✗ Todas las APIs fallaron. Usando tiempo local.');
    _isOnline = false;
    _currentTimeSource = 'APIs no disponibles - Tiempo Local';
    _syncStopwatch.stop();
    _baseApiTime = null;
  }

  DateTime? _parseTimeResponse(Map<String, String> api, http.Response response) {
    try {
      switch (api['type']) {
        case 'google-header':
          final dateHeader = response.headers['date'];
          if (dateHeader == null) return null;
          return parseHttpDate(dateHeader).subtract(const Duration(hours: 5));
        case 'timeapi':
          final data = json.decode(response.body);
          return DateTime.parse(data['dateTime'] as String);
        case 'worldclock':
          final data = json.decode(response.body);
          return DateTime.parse(data['currentDateTime'] as String);
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error parseando ${api['name']}: $e');
      return null;
    }
  }

  bool _isTimeReasonable(DateTime apiTime) {
    final now = DateTime.now();
    final difference = apiTime.difference(now).abs();
    return difference.inHours <= 12;
  }

  void initialize() {
    _attemptTimeSync();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
        const Duration(minutes: 5), (timer) => _attemptTimeSync());
  }

  Future<void> forceSync() async {
    _currentTimeSource = 'Sincronizando...';
    await _attemptTimeSync();
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncStopwatch.stop();
  }
}

// La clase ResponsiveConfig se mantiene como la definiste originalmente.
class ResponsiveConfig {
  final double screenWidth;
  final double screenHeight;
  final bool isPortrait;

  ResponsiveConfig({
    required this.screenWidth,
    required this.screenHeight,
  }) : isPortrait = screenHeight > screenWidth;

  bool get isXSmall => screenWidth < 360;
  bool get isSmall => screenWidth >= 360 && screenWidth < 480;
  bool get isMedium => screenWidth >= 480 && screenWidth < 768;
  bool get isLarge => screenWidth >= 768 && screenWidth < 1024;
  bool get isXLarge => screenWidth >= 1024;

  double get dateSize => isXSmall ? 14 : isSmall ? 16 : isMedium ? 18 : 20;
  double get timeSize =>
      isXSmall ? 42 : isSmall ? 52 : isMedium ? 64 : isLarge ? 76 : 88;
  double get titleSize => isXSmall ? 20 : isSmall ? 24 : isMedium ? 28 : 32;
  double get buttonTextSize => isXSmall ? 14 : isSmall ? 16 : 18;
  double get statusSize => isXSmall ? 11 : isSmall ? 12 : 14;

  double get padding => isXSmall ? 12 : isSmall ? 16 : isMedium ? 20 : 24;
  double get margin => isXSmall ? 8 : isSmall ? 12 : isMedium ? 16 : 20;
  double get buttonHeight => isXSmall ? 48 : isSmall ? 52 : isMedium ? 56 : 60;

  double get iconSize => isXSmall ? 20 : isSmall ? 24 : isMedium ? 28 : 32;
  double get buttonIconSize => isXSmall ? 20 : isSmall ? 22 : 24;
}

class MainMenuScreen extends StatefulWidget {
  final void Function(BuildContext context) onMarkAttendance;
  final void Function(BuildContext context) onAdminLogin;

  const MainMenuScreen({
    super.key,
    required this.onMarkAttendance,
    required this.onAdminLogin,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late DateTime _currentTime;
  late Timer _timer;
  late AnimationController _pulseController;
  late AnimationController _syncController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _syncAnimation;

  late AnimationController _entryController;
  late Animation<double> _headerFade, _cardFade, _buttonFade;

  bool _isMenuOpen = false;
  bool _isInitializing = true;
  bool _isSyncing = false;
  
  /// Estado para controlar la verificación del GPS
  bool _isCheckingGps = false;

  final TimeService _timeService = TimeService();

  static const Color _primaryColor = Color(0xFF6A1B9A);
  static const Color _secondaryColor = Color(0xFF00C853);
  static const Color _accentColor = Color(0xFF4E1386);

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await initializeDateFormatting('es_PE', null);
    _setupAnimations();

    _timeService.initialize();
    await _initializeTime();
    _setupTimers();

    setState(() {
      _isInitializing = false;
    });

    _entryController.forward();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _syncController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _syncAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _syncController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _initializeTime() async {
    _currentTime = await _timeService.getCurrentTime();
  }

  void _setupTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        final newTime = await _timeService.getCurrentTime();
        setState(() {
          _currentTime = newTime;
        });
      }
    });
  }

  Future<void> _performManualSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    _syncController.reset();
    _syncController.forward();

    await _timeService.forceSync();

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });

      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _timeService.isOnline
                ? '✓ Sincronizado correctamente'
                : '⚠ Sin conexión - usando tiempo local',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: _timeService.isOnline ? _secondaryColor : Colors.orange,
        ),
      );
    }
  }

  /// Muestra un diálogo de error cuando se detecta un problema con el GPS.
  void _showGpsErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // El usuario debe confirmar
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Alerta de Seguridad', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Maneja el proceso de marcar asistencia, incluyendo la verificación de GPS falso.
  Future<void> _handleMarkAttendance() async {
    if (_isCheckingGps) return; // Evitar múltiples clics

    setState(() {
      _isCheckingGps = true;
    });
    HapticFeedback.mediumImpact();

    try {
      // 1. Llamar al servicio de detección de GPS falso
      final fakeGpsMessage = await FakeGpsDetectorService.checkIfFakeGpsUsed();

      // 2. Comprobar el resultado
      if (fakeGpsMessage != null) {
        // Problema detectado: Mostrar alerta y no continuar
        if (mounted) {
          _showGpsErrorDialog(fakeGpsMessage);
        }
      } else {
        // Todo en orden: Proceder a marcar asistencia
        if (mounted) {
          widget.onMarkAttendance(context);
        }
      }
    } catch (e) {
      // Manejar errores inesperados (ej. permisos de ubicación denegados)
      if (mounted) {
        _showGpsErrorDialog("No se pudo verificar la ubicación. Asegúrate de tener los permisos de GPS activados. Error: ${e.toString()}");
      }
    } finally {
      // 3. Restablecer el estado del botón
      if (mounted) {
        setState(() {
          _isCheckingGps = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _syncController.dispose();
    _entryController.dispose();
    _timeService.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final config = ResponsiveConfig(
          screenWidth: constraints.maxWidth,
          screenHeight: constraints.maxHeight,
        );

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: _buildGradientBackground(),
            child: SafeArea(
              child: Stack(
                children: [
                  _buildMainContent(config),
                  if (_isMenuOpen) _buildMenuOverlay(config),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A0D45),
          Color(0xFF4E1386),
          Color(0xFF2E0F52),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final config = ResponsiveConfig(
            screenWidth: constraints.maxWidth,
            screenHeight: constraints.maxHeight,
          );
          
          return Center(
            child: Padding(
              padding: EdgeInsets.all(config.padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: config.isXSmall ? 120 : 150,
                    height: config.isXSmall ? 120 : 150,
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        return const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: config.padding),
                  Text(
                    'Inicializando GeoFace...',
                    style: TextStyle(
                      fontSize: config.buttonTextSize,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: config.margin),
                  Text(
                    'Sincronizando con tiempo de servidores',
                    style: TextStyle(
                      fontSize: config.statusSize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(ResponsiveConfig config) {
    final limaTimeFormat = DateFormat('EEEE d \'de\' MMMM, yyyy', 'es_PE');
    final clockFormat = DateFormat('HH:mm:ss');

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     MediaQuery.of(context).padding.bottom,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              FadeTransition(
                opacity: _headerFade,
                child: _buildHeader(config),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _cardFade,
                  child: _buildTimeCard(config, limaTimeFormat, clockFormat),
                ),
              ),
              FadeTransition(
                opacity: _buttonFade,
                child: _buildAdminAccess(config),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(config.padding * 0.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.face_retouching_natural,
                    color: Colors.white,
                    size: config.iconSize,
                  ),
                ),
                SizedBox(width: config.margin),
                Flexible(
                  child: Text(
                    'GeoFace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: config.titleSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _buildSyncIndicator(config),
          SizedBox(width: config.margin),
          _buildMenuButton(config),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator(ResponsiveConfig config) {
    return GestureDetector(
      onTap: _performManualSync,
      child: AnimatedBuilder(
        animation: _syncAnimation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: config.margin,
              vertical: config.margin * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSyncing)
                  Transform.rotate(
                    angle: _syncAnimation.value * 6.28,
                    child: const Icon(
                      Icons.sync,
                      size: 16,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    _timeService.isOnline ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: _timeService.isOnline ? _secondaryColor : Colors.orange[300],
                  ),
                const SizedBox(width: 6),
                Text(
                  _timeService.isOnline ? 'Online' : 'Local',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: config.statusSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton(ResponsiveConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: AnimatedRotation(
          turns: _isMenuOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isMenuOpen ? Icons.close : Icons.info_outline,
            color: Colors.white,
            size: config.iconSize * 0.8,
          ),
        ),
        onPressed: _toggleMenu,
        tooltip: 'Información',
        padding: EdgeInsets.all(config.margin),
      ),
    );
  }

  Widget _buildTimeCard(ResponsiveConfig config, DateFormat dateFormat, DateFormat timeFormat) {
    return Padding(
      padding: EdgeInsets.all(config.padding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: EdgeInsets.all(config.padding * 1.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateFormat.format(_currentTime).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: config.dateSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: config.padding),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    timeFormat.format(_currentTime),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: config.timeSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: config.margin),
                _buildTimeSource(config),
                SizedBox(height: config.padding * 1.5),
                _buildAttendanceButton(config),
                SizedBox(height: config.padding),
                _buildConnectionStatus(config),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSource(ResponsiveConfig config) {
    final isOnline = _timeService.isOnline;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.padding,
        vertical: config.margin * 0.5,
      ),
      decoration: BoxDecoration(
        color: isOnline ? 
          _secondaryColor.withValues(alpha: 0.1) : 
          Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? 
            _secondaryColor.withValues(alpha: 0.3) : 
            Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.language : Icons.smartphone,
            size: config.statusSize,
            color: isOnline ? _secondaryColor : Colors.orange[600],
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _timeService.timeSource,
              style: TextStyle(
                color: isOnline ? _secondaryColor : Colors.orange[700],
                fontSize: config.statusSize - 1,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(ResponsiveConfig config) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: double.infinity,
        height: config.buttonHeight,
        child: ElevatedButton(
          onPressed: _isCheckingGps ? null : _handleMarkAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            padding: EdgeInsets.zero,
            disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2), // Estilo para deshabilitado
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  _secondaryColor,
                  Color(0xFF00E676),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              alignment: Alignment.center,
              child: _isCheckingGps
                  ? SizedBox(
                      width: config.buttonIconSize,
                      height: config.buttonIconSize,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: config.buttonIconSize,
                        ),
                        SizedBox(width: config.margin),
                        Text(
                          'MARCAR ASISTENCIA',
                          style: TextStyle(
                            fontSize: config.buttonTextSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(ResponsiveConfig config) {
    final isOnline = _timeService.isOnline;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? _secondaryColor : Colors.orange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isOnline ? _secondaryColor : Colors.orange).withValues(alpha: 0.5),
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isOnline ? 'Hora sincronizada Online' : 'Tiempo local (UTC-5) - Sin conexión',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: config.statusSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminAccess(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      child: Column(
        children: [
          // Botón de acceso de empleado
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushNamed('/login-empleado');
              },
              icon: Icon(
                Icons.person_outline,
                color: Colors.white.withValues(alpha: 0.9),
                size: config.iconSize * 0.7,
              ),
              label: Text(
                'Iniciar Sesión como Empleado',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                  fontSize: config.statusSize + 2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: config.padding,
                  vertical: config.margin,
                ),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botón de acceso administrativo
          TextButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onAdminLogin(context);
            },
            icon: Icon(
              Icons.admin_panel_settings,
              color: Colors.white.withValues(alpha: 0.9),
              size: config.iconSize * 0.7,
            ),
            label: Text(
              'Acceso Administrativo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                fontSize: config.statusSize + 2,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: config.padding,
                vertical: config.margin,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // El resto de los métodos para el menú de información no han cambiado...
  Widget _buildMenuOverlay(ResponsiveConfig config) {
    final menuWidth = (config.screenWidth * 0.9).clamp(280.0, 400.0);
    
    return Positioned.fill(
      child: GestureDetector(
        onTap: _toggleMenu,
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Stack(
            children: [
              Positioned(
                top: config.padding * 4,
                right: config.padding,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _isMenuOpen ? Offset.zero : const Offset(1, 0),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: menuWidth,
                    constraints: BoxConstraints(
                      maxHeight: config.screenHeight * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildMenuContent(config),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent(ResponsiveConfig config) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(config.padding),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _accentColor],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white,
                size: config.iconSize * 0.8,
              ),
              SizedBox(width: config.margin),
              Expanded(
                child: Text(
                  'Información del Sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: config.buttonTextSize,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(config.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMenuHeader(config),
                SizedBox(height: config.padding),
                Text(
                  'Sistema avanzado de control de asistencia con reconocimiento facial, geolocalización y sincronización de tiempo oficial de Lima.',
                  style: TextStyle(
                    fontSize: config.statusSize + 1,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: config.padding),
                _buildTechnicalInfo(config),
                SizedBox(height: config.padding),
                _buildCopyright(config),
              ],
            ),
          ),
        ),
        
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(config.padding),
          child: ElevatedButton(
            onPressed: _toggleMenu,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: config.margin),
            ),
            child: Text(
              'CERRAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: config.statusSize + 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuHeader(ResponsiveConfig config) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(config.margin),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _accentColor],
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Icon(
            Icons.face_retouching_natural,
            size: config.iconSize,
            color: Colors.white,
          ),
        ),
        SizedBox(width: config.margin),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GeoFace',
                style: TextStyle(
                  fontSize: config.buttonTextSize + 2,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              Text(
                'Versión 2.3.1',
                style: TextStyle(
                  fontSize: config.statusSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfo(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: config.padding, vertical: config.margin),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(config, Icons.build, 'Build', '20250531-TimeSync-V2'),
          _buildInfoRow(config, Icons.schedule, 'Fuente de Tiempo', _timeService.timeSource),
          _buildInfoRow(config, Icons.cloud, 'Estado de Conexión', _timeService.isOnline ? 'Conectado' : 'Sin conexión'),
          _buildInfoRow(config, Icons.location_on, 'Zona Horaria', 'America/Lima (UTC-5)'),
          _buildInfoRow(config, Icons.phone_android, 'Plataforma', 'Flutter Mobile'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ResponsiveConfig config, IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: config.iconSize * 0.8,
        color: _primaryColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: config.statusSize + 1,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: config.statusSize,
          color: Colors.grey[600],
        ),
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
    );
  }

  Widget _buildCopyright(ResponsiveConfig config) {
    return Container(
      padding: EdgeInsets.all(config.padding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.copyright,
                size: config.statusSize,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '2025 GeoFace Systems',
                style: TextStyle(
                  fontSize: config.statusSize,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: config.margin * 0.5),
          Text(
            'Desarrollado para control de asistencia empresarial',
            style: TextStyle(
              fontSize: config.statusSize - 1,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}