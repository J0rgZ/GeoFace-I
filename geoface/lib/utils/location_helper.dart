// lib/utils/location_helper.dart
import 'dart:math';

class LocationHelper {
  /// Calcula la distancia entre dos coordenadas geográficas en metros usando la fórmula de Haversine.
  static double calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double radioTierra = 6371000; // Radio de la Tierra en metros

    // Convertir grados a radianes
    final double lat1Rad = lat1 * (pi / 180);
    final double lon1Rad = lon1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double lon2Rad = lon2 * (pi / 180);

    // Diferencias de latitud y longitud
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    // Fórmula de Haversine
    final double a = pow(sin(dLat / 2), 2) +
                   cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distancia = radioTierra * c;

    return distancia;
  }
}