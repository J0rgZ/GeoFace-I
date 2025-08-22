import 'package:geolocator/geolocator.dart';

class FakeGpsDetectorService {
  /// Verifica si la ubicación es falsa o manipulada
  static Future<bool> _isMockLocation(Position position) async {
    try {
      return position.isMocked;
    } catch (e) {
      print("Error verificando ubicación falsa: $e");
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
