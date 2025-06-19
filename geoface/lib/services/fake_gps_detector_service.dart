import 'package:geolocator/geolocator.dart';
import 'package:device_apps/device_apps.dart';


class FakeGpsDetectorService {
  /// Verifica si el dispositivo tiene apps de GPS falso conocidas
  static Future<bool> _hasFakeGpsApps() async {
    final List<String> fakeGpsPackages = [
      'com.lexa.fakegps',
      'com.fakegps.mock',
      'com.incorporateapps.fakegps.fre',
      'com.blogspot.newapphorizons.fakegps',
      'com.just4funtools.fakegps',
    ];

    try {
      final apps = await DeviceApps.getInstalledApplications(includeSystemApps: false);
      return apps.any((app) => fakeGpsPackages.contains(app.packageName));
    } catch (e) {
      print("Error verificando apps instaladas: $e");
      return false;
    }
  }

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
    final position = await Geolocator.getCurrentPosition();

    final isMock = await _isMockLocation(position);
    final isLowAccuracy = _isLowAccuracy(position);
    final hasFakeGpsApp = await _hasFakeGpsApps();

    if (isMock) return "Se detectó ubicación falsa (mocked)";
    if (isLowAccuracy) return "Ubicación con baja precisión";
    if (hasFakeGpsApp) return "Se detectó app de GPS falso instalada";

    return null; // Sin problemas detectados
  }
}