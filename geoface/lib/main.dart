// FILE: main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geoface/controllers/api_config_controller.dart';
import 'package:geoface/controllers/asistencia_controller.dart';
import 'package:geoface/controllers/administrador_controller.dart'; 
import 'package:geoface/controllers/biometrico_controller.dart';
import 'package:geoface/controllers/theme_provider.dart';
import 'package:geoface/controllers/user_controller.dart';
import 'package:geoface/views/permissions_handler.dart';
import 'package:geoface/views/main_menu_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_config.dart';
import 'routes.dart';
import 'themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/empleado_controller.dart';
import 'controllers/sede_controller.dart';
import 'controllers/reporte_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  try {
    await Firebase.initializeApp();
    await AppConfig.initialize();
  } catch (e) {
    debugPrint("Error en inicialización: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        // Controladores principales y de estado
        ChangeNotifierProvider(create: (context) => AuthController()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Controladores de funcionalidades específicas
        ChangeNotifierProvider(create: (context) => EmpleadoController()),
        ChangeNotifierProvider(create: (context) => SedeController()),
        ChangeNotifierProvider(create: (context) => ReporteController()),
        ChangeNotifierProvider(create: (context) => AsistenciaController()),
        ChangeNotifierProvider(create: (context) => AdministradorController()),
        ChangeNotifierProvider(create: (context) => UserController()),
        ChangeNotifierProvider(create: (_) => ApiConfigController()),
        ChangeNotifierProvider(create: (_) => BiometricoController()),        
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirstLaunch = true;
  bool _isLoading = true;
  final String _firstLaunchKey = 'isFirstLaunch';
  
  @override
  void initState() {
    super.initState();
    _loadAppState();
  }
  
  Future<void> _loadAppState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
      _isLoading = false;
    });
  }
  
  void _handlePermissionsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
    setState(() {
      _isFirstLaunch = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'GeoFace - Control de Asistencia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          onGenerateRoute: AppRoutes.generateRoute,
          home: _isLoading 
            ? _buildLoadingScreen() 
            : _buildInitialScreen(),
        );
      },
    );
  }
  
  Widget _buildLoadingScreen() {
    // (Sin cambios, este widget está bien)
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
  
  Widget _buildInitialScreen() {
    if (_isFirstLaunch) {
      return PermissionsHandlerScreen(
        onPermissionsGranted: _handlePermissionsGranted,
      );
    }
    
    return MainMenuScreen(
      onMarkAttendance: (context) {
        Navigator.of(context).pushNamed(AppRoutes.marcarAsistencia);
      },
      onAdminLogin: (context) {
        Navigator.of(context).pushNamed(AppRoutes.login);
      },
    );
  }
}