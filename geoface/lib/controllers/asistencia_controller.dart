// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Asistencia
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo contiene la lógica de negocio para el registro de
//               asistencias de los empleados. Gestiona la verificación del
//               estado de asistencia (entrada/salida), el registro de marcas
//               con validación de geocercas (geofencing), y la obtención de
//               historiales de asistencia, interactuando con los servicios de
//               Firebase, localización y tiempo de red.
//
// @NombreControlador: AsistenciaController
// @Ubicacion:    lib/controllers/asistencia_controller.dart // (o la ruta que corresponda)
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

// Define los posibles estados de la jornada laboral de un empleado en un día.
enum AsistenciaStatus {
  debeMarcarEntrada,
  debeMarcarSalida, 
  jornadaCompleta,
  error,
}

// Controlador que encapsula toda la lógica de negocio para la gestión de asistencias.
class AsistenciaController extends ChangeNotifier {
  // --- INYECCIÓN DE SERVICIOS ---
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  final Uuid _uuid = Uuid();
  
  // --- ESTADO INTERNO DEL CONTROLADOR ---
  Asistencia? _asistenciaActiva;
  List<Asistencia> _asistencias = [];
  bool _loading = false;
  String? _errorMessage;

  // --- GETTERS PÚBLICOS ---
  // Proporcionan acceso de solo lectura al estado para la UI.
  Asistencia? get asistenciaActiva => _asistenciaActiva;
  List<Asistencia> get asistencias => _asistencias;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  List<Asistencia> _asistenciasDeHoy = [];

  List<Asistencia> get asistenciasDeHoy => _asistenciasDeHoy;

  // Verifica el estado actual de la asistencia de un empleado para el día de hoy.
  // Este método determina qué botón (Entrada o Salida) debe mostrar la UI.
  Future<AsistenciaStatus> checkEmpleadoAsistenciaStatus(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    
    try {
      final asistenciaHoy = await _firebaseService.getTodayAsistencia(empleadoId);
      
      if (asistenciaHoy == null) {
        _asistenciaActiva = null;
        return AsistenciaStatus.debeMarcarEntrada;
      } else if (asistenciaHoy.fechaHoraSalida == null) {
        _asistenciaActiva = asistenciaHoy;
        return AsistenciaStatus.debeMarcarSalida;
      } else {
        _asistenciaActiva = asistenciaHoy;
        return AsistenciaStatus.jornadaCompleta;
      }
    } catch (e) {
      _errorMessage = 'Error al verificar estado de asistencia: ${e.toString()}';
      return AsistenciaStatus.error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Registra la marca de entrada de un empleado.
  Future<bool> registrarEntrada({
    required String empleadoId,
    required String sedeId,
    required String? capturaEntrada,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 1. Obtiene la hora de un servidor NTP para evitar fraudes por cambio de hora en el dispositivo.
      final networkTime = await TimeService.getCurrentNetworkTime();
      
      // 2. Verifica que no exista ya un registro para hoy, evitando duplicados.
      final asistenciaHoy = await _firebaseService.getTodayAsistencia(empleadoId);
      if (asistenciaHoy != null) {
        throw Exception('Ya tiene un registro de asistencia para el día de hoy.');
      }
      
      // 3. Obtiene los datos de la sede para validar la ubicación.
      final sede = await _firebaseService.getSedeById(sedeId);
      if (sede == null) throw Exception('Sede no encontrada');
      
      // 4. Obtiene la ubicación GPS actual del dispositivo.
      final position = await _locationService.getCurrentPosition();
      
      // 5. Valida si el empleado está dentro del radio permitido (geofencing).
      final distancia = LocationHelper.calcularDistancia(
        position.latitude, position.longitude, sede.latitud, sede.longitud
      );
      if (distancia > sede.radioPermitido) {
        throw Exception('Está fuera del radio permitido para marcar asistencia.');
      }
      
      // Si todas las validaciones son correctas, se crea y guarda el nuevo registro.
      final nuevaAsistencia = Asistencia(
        id: _uuid.v4(),
        empleadoId: empleadoId,
        sedeId: sedeId,
        fechaHoraEntrada: networkTime,
        latitudEntrada: position.latitude,
        longitudEntrada: position.longitude,
        capturaEntrada: capturaEntrada,
      );
      
      await _firebaseService.registrarEntrada(nuevaAsistencia);
      _asistenciaActiva = nuevaAsistencia;
      
      return true;

    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Registra la marca de salida de un empleado.
  Future<bool> registrarSalida({
    required String empleadoId,
    String? capturaSalida,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final networkTime = await TimeService.getCurrentNetworkTime();
      
      // Optimización: Intenta usar la asistencia activa ya cargada en el estado local.
      Asistencia? asistenciaParaCerrar = _asistenciaActiva;
      
      // Si el estado se perdió (ej. app cerrada), busca la asistencia en Firebase como respaldo.
      if (asistenciaParaCerrar == null) {
        asistenciaParaCerrar = await _firebaseService.getTodayAsistencia(empleadoId);
        if (asistenciaParaCerrar == null || asistenciaParaCerrar.fechaHoraSalida != null) {
          throw Exception('No tiene una entrada registrada hoy para marcar salida.');
        }
        _asistenciaActiva = asistenciaParaCerrar;
      }

      // Validación de seguridad: Asegura que la entrada que se va a cerrar sea del día de hoy.
      final startOfDay = DateTime(networkTime.year, networkTime.month, networkTime.day);
      if (asistenciaParaCerrar.fechaHoraEntrada.isBefore(startOfDay)) {
        throw Exception('La entrada registrada no corresponde al día de hoy.');
      }

      final position = await _locationService.getCurrentPosition();

      // Prepara los datos que se actualizarán en el documento de Firestore.
      final salidaData = {
        'latitudSalida': position.latitude,
        'longitudSalida': position.longitude,
        'capturaSalida': capturaSalida,
        'fechaHoraSalida': networkTime,
      };
      
      await _firebaseService.registrarSalida(asistenciaParaCerrar.id, salidaData);
      
      // Actualiza el objeto local para que la UI refleje el cambio instantáneamente.
      _asistenciaActiva = _asistenciaActiva?.copyWith(
        fechaHoraSalida: networkTime,
        latitudSalida: position.latitude,
        longitudSalida: position.longitude,
        capturaSalida: capturaSalida,
      );
      
      return true;

    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Obtiene el historial de asistencias para un empleado específico.
  Future<void> getAsistenciasByEmpleado(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _asistencias = await _firebaseService.getAsistenciasByEmpleado(empleadoId);
    } catch (e) {
      _errorMessage = 'Error al cargar asistencias: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> getAsistenciasDeHoy() async {
    _loading = true;
    _errorMessage = null;
    // No notificamos aquí para no causar un parpadeo si _loadData usa Future.wait
    
    try {
      // Tu FirebaseService necesitará un método que haga una consulta filtrada por fecha.
      _asistenciasDeHoy = await _firebaseService.getAsistenciasDeHoy();
    } catch (e) {
      _errorMessage = 'Error al cargar asistencias de hoy: ${e.toString()}';
    } finally {
      _loading = false;
      // Notificamos solo al final o dejamos que el Future.wait maneje el estado de la UI.
    }
  }

  // Limpia el estado del controlador.
  // Es útil llamar a este método al cerrar sesión para evitar mostrar datos de un usuario anterior.
  void clearState() {
    _asistenciaActiva = null;
    _errorMessage = null;
    _asistencias = [];
    notifyListeners();
  }

  // Vuelve a ejecutar la verificación de estado de asistencia.
  // Útil para acciones como "deslizar para refrescar" en la UI.
  Future<void> refreshAsistenciaStatus(String empleadoId) async {
    await checkEmpleadoAsistenciaStatus(empleadoId);
  }
}