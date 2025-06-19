// lib/controllers/api_config_controller.dart

import 'package:flutter/material.dart';
import '../models/api_config.dart';
import '../services/firebase_service.dart';

class ApiConfigController with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  ApiConfig _apiConfig = ApiConfig.empty;
  bool _isLoading = false;
  String? _error;

  // Getters para que la UI acceda al estado de forma segura
  ApiConfig get apiConfig => _apiConfig;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ApiConfigController() {
    // Carga la configuración inicial al crear el controlador
    loadApiConfig();
  }

  /// Carga la configuración de la API desde Firebase.
  Future<void> loadApiConfig() async {
    _setLoading(true);
    _error = null;

    try {
      final url = await _firebaseService.getFaceApiUrl();
      _apiConfig = ApiConfig(faceRecognitionApiUrl: url ?? '');
    } catch (e) {
      _error = "Error al cargar la configuración: ${e.toString()}";
      _apiConfig = ApiConfig.empty;
    } finally {
      _setLoading(false);
    }
  }

  /// Guarda la nueva configuración de la API en Firebase.
  /// Retorna `true` si fue exitoso, `false` en caso de error.
  Future<bool> saveApiConfig(String newUrl) async {
    _setLoading(true);
    _error = null;

    // Validación simple
    if (newUrl.trim().isEmpty || !Uri.tryParse(newUrl.trim())!.isAbsolute) {
      _error = "Por favor, ingresa una URL válida.";
      _setLoading(false);
      return false;
    }

    try {
      await _firebaseService.saveFaceApiUrl(newUrl.trim());
      // Actualiza el estado local después de guardar exitosamente
      _apiConfig = ApiConfig(faceRecognitionApiUrl: newUrl.trim());
      _setLoading(false);
      return true; // Éxito
    } catch (e) {
      _error = "Error al guardar la configuración: ${e.toString()}";
      _setLoading(false);
      return false; // Error
    }
  }

  // Método privado para manejar el estado de carga y notificar a los oyentes.
  void _setLoading(bool loadingState) {
    _isLoading = loadingState;
    notifyListeners();
  }
}