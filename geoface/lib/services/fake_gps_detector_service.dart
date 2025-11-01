// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Detección de GPS Falso
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `FakeGpsDetectorService`, que se
//               encarga de detectar si el dispositivo está utilizando una
//               ubicación falsa o simulada. Verifica tanto si la ubicación es
//               marcada como "mock" por el sistema como si tiene una precisión
//               muy baja que podría indicar manipulación. Es una medida de
//               seguridad importante para prevenir fraudes en el sistema de
//               asistencia.
//
// @NombreArchivo: fake_gps_detector_service.dart
// @Ubicacion:    lib/services/fake_gps_detector_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class FakeGpsDetectorService {
  /// Verifica si la ubicación es falsa o manipulada
  static Future<bool> _isMockLocation(Position position) async {
    try {
      return position.isMocked;
    } catch (e) {
      debugPrint("Error verificando ubicación falsa: $e");
      return true; // Si falla, mejor prevenir
    }
  }

  /// Verifica si la precisión es muy baja (posible ubicación simulada)
  static bool _isLowAccuracy(Position position, {double threshold = 50.0}) {
    return position.accuracy > threshold;
  }

  /// Llama esta función antes de marcar asistencia
  static Future<String?> checkIfFakeGpsUsed() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      final isMock = await _isMockLocation(position);
      final isLowAccuracy = _isLowAccuracy(position);

      if (isMock) return "Se detectó ubicación falsa (mocked).";
      if (isLowAccuracy) return "Ubicación con baja precisión.";

      return null; // Sin problemas detectados
    } catch (e) {
      return "No se pudo verificar la ubicación.";
    }
  }
}
