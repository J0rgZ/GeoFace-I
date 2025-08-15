import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/time_service.dart';
import '../models/asistencia.dart';
import '../utils/location_helper.dart';

/// Enum para representar de forma clara y segura los posibles estados de asistencia de un empleado.
/// Esto evita el uso de strings o booleanos que pueden llevar a errores.
enum AsistenciaStatus {
  /// El empleado no ha registrado entrada hoy.
  debeMarcarEntrada,
  /// El empleado ha registrado entrada pero no salida.
  debeMarcarSalida, 
  /// El empleado ya ha registrado entrada y salida hoy.
  jornadaCompleta,
  /// Ocurrió un error al verificar el estado.
  error,
}


/// Controlador para gestionar la lógica de negocio relacionada con el registro de asistencias.
///
/// Utiliza `ChangeNotifier` para que los widgets que lo escuchan puedan reconstruirse
/// automáticamente cuando el estado (como la lista de asistencias o el estado de carga) cambie.
class AsistenciaController extends ChangeNotifier {
  // --- INYECCIÓN DE SERVICIOS ---
  /// Instancia del servicio de Firebase para interactuar con la base de datos.
  final FirebaseService _firebaseService = FirebaseService();
  /// Instancia del servicio de localización para obtener las coordenadas GPS.
  final LocationService _locationService = LocationService();
  /// Paquete para generar identificadores únicos universales (UUIDs) para nuevos registros.
  final Uuid _uuid = Uuid();
  
  // --- ESTADO INTERNO DEL CONTROLADOR ---
  /// Almacena el registro de asistencia activo o el último del día para el empleado.
  Asistencia? _asistenciaActiva;
  /// Lista de asistencias, generalmente para mostrar historiales.
  List<Asistencia> _asistencias = [];
  /// Indicador de si una operación asíncrona está en curso. Útil para mostrar spinners de carga en la UI.
  bool _loading = false;
  /// Mensaje de error en caso de que una operación falle. Útil para mostrar alertas en la UI.
  String? _errorMessage;

  // --- GETTERS PÚBLICOS ---
  /// Proporciona acceso de solo lectura al estado de la asistencia activa.
  Asistencia? get asistenciaActiva => _asistenciaActiva;
  /// Proporciona acceso de solo lectura a la lista de asistencias.
  List<Asistencia> get asistencias => _asistencias;
  /// Proporciona acceso de solo lectura al estado de carga.
  bool get loading => _loading;
  /// Proporciona acceso de solo lectura al mensaje de error.
  String? get errorMessage => _errorMessage;

  /// Método principal para verificar el estado de asistencia de un empleado para el día actual.
  ///
  /// Este método determina si el empleado necesita marcar entrada, salida, si ya completó su jornada,
  /// o si ocurrió un error. Usa `getTodayAsistencia` del servicio de Firebase, que ya
  /// se encarga de la lógica de fechas usando la hora de red para mayor precisión.
  ///
  /// @param empleadoId El ID del empleado a verificar.
  /// @returns Un [Future] que resuelve a un valor del enum [AsistenciaStatus].
  Future<AsistenciaStatus> checkEmpleadoAsistenciaStatus(String empleadoId) async {
    _loading = true;
    _errorMessage = null;
    
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
      _errorMessage = 'Error al verificar estado de asistencia: ${e.toString()}';
      return AsistenciaStatus.error;
    } finally {
      // Se ejecuta siempre, haya éxito o error.
      _loading = false;
      notifyListeners(); // Notifica a los listeners (la UI) que el estado ha cambiado.
    }
  }

  /// Registra la entrada de un empleado.
  ///
  /// Realiza varias validaciones antes de registrar:
  /// 1. Obtiene la hora de red para evitar inconsistencias por la hora del dispositivo.
  /// 2. Confirma que no exista ya un registro para hoy.
  /// 3. Valida la existencia de la sede.
  /// 4. Obtiene la ubicación GPS y verifica que esté dentro del radio permitido de la sede (geofencing).
  ///
  /// @returns `true` si el registro fue exitoso, `false` si falló.
  Future<bool> registrarEntrada({
    required String empleadoId,
    required String sedeId,
    required String? capturaEntrada, // URL o path de la foto
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 1. Obtener hora de red para asegurar la marca de tiempo correcta.
      final networkTime = await TimeService.getCurrentNetworkTime();
      
      // 2. Verificación de seguridad para evitar registros duplicados en el mismo día.
      final asistenciaHoy = await _firebaseService.getTodayAsistencia(empleadoId);
      if (asistenciaHoy != null) {
        throw Exception('Ya tiene un registro de asistencia para el día de hoy.');
      }
      
      // 3. Obtener datos de la sede para el geofencing.
      final sede = await _firebaseService.getSedeById(sedeId);
      if (sede == null) throw Exception('Sede no encontrada');
      
      // 4. Obtener ubicación actual.
      final position = await _locationService.getCurrentPosition();
      
      // 5. Calcular distancia y validar si está dentro del radio.
      final distancia = LocationHelper.calcularDistancia(
        position.latitude, position.longitude, sede.latitud, sede.longitud
      );
      
      if (distancia > sede.radioPermitido) {
        throw Exception('Está fuera del radio permitido para marcar asistencia.');
      }
      
      // Si todas las validaciones pasan, se crea el objeto de asistencia.
      final nuevaAsistencia = Asistencia(
        id: _uuid.v4(), // Genera un ID único.
        empleadoId: empleadoId,
        sedeId: sedeId,
        fechaHoraEntrada: networkTime,
        latitudEntrada: position.latitude,
        longitudEntrada: position.longitude,
        capturaEntrada: capturaEntrada,
      );
      
      // Se guarda en Firebase y se actualiza el estado local.
      await _firebaseService.registrarEntrada(nuevaAsistencia);
      _asistenciaActiva = nuevaAsistencia;
      
      return true; // Éxito

    } catch (e) {
      _errorMessage = e.toString();
      return false; // Falla
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Registra la salida de un empleado.
  ///
  /// Busca una asistencia activa (sin salida) para el día de hoy y la actualiza con los
  /// datos de la salida.
  ///
  /// @returns `true` si el registro fue exitoso, `false` si falló.
  Future<bool> registrarSalida({
    required String empleadoId,
    String? capturaSalida,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final networkTime = await TimeService.getCurrentNetworkTime();
      
      // Intenta usar la asistencia activa ya cargada en el estado local.
      Asistencia? asistenciaParaCerrar = _asistenciaActiva;
      
      // Si no hay una en el estado local, la busca en Firebase.
      // Esto es un respaldo en caso de que el estado se haya perdido (ej. app reiniciada).
      if (asistenciaParaCerrar == null) {
        asistenciaParaCerrar = await _firebaseService.getTodayAsistencia(empleadoId);
        // Valida que exista una asistencia y que no tenga ya una salida.
        if (asistenciaParaCerrar == null || asistenciaParaCerrar.fechaHoraSalida != null) {
          throw Exception('No tiene una entrada registrada hoy para marcar salida.');
        }
        _asistenciaActiva = asistenciaParaCerrar; // Actualiza el estado local.
      }

      // Validación de seguridad: Asegura que la entrada que se va a cerrar sea del día de hoy.
      final startOfDay = DateTime(networkTime.year, networkTime.month, networkTime.day);
      if (asistenciaParaCerrar.fechaHoraEntrada.isBefore(startOfDay)) {
        throw Exception('La entrada registrada no corresponde al día de hoy.');
      }

      final position = await _locationService.getCurrentPosition();

      // Prepara los datos a actualizar en el documento de Firebase.
      final salidaData = {
        'latitudSalida': position.latitude,
        'longitudSalida': position.longitude,
        'capturaSalida': capturaSalida,
        'networkTimestampSalida': networkTime.millisecondsSinceEpoch, // Timestamp de red para auditoría.
      };
      
      await _firebaseService.registrarSalida(asistenciaParaCerrar.id, salidaData);
      
      // Actualiza el objeto local para reflejar inmediatamente los cambios en la UI.
      _asistenciaActiva = _asistenciaActiva?.copyWith(
        fechaHoraSalida: networkTime,
        latitudSalida: position.latitude,
        longitudSalida: position.longitude,
        capturaSalida: capturaSalida,
      );
      
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Obtiene el historial de asistencias para un empleado específico.
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

  /// Obtiene el historial de asistencias de todos los empleados.
  /// Nota: Puede ser una operación costosa si hay muchos registros.
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

  /// Limpia el estado del controlador.
  ///
  /// Es útil llamar a este método, por ejemplo, cuando el usuario cierra sesión,
  /// para evitar mostrar datos de un usuario anterior.
  void clearState() {
    _asistenciaActiva = null;
    _errorMessage = null;
    _asistencias = [];
    notifyListeners();
  }

  /// Vuelve a ejecutar la verificación de estado de asistencia.
  ///
  /// Es un método de conveniencia útil para acciones como "deslizar para refrescar" en la UI.
  Future<void> refreshAsistenciaStatus(String empleadoId) async {
    await checkEmpleadoAsistenciaStatus(empleadoId);
  }
}