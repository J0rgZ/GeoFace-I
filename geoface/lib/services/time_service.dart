// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Tiempo de Red (NTP)
// @Autor:        Brayar Lopez Catunta
// @Descripción:  Este archivo define la clase `TimeService`, responsable de
//               obtener la hora exacta desde un servidor de tiempo de red (NTP).
//               El propósito principal de este servicio es prevenir fraudes o
//               inconsistencias que podrían ocurrir si un empleado manipula
//               manualmente la fecha y hora de su dispositivo. Todas las marcas
//               de tiempo críticas (como entradas y salidas) deben usar este
//               servicio para garantizar su integridad.
//
// @NombreArchivo: time_service.dart
// @Ubicacion:    lib/services/time_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:ntp/ntp.dart';
import 'package:flutter/foundation.dart';

// Clase de servicio para obtener la hora de una fuente fiable en internet.
class TimeService {
  
  /// Obtiene la hora actual desde un servidor NTP (Protocolo de Tiempo de Red).
  ///
  /// El uso de NTP es una medida de seguridad crucial para asegurar que las marcas
  /// de asistencia no puedan ser alteradas cambiando la hora del sistema del dispositivo.
  ///
  /// Devuelve la hora del dispositivo (`DateTime.now()`) como un respaldo
  /// únicamente si la conexión con el servidor NTP falla (ej. sin internet).
  static Future<DateTime> getCurrentNetworkTime() async {
    try {
      // Se intenta obtener la hora del servidor NTP de Google.
      // Se establece un tiempo de espera (`timeout`) para evitar que la aplicación
      // se congele indefinidamente si no hay conexión a internet.
      return await NTP.now(
        lookUpAddress: 'time.google.com', 
        timeout: const Duration(seconds: 5)
      );
    } catch (e) {
      // Si ocurre un error (generalmente por falta de conexión), se registra en la consola.
      debugPrint("Error al obtener la hora de red, usando hora local: $e");
      
      // Se devuelve la hora local del dispositivo como última opción.
      // Nota: En un sistema de alta seguridad, se podría registrar que esta
      // marca de tiempo no fue verificada por NTP.
      return DateTime.now();
    }
  }
}