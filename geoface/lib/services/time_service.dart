import 'package:ntp/ntp.dart';

class TimeService {
  /// Obtiene la hora actual de un servidor NTP para evitar la manipulación
  /// de la hora del dispositivo.
  /// Devuelve [DateTime.now()] como respaldo si falla la conexión.
  static Future<DateTime> getCurrentNetworkTime() async {
    try {
      // Usamos el servidor de Google, pero puedes usar otros.
      // El timeout es importante para no bloquear la app si no hay internet.
      return await NTP.now(lookUpAddress: 'time.google.com', timeout: Duration(seconds: 5));
    } catch (e) {
      print("Error al obtener la hora de red, usando hora local: $e");
      // Si no hay conexión, devolvemos la hora del dispositivo como respaldo.
      // En un escenario real, podrías querer registrar que esta marcación
      // se hizo sin hora de red verificada.
      return DateTime.now();
    }
  }
}