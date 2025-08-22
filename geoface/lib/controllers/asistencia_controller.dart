// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Lógica de Asistencia
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Esta clase gestiona la lógica de negocio y el estado para el
//               registro de asistencias. Actúa como un intermediario entre la
//               interfaz de usuario (la Vista) y los servicios de datos
//               (Firebase, localización, etc.). Utiliza ChangeNotifier para
//               notificar a la UI sobre cambios en el estado.
//
// @NombreArchivo: asistencia_controller.dart
// @Ubicacion:    lib/controllers/asistencia_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/time_service.dart';
import '../models/asistencia.dart';
import '../utils/location_helper.dart';

// Enum para representar de forma clara y segura los posibles estados de asistencia de un empleado.
// Esto evita el uso de strings o booleanos que pueden llevar a errores.
enum AsistenciaStatus {
  // El empleado no ha registrado entrada hoy.
  debeMarcarEntrada,
  // El empleado ha registrado entrada pero no salida.
  debeMarcarSalida, 
  // El empleado ya ha registrado entrada y salida hoy.
  jornadaCompleta,
  // Ocurrió un error al verificar el estado.
  error,
}


// Controlador para gestionar la lógica de negocio relacionada con el registro de asistencias.
//
// Utiliza `ChangeNotifier` para que los widgets que lo escuchan puedan reconstruirse
// automáticamente cuando el estado (como la lista de asistencias o el estado de carga) cambie.
class AsistenciaController extends ChangeNotifier {
  // --- INYECCIÓN DE SERVICIOS ---
  // Instancia del servicio de Firebase para interactuar con la base de datos.
  final FirebaseService _firebaseService = FirebaseService();
  // Instancia del servicio de localización para obtener las coordenadas GPS.
  final LocationService _locationService = LocationService();
  // Paquete para generar identificadores únicos universales (UUIDs) para nuevos registros.
  final Uuid _uuid = Uuid();
  
  // --- ESTADO INTERNO DEL CONTROLADOR ---
  // Almacena el registro de asistencia activo o el último del día para el empleado.
  Asistencia? _asistenciaActiva;
  // Lista de asistencias, generalmente para mostrar historiales.
  List<Asistencia> _asistencias = [];
  // Indicador de si una operación asíncrona está en curso. Útil para mostrar spinners de carga.
  bool _cargando = false;
  // Mensaje de error en caso de que una operación falle. Útil para mostrar alertas.
  String? _mensajeError;

  // --- GETTERS PÚBLICOS (ACCESOS DE SOLO LECTURA AL ESTADO) ---
  Asistencia? get asistenciaActiva => _asistenciaActiva;
  List<Asistencia> get asistencias => _asistencias;
  bool get cargando => _cargando;
  String? get mensajeError => _mensajeError;

  // Método principal para verificar el estado de asistencia de un empleado para el día actual.
  //
  // @param empleadoId El ID del empleado a verificar.
  // @returns Un [Future] que resuelve a un valor del enum [AsistenciaStatus].
  Future<AsistenciaStatus> verificarEstadoAsistenciaEmpleado(String empleadoId) async {
    _cargando = true;
    _mensajeError = null;
    
    try {
      // Consulta a Firebase para obtener el registro de asistencia de hoy (completo o no).
      final asistenciaHoy = await _firebaseService.getTodayAsistencia(empleadoId);
      
      if (asistenciaHoy == null) {
        // Si no hay ningún registro para hoy.
        _asistenciaActiva = null;
        return AsistenciaStatus.debeMarcarEntrada;
      } else if (asistenciaHoy.fechaHoraSalida == null) {
        // Si hay un registro, pero le falta la fecha de salida.
        _asistenciaActiva = asistenciaHoy;
        return AsistenciaStatus.debeMarcarSalida;
      } else {
        // Si hay un registro y ya tiene fecha de salida.
        _asistenciaActiva = asistenciaHoy; // Se guarda para poder mostrar detalles de la jornada.
        return AsistenciaStatus.jornadaCompleta;
      }
    } catch (e) {
      _mensajeError = 'Error al verificar estado de asistencia: ${e.toString()}';
      return AsistenciaStatus.error;
    } finally {
      // Se ejecuta siempre, haya éxito o error.
      _cargando = false;
      notifyListeners(); // Notifica a los escuchas (la UI) que el estado ha cambiado.
    }
  }

  // Registra la entrada de un empleado.
  // @returns `true` si el registro fue exitoso, `false` si falló.
  Future<bool> registrarEntrada({
    required String empleadoId,
    required String sedeId,
    required String? capturaEntrada, // URL o ruta de la foto
  }) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();
    
    try {
      final tiempoDeRed = await TimeService.getCurrentNetworkTime();
      final asistenciaHoy = await _firebaseService.getTodayAsistencia(empleadoId);
      if (asistenciaHoy != null) {
        throw Exception('Ya tiene un registro de asistencia para el día de hoy.');
      }
      
      final sede = await _firebaseService.getSedeById(sedeId);
      if (sede == null) throw Exception('Sede no encontrada');
      
      final posicion = await _locationService.getCurrentPosition();
      
      final distancia = LocationHelper.calcularDistancia(
        posicion.latitude, posicion.longitude, sede.latitud, sede.longitud
      );
      
      if (distancia > sede.radioPermitido) {
        throw Exception('Está fuera del radio permitido para marcar asistencia.');
      }
      
      final nuevaAsistencia = Asistencia(
        id: _uuid.v4(), // Genera un ID único.
        empleadoId: empleadoId,
        sedeId: sedeId,
        fechaHoraEntrada: tiempoDeRed,
        latitudEntrada: posicion.latitude,
        longitudEntrada: posicion.longitude,
        capturaEntrada: capturaEntrada,
      );
      
      await _firebaseService.registrarEntrada(nuevaAsistencia);
      _asistenciaActiva = nuevaAsistencia;
      
      return true; // Éxito

    } catch (e) {
      _mensajeError = e.toString();
      return false; // Falla
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Registra la salida de un empleado.
  // @returns `true` si el registro fue exitoso, `false` si falló.
  Future<bool> registrarSalida({
    required String empleadoId,
    String? capturaSalida,
  }) async {
    _cargando = true;
    _mensajeError = null;
    notifyListeners();

    try {
      final tiempoDeRed = await TimeService.getCurrentNetworkTime();
      Asistencia? asistenciaParaCerrar = await _firebaseService.getTodayAsistencia(empleadoId);

      if (asistenciaParaCerrar == null || asistenciaParaCerrar.fechaHoraSalida != null) {
        throw Exception('No tiene una entrada registrada hoy para marcar salida.');
      }
      _asistenciaActiva = asistenciaParaCerrar;

      final posicion = await _locationService.getCurrentPosition();

      final datosSalida = {
        'latitudSalida': posicion.latitude,
        'longitudSalida': posicion.longitude,
        'capturaSalida': capturaSalida,
      };
      
      await _firebaseService.registrarSalida(asistenciaParaCerrar.id, datosSalida);
      
      _asistenciaActiva = _asistenciaActiva?.copyWith(
        fechaHoraSalida: tiempoDeRed, // Se usa tiempo de red para consistencia en la UI
        latitudSalida: posicion.latitude,
        longitudSalida: posicion.longitude,
        capturaSalida: capturaSalida,
      );
      
      return true;

    } catch (e) {
      _mensajeError = e.toString();
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // Limpia el estado del controlador, útil al cerrar sesión.
  void limpiarEstado() {
    _asistenciaActiva = null;
    _mensajeError = null;
    _asistencias = [];
    notifyListeners();
  }
}