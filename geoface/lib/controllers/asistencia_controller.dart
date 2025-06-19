import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/time_service.dart';
import '../models/asistencia.dart';
import '../utils/location_helper.dart';

class AsistenciaController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  final Uuid _uuid = Uuid();
  
  Asistencia? _asistenciaActiva;
  List<Asistencia> _asistencias = [];
  bool _loading = false;
  String? _errorMessage;

  Asistencia? get asistenciaActiva => _asistenciaActiva;
  List<Asistencia> get asistencias => _asistencias;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  /// Método principal para verificar el estado de asistencia de un empleado HOY
  Future<AsistenciaStatus> checkEmpleadoAsistenciaStatus(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    
    try {
      // Usar el método de Firebase directamente que ya maneja la hora de red
      final asistenciaHoy = await _firebaseService.getTodayAsistencia(empleadoId);
      
      if (asistenciaHoy == null) {
        // No tiene asistencia hoy -> debe marcar ENTRADA
        _asistenciaActiva = null;
        return AsistenciaStatus.debeMarcarEntrada;
      } else if (asistenciaHoy.fechaHoraSalida == null) {
        // Tiene entrada pero no salida -> debe marcar SALIDA
        _asistenciaActiva = asistenciaHoy;
        return AsistenciaStatus.debeMarcarSalida;
      } else {
        // Tiene entrada Y salida -> jornada completa
        _asistenciaActiva = asistenciaHoy; // CORRECCIÓN: Mantener la referencia para mostrar detalles
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

  /// Registrar entrada (solo si no tiene asistencia hoy)
  Future<bool> registrarEntrada({
    required String empleadoId,
    required String sedeId,
    required String? capturaEntrada,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Obtener hora de red para la marcación
      final networkTime = await TimeService.getCurrentNetworkTime();
      
      // Verificación de seguridad: ¿Ya tiene asistencia hoy? (usando el método de Firebase)
      final asistenciaHoy = await _firebaseService.getTodayAsistencia(empleadoId);
      if (asistenciaHoy != null) {
        throw Exception('Ya tiene un registro de asistencia para el día de hoy.');
      }
      
      final sede = await _firebaseService.getSedeById(sedeId);
      if (sede == null) throw Exception('Sede no encontrada');
      
      final position = await _locationService.getCurrentPosition();
      
      final distancia = LocationHelper.calcularDistancia(
        position.latitude, position.longitude, sede.latitud, sede.longitud
      );
      
      if (distancia > sede.radioPermitido) {
        throw Exception('Está fuera del radio permitido para marcar asistencia.');
      }
      
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
      
      _loading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registrar salida (solo si tiene entrada sin salida hoy)
  Future<bool> registrarSalida({
    required String empleadoId,
    String? capturaSalida,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obtener hora de red para la marcación
      final networkTime = await TimeService.getCurrentNetworkTime();
      
      // Primero verificar si hay asistencia activa en el estado local
      Asistencia? asistenciaActiva = _asistenciaActiva;
      
      // Si no hay en el estado local, buscar en Firebase
      if (asistenciaActiva == null) {
        asistenciaActiva = await _firebaseService.getTodayAsistencia(empleadoId);
        if (asistenciaActiva == null || asistenciaActiva.fechaHoraSalida != null) {
          throw Exception('No tiene una entrada registrada para marcar salida.');
        }
        _asistenciaActiva = asistenciaActiva; // Actualizar estado local
      }

      // Verificar que la asistencia activa sea de HOY (usando hora de red)
      final startOfDay = DateTime(networkTime.year, networkTime.month, networkTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      if (asistenciaActiva.fechaHoraEntrada.isBefore(startOfDay) || 
          asistenciaActiva.fechaHoraEntrada.isAfter(endOfDay)) {
        throw Exception('La entrada registrada no corresponde al día de hoy.');
      }

      final position = await _locationService.getCurrentPosition();

      final salidaData = {
        'latitudSalida': position.latitude,
        'longitudSalida': position.longitude,
        'capturaSalida': capturaSalida,
        // Agregar timestamp de hora de red
        'networkTimestamp': networkTime.millisecondsSinceEpoch,
      };
      
      await _firebaseService.registrarSalida(asistenciaActiva.id, salidaData);
      
      // Actualizar la asistencia local con los datos de salida
      _asistenciaActiva = Asistencia(
        id: asistenciaActiva.id,
        empleadoId: asistenciaActiva.empleadoId,
        sedeId: asistenciaActiva.sedeId,
        fechaHoraEntrada: asistenciaActiva.fechaHoraEntrada,
        fechaHoraSalida: networkTime, // Actualizar con la hora de salida
        latitudEntrada: asistenciaActiva.latitudEntrada,
        longitudEntrada: asistenciaActiva.longitudEntrada,
        latitudSalida: position.latitude,
        longitudSalida: position.longitude,
        capturaEntrada: asistenciaActiva.capturaEntrada,
        capturaSalida: capturaSalida,
      );
      
      _loading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Métodos existentes sin cambios
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

  Future<void> getAllAsistencias() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _asistencias = await _firebaseService.getAllAsistencias();
    } catch (e) {
      _errorMessage = 'Error al cargar todas las asistencias: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Método para limpiar estado cuando sea necesario
  void clearState() {
    _asistenciaActiva = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// NUEVO: Método para refrescar el estado después de una operación
  Future<void> refreshAsistenciaStatus(String empleadoId) async {
    await checkEmpleadoAsistenciaStatus(empleadoId);
  }
}

// Enum para clarificar el estado de asistencia
enum AsistenciaStatus {
  debeMarcarEntrada,
  debeMarcarSalida, 
  jornadaCompleta,
  error,
}