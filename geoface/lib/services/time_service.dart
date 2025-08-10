// services/time_service.dart

import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import '../models/network_time_result.dart';

/// Servicio responsable de obtener una fuente de tiempo confiable desde la red.
///
/// **Mejoras Clave:**
/// 1.  **Inyección de Dependencias:** La clase ya no es estática. Se crea una instancia,
///     lo que permite "inyectarla" en otros servicios o ViewModels. Esto es
///     fundamental para las pruebas unitarias, ya que se puede reemplazar por una
///     versión "mock" (simulada).
/// 2.  **Configurabilidad:** El servidor NTP y el timeout se pueden configurar
///     en el constructor, haciendo el servicio más flexible.
/// 3.  **Resultado Informativo:** Devuelve un objeto `NetworkTimeResult` en lugar
///     de un `DateTime` simple, permitiendo al código que lo llama saber si
///     la hora obtenida es de red o local.
class TimeService {
  final String ntpServer;
  final Duration timeout;

  /// Constructor del servicio.
  /// Permite especificar un servidor NTP y un timeout, o usa valores por defecto.
  const TimeService({
    this.ntpServer = 'time.google.com',
    this.timeout = const Duration(seconds: 5),
  });

  /// Obtiene la hora actual de un servidor NTP.
  ///
  /// Devuelve un objeto [NetworkTimeResult] que indica tanto la hora
  /// como si la sincronización con el servidor de red fue exitosa.
  /// No lanza excepciones por fallo de red; en su lugar, el `isSuccess`
  /// del resultado será `false`.
  Future<NetworkTimeResult> getCurrentNetworkTime() async {
    try {
      // Se usan las propiedades de la instancia en lugar de valores hardcodeados.
      final DateTime networkTime = await NTP.now(
        lookUpAddress: ntpServer,
        timeout: timeout,
      );
      // Éxito: La hora es la de la red.
      return NetworkTimeResult(time: networkTime, isSuccess: true);
    } catch (e) {
      // Se usa debugPrint, que se omite en builds de producción.
      debugPrint("Error al obtener la hora de red. Se usará la hora local como respaldo. Error: $e");
      
      // Fallo: La hora es la del dispositivo local.
      // Se informa del fallo a través del objeto de resultado.
      return NetworkTimeResult(time: DateTime.now(), isSuccess: false);
    }
  }
}