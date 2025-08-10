// models/network_time_result.dart

/// Representa el resultado de una solicitud de tiempo a un servidor NTP.
///
/// Encapsula tanto el [DateTime] obtenido como un indicador [isSuccess]
/// para saber si la hora corresponde a la del servidor de red (éxito)
/// o a la del dispositivo local (fallo/respaldo).
class NetworkTimeResult {
  final DateTime time;
  final bool isSuccess;

  const NetworkTimeResult({required this.time, required this.isSuccess});
}