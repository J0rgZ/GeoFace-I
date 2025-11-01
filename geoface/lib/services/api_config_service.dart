// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Configuración de API
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `ApiConfigService`, que actúa como
//               una capa de servicio para todas las operaciones relacionadas con
//               la configuración de API en Firebase. Centraliza las operaciones
//               CRUD con Cloud Firestore para la configuración de endpoints de API,
//               desacoplando la lógica de la base de datos de los controladores y
//               la interfaz de usuario. Este enfoque mejora la mantenibilidad y
//               la organización del código.
//
// @NombreArchivo: api_config_service.dart
// @Ubicacion:    lib/services/api_config_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/api_config.dart';

/// Clase de servicio para gestionar todas las operaciones relacionadas con la configuración de API.
///
/// Centraliza las operaciones de Firestore para la configuración de API,
/// manteniendo el código organizado y desacoplado de la lógica de la interfaz.
class ApiConfigService {
  // Instancia de Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda o actualiza el objeto de configuración de la API en un único documento de Firestore.
  ///
  /// @param config El objeto [ApiConfig] a guardar.
  /// Utiliza `SetOptions(merge: true)` para no sobrescribir campos que no estén en el objeto `config`.
  Future<void> saveApiConfig(ApiConfig config) async {
    try {
      await _firestore.collection('app_config').doc('settings').set(
        config.toMap(), 
        SetOptions(merge: true)
      );
    } catch (e) {
      debugPrint("Error al guardar la configuración de la API: $e");
      throw Exception("No se pudo guardar la configuración. Inténtalo de nuevo.");
    }
  }

  /// Obtiene el objeto de configuración de la API desde Firestore.
  ///
  /// @returns Un [Future] que completa con el objeto [ApiConfig].
  /// Si el documento no existe, devuelve una configuración por defecto con `ApiConfig.empty`.
  Future<ApiConfig> getApiConfig() async {
    try {
      final docSnapshot = await _firestore.collection('app_config').doc('settings').get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ApiConfig.fromMap(docSnapshot.data()!);
      }
      // Si el documento no existe, devuelve una configuración vacía/predeterminada.
      return ApiConfig.empty;
    } catch (e) {
      debugPrint("Error al obtener la configuración de la API: $e");
      throw Exception("No se pudo cargar la configuración de la API.");
    }
  }
}

