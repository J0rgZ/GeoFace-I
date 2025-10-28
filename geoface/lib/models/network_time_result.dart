// -----------------------------------------------------------------------------
// @Encabezado:   Resultado de Tiempo de Red
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Define el modelo `NetworkTimeResult` para encapsular el
//               resultado de una solicitud de tiempo a un servidor NTP. Incluye
//               tanto el tiempo obtenido como un indicador de éxito para saber
//               si la hora corresponde al servidor de red o al dispositivo local.
//
// @NombreModelo: NetworkTimeResult
// @Ubicacion:    lib/models/network_time_result.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

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