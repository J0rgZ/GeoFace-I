// lib/controllers/api_config_controller.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/api_config.dart';
import '../services/firebase_service.dart';

class ApiConfigController with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  ApiConfig _apiConfig = ApiConfig.empty;
  bool _isLoading = false;
  bool _isSyncing = false; // <-- Nuevo estado para el botón de sincronizar
  String? _error;

  // Getters
  ApiConfig get apiConfig => _apiConfig;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing; // <-- Getter para el nuevo estado
  String? get error => _error;

  ApiConfigController() {
    loadApiConfig();
  }

  Future<void> loadApiConfig() async {
    _setLoading(true);
    _error = null;
    try {
      _apiConfig = await _firebaseService.getApiConfig();
    } catch (e) {
      _error = "Error al cargar la configuración: ${e.toString()}";
      _apiConfig = ApiConfig.empty;
    } finally {
      _setLoading(false);
    }
  }

  /// Guarda la configuración a partir de una URL base.
  Future<bool> saveApiConfigFromBaseUrl(String baseUrl) async {
    _setLoading(true);
    _error = null;

    final trimmedUrl = baseUrl.trim();
    if (trimmedUrl.isEmpty || !Uri.tryParse(trimmedUrl)!.isAbsolute) {
      _error = "Por favor, ingresa una URL base válida (ej: https://...).";
      _setLoading(false);
      return false;
    }

    // Construimos las URLs completas
    final newConfig = ApiConfig(
      identificationApiUrl: '$trimmedUrl/identificar',
      syncApiUrl: '$trimmedUrl/sync-database',
    );

    try {
      await _firebaseService.saveApiConfig(newConfig);
      _apiConfig = newConfig; // Actualiza el estado local
      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Error al guardar: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }
  
  /// NUEVO: Llama al endpoint de sincronización de la API.
  Future<String> syncRemoteDatabase() async {
    if (_apiConfig.syncApiUrl.isEmpty) {
      return "Error: No hay una URL de sincronización configurada.";
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final response = await http.post(Uri.parse(_apiConfig.syncApiUrl));

      if (response.statusCode == 200) {
        return "✅ ¡Éxito! La base de datos de la API se está actualizando.";
      } else {
        return "❌ Error (${response.statusCode}): No se pudo sincronizar. Revisa la consola de la API.";
      }
    } catch (e) {
      return "❌ Error de conexión: No se pudo contactar a la API. ¿Está encendida y la URL es correcta?";
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _setLoading(bool loadingState) {
    _isLoading = loadingState;
    notifyListeners();
  }
}