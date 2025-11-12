// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Notificaciones
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo contiene la lógica de negocio para la gestión de
//               notificaciones. Gestiona el estado de las notificaciones (carga y
//               errores) y coordina entre el servicio de notificaciones y las
//               notificaciones locales.
//
// @NombreControlador: NotificacionController
// @Ubicacion:    lib/controllers/notificacion_controller.dart
// @FechaInicio:  25/06/2025
// @FechaFin:     25/06/2025
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../services/notificacion_service.dart';
import '../services/notificacion_local_service.dart';
import '../models/notificacion.dart';
import '../services/empleado_service.dart';
import '../services/sede_service.dart';

/// Controlador que gestiona las notificaciones del sistema
class NotificacionController extends ChangeNotifier {
  final NotificacionService _notificacionService = NotificacionService();
  final NotificacionLocalService _localService = NotificacionLocalService();
  final EmpleadoService _empleadoService = EmpleadoService();
  final SedeService _sedeService = SedeService();

  List<Notificacion> _notificaciones = [];
  List<Notificacion> _notificacionesDeHoy = [];
  bool _loading = false;
  String? _errorMessage;
  bool _permisosConcedidos = false;

  // Getters públicos
  List<Notificacion> get notificaciones => _notificaciones;
  List<Notificacion> get notificacionesDeHoy => _notificacionesDeHoy;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get permisosConcedidos => _permisosConcedidos;

  int get notificacionesNoLeidas => _notificacionesDeHoy.where((n) => !n.leida).length;

  /// Inicializa el servicio de notificaciones locales
  Future<bool> inicializarNotificacionesLocales() async {
    try {
      _permisosConcedidos = await _localService.inicializar();
      notifyListeners();
      return _permisosConcedidos;
    } catch (e) {
      _errorMessage = 'Error al inicializar notificaciones: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Verifica si se tienen permisos para notificaciones
  Future<bool> verificarPermisos() async {
    try {
      _permisosConcedidos = await _localService.verificarPermisos();
      notifyListeners();
      return _permisosConcedidos;
    } catch (e) {
      _errorMessage = 'Error al verificar permisos: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Solicita permisos para notificaciones
  Future<bool> solicitarPermisos() async {
    try {
      _loading = true;
      _errorMessage = null;
      notifyListeners();

      _permisosConcedidos = await _localService.solicitarPermisos();
      _loading = false;
      notifyListeners();
      return _permisosConcedidos;
    } catch (e) {
      _loading = false;
      _errorMessage = 'Error al solicitar permisos: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Carga las notificaciones del día de hoy
  Future<void> cargarNotificacionesDeHoy() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificacionesDeHoy = await _notificacionService.getNotificacionesDeHoy();
    } catch (e) {
      _errorMessage = 'Error al cargar notificaciones: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Carga todas las notificaciones
  Future<void> cargarTodasLasNotificaciones({int? limit}) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notificaciones = await _notificacionService.getAllNotificaciones(limit: limit);
    } catch (e) {
      _errorMessage = 'Error al cargar notificaciones: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Crea una notificación de entrada de empleado
  Future<void> crearNotificacionEntrada({
    required String empleadoId,
    required String empleadoNombre,
    required String sedeId,
    required String sedeNombre,
    required DateTime fecha,
  }) async {
    try {
      final notificacion = Notificacion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tipo: TipoNotificacion.entrada,
        titulo: 'Entrada registrada',
        mensaje: '$empleadoNombre marcó entrada en $sedeNombre',
        empleadoId: empleadoId,
        empleadoNombre: empleadoNombre,
        sedeId: sedeId,
        sedeNombre: sedeNombre,
        fecha: fecha,
        leida: false,
      );

      await _notificacionService.crearNotificacion(notificacion);

      // Muestra notificación local si se tienen permisos
      if (_permisosConcedidos) {
        await _localService.mostrarNotificacion(
          id: fecha.millisecond,
          titulo: notificacion.titulo,
          cuerpo: notificacion.mensaje,
        );
      }

      // Recarga las notificaciones del día
      await cargarNotificacionesDeHoy();
    } catch (e) {
      debugPrint('Error al crear notificación de entrada: $e');
    }
  }

  /// Crea una notificación de salida de empleado
  Future<void> crearNotificacionSalida({
    required String empleadoId,
    required String empleadoNombre,
    required String sedeId,
    required String sedeNombre,
    required DateTime fecha,
  }) async {
    try {
      final notificacion = Notificacion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tipo: TipoNotificacion.salida,
        titulo: 'Salida registrada',
        mensaje: '$empleadoNombre marcó salida en $sedeNombre',
        empleadoId: empleadoId,
        empleadoNombre: empleadoNombre,
        sedeId: sedeId,
        sedeNombre: sedeNombre,
        fecha: fecha,
        leida: false,
      );

      await _notificacionService.crearNotificacion(notificacion);

      // Muestra notificación local si se tienen permisos
      if (_permisosConcedidos) {
        await _localService.mostrarNotificacion(
          id: fecha.millisecond + 1,
          titulo: notificacion.titulo,
          cuerpo: notificacion.mensaje,
        );
      }

      // Recarga las notificaciones del día
      await cargarNotificacionesDeHoy();
    } catch (e) {
      debugPrint('Error al crear notificación de salida: $e');
    }
  }

  /// Marca una notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      await _notificacionService.marcarComoLeida(notificacionId);
      await cargarNotificacionesDeHoy();
    } catch (e) {
      _errorMessage = 'Error al marcar notificación como leída: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      _loading = true;
      notifyListeners();

      await _notificacionService.marcarTodasComoLeidas();
      await cargarNotificacionesDeHoy();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _errorMessage = 'Error al marcar todas como leídas: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Elimina una notificación
  Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      await _notificacionService.eliminarNotificacion(notificacionId);
      await cargarNotificacionesDeHoy();
    } catch (e) {
      _errorMessage = 'Error al eliminar notificación: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Calcula estadísticas de ausentismo por sede
  Future<Map<String, dynamic>> calcularEstadisticasAusentismo() async {
    try {
      final notificacionesHoy = await _notificacionService.getNotificacionesDeHoy();
      final empleados = await _empleadoService.getEmpleados();
      final sedes = await _sedeService.getSedes();

      // Empleados que marcaron entrada hoy
      final empleadosConEntrada = notificacionesHoy
          .where((n) => n.tipo == TipoNotificacion.entrada)
          .map((n) => n.empleadoId)
          .toSet();

      // Empleados activos por sede
      final empleadosPorSede = <String, List<String>>{};
      for (var empleado in empleados) {
        if (empleado.activo) {
          empleadosPorSede.putIfAbsent(empleado.sedeId, () => []).add(empleado.id);
        }
      }

      // Calcular ausentismo por sede
      final estadisticas = <String, Map<String, dynamic>>{};
      for (var sede in sedes) {
        final empleadosSede = empleadosPorSede[sede.id] ?? [];
        final empleadosConEntradaSede = empleadosSede
            .where((id) => empleadosConEntrada.contains(id))
            .length;
        final ausentes = empleadosSede.length - empleadosConEntradaSede;
        final porcentajeAusentismo = empleadosSede.isEmpty
            ? 0.0
            : (ausentes / empleadosSede.length) * 100;

        estadisticas[sede.id] = {
          'sedeNombre': sede.nombre,
          'totalEmpleados': empleadosSede.length,
          'empleadosConEntrada': empleadosConEntradaSede,
          'ausentes': ausentes,
          'porcentajeAusentismo': porcentajeAusentismo,
        };
      }

      // Encontrar la sede con más ausentismo
      String? sedeConMasAusentismo;
      double maxAusentismo = 0.0;
      estadisticas.forEach((sedeId, stats) {
        if (stats['porcentajeAusentismo'] > maxAusentismo) {
          maxAusentismo = stats['porcentajeAusentismo'];
          sedeConMasAusentismo = sedeId;
        }
      });

      return {
        'estadisticas': estadisticas,
        'sedeConMasAusentismo': sedeConMasAusentismo,
        'maxAusentismo': maxAusentismo,
      };
    } catch (e) {
      debugPrint('Error al calcular estadísticas: $e');
      return {
        'estadisticas': <String, Map<String, dynamic>>{},
        'sedeConMasAusentismo': null,
        'maxAusentismo': 0.0,
      };
    }
  }

  /// Limpia el estado del controlador
  void clearState() {
    _notificaciones = [];
    _notificacionesDeHoy = [];
    _errorMessage = null;
    notifyListeners();
  }
}

