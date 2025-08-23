// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Localización (GPS)
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `LocationService`, que encapsula
//               toda la lógica para interactuar con el GPS del dispositivo
//               utilizando el paquete `geolocator`. Se encarga de verificar si
//               los servicios de ubicación están activos, solicitar los
//               permisos necesarios al usuario y obtener la posición actual
//               (latitud y longitud). Centralizar esta lógica aquí simplifica
//               su uso en otros controladores.
//
// @NombreArchivo: location_service.dart
// @Ubicacion:    lib/services/location_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:geolocator/geolocator.dart';

// Clase de servicio dedicada a la gestión de la geolocalización.
class LocationService {
  
  /// Obtiene la posición GPS actual del dispositivo.
  ///
  /// Este método realiza una secuencia de validaciones:
  /// 1. Verifica si el servicio de ubicación del dispositivo está encendido.
  /// 2. Comprueba si la aplicación tiene los permisos necesarios. Si no los tiene, los solicita.
  /// 3. Si los permisos son concedidos, obtiene y devuelve la posición.
  ///
  /// Lanza una [Exception] con un mensaje en español si el servicio está apagado
  /// o si el usuario deniega los permisos.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Primero, se comprueba si los servicios de ubicación del teléfono están habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si están desactivados, no se puede continuar.
      throw Exception('Los servicios de ubicación están desactivados.');
    }

    // Se comprueba el estado de los permisos para esta aplicación.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si los permisos no han sido otorgados, se le solicitan al usuario.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Si el usuario rechaza la solicitud.
        throw Exception('Los permisos de ubicación fueron denegados');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Si el usuario ha denegado los permisos permanentemente, no se puede volver a preguntar.
      throw Exception('Los permisos de ubicación fueron denegados permanentemente');
    }

    // Si se llega a este punto, los permisos están otorgados y se puede
    // acceder de forma segura a la posición del dispositivo.
    return await Geolocator.getCurrentPosition();
  }
}