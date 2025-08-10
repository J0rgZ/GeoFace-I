// lib/controllers/api_config_controller.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_config.dart';
import '../services/firebase_service.dart';

/// Controlador para gestionar el estado y la lógica de la configuración de la API.
///
/// Utiliza el patrón de inyección de dependencias para recibir una instancia de
/// [FirebaseService], lo que permite desacoplarlo y facilita las pruebas unitarias.
class ApiConfigController with ChangeNotifier {
  final FirebaseService _firebaseService;

  // --- Constantes para evitar "Magic Strings" ---
  static const String _identificarEndpoint = '/identificar';
  static const String _syncEndpoint = '/sync-database';

  // --- Estado Interno ---
  ApiConfig? _apiConfig;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;

  /// Constructor que requiere un [FirebaseService].
  ApiConfigController(this._firebaseService);

  // --- Getters Públicos para la UI ---
  ApiConfig? get apiConfig => _apiConfig;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  
  /// Indica si existe una configuración válida y cargada.
  bool get isConfigured => _apiConfig != null;

  /// Carga la configuración de la API desde Firestore.
  ///
  /// **Nota de Diseño:** Este método debe ser llamado explícitamente desde la UI
  /// (ej. en `initState` de un StatefulWidget) en lugar de en el constructor
  /// para tener un control más predecible sobre los estados de carga y error.
  Future<void> loadApiConfig() async {
    _setLoading(true);
    _error = null;
    try {
      // El servicio ahora puede devolver null, lo cual es un estado válido (sin configurar).
      _apiConfig = await _firebaseService.getApiConfig();
    } catch (e) {
      _error = "Error al cargar la configuración: ${e.toString()}";
      _apiConfig = null; // En caso de error, la configuración es nula.
    } finally {
      _setLoading(false);
    }
  }

  /// Construye y guarda una nueva configuración a partir de una URL base.
  ///
  /// Valida la URL base y luego construye las URLs de los endpoints completos
  /// antes de guardarlas a través del servicio de Firebase.
  /// Devuelve `true` si la operación fue exitosa.
  Future<bool> saveAndConstructApiConfig(String baseUrl) async {
    _setLoading(true);
    _error = null;

    final trimmedUrl = baseUrl.trim().replaceAll(RegExp(r'/$'), ''); // Limpia y quita la barra final

    if (trimmedUrl.isEmpty || Uri.tryParse(trimmedUrl)?.isAbsolute != true) {
      _error = "Por favor, ingresa una URL base válida (ej: https://api.midominio.com).";
      _setLoading(false);
      return false;
    }

    // Se construye el objeto ApiConfig completo, como lo requiere el modelo refactorizado.
    final newConfig = ApiConfig(
      baseUrl: trimmedUrl,
      identificationApiUrl: '$trimmedUrl$_identificarEndpoint',
      syncApiUrl: '$trimmedUrl$_syncEndpoint',
    );

    try {
      await _firebaseService.saveApiConfig(newConfig);
      _apiConfig = newConfig; // Actualiza el estado local con la nueva configuración válida.
      return true;
    } catch (e) {
      _error = "Error al guardar: ${e.toString()}";
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Llama al endpoint de sincronización de la API.
  ///
  /// Devuelve un mensaje de estado legible para el usuario.
  /// En una app más compleja, esto podría devolver un enum o un objeto de resultado.
  Future<String> syncRemoteDatabase() async {
    // La validación ahora es más simple y segura: ¿tenemos una configuración?
    if (_apiConfig == null) {
      return "Error: No hay una URL de sincronización configurada.";
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // Se usa el operador '!' porque ya se validó que _apiConfig no es nulo.
      final response = await http.post(Uri.parse(_apiConfig!.syncApiUrl));

      if (response.statusCode == 200) {
        return "✅ ¡Éxito! La base de datos de la API se está actualizando.";
      } else {
        return "❌ Error (${response.statusCode}): No se pudo sincronizar. Revise los logs de la API.";
      }
    } catch (e) {
      return "❌ Error de conexión: No se pudo contactar a la API. Verifique que la URL es correcta y el servidor está en línea.";
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Helper privado para gestionar el estado de carga y notificar a los listeners.
  void _setLoading(bool loadingState) {
    _isLoading = loadingState;
    notifyListeners();
  }
}