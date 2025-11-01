// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Asistencias
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `AsistenciaService`, que actúa como
//               una capa de servicio para todas las operaciones relacionadas con
//               asistencias en Firebase. Centraliza las operaciones CRUD con Cloud
//               Firestore para la colección de asistencias, incluyendo el registro
//               de entradas y salidas. Desacopla la lógica de la base de datos de
//               los controladores y la interfaz de usuario. Este enfoque mejora la
//               mantenibilidad y la organización del código.
//
// @NombreArchivo: asistencia_service.dart
// @Ubicacion:    lib/services/asistencia_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../app_config.dart';
import '../models/asistencia.dart';
import '../services/time_service.dart';

/// Clase de servicio para gestionar todas las operaciones relacionadas con asistencias.
///
/// Centraliza las operaciones de Firestore para la colección de asistencias,
/// manteniendo el código organizado y desacoplado de la lógica de la interfaz.
class AsistenciaService {
  // Instancia de Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene todos los registros de asistencia para un empleado específico, ordenados por fecha de entrada descendente.
  /// 
  /// IMPORTANTE: Este método debe ser usado solo después de validar que el empleadoId
  /// corresponde al usuario autenticado para evitar que usuarios vean datos de otros.
  Future<List<Asistencia>> getAsistenciasByEmpleado(String empleadoId) async {
    if (empleadoId.isEmpty) {
      throw Exception('El ID del empleado no puede estar vacío');
    }
    
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('empleadoId', isEqualTo: empleadoId)
        .orderBy('fechaHoraEntrada', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Asegura que el ID del documento se incluya en el objeto.
      return Asistencia.fromJson(data);
    }).toList();
  }

  /// Obtiene la asistencia activa (entrada registrada pero sin salida) para un empleado.
  ///
  /// Es útil para saber si un empleado está actualmente "trabajando".
  Future<Asistencia?> getActiveAsistencia(String empleadoId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('empleadoId', isEqualTo: empleadoId)
          .where('fechaHoraSalida', isNull: true) // La clave: busca registros sin fecha de salida.
          .orderBy('fechaHoraEntrada', descending: true) 
          .limit(1) // Solo nos interesa el más reciente.
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener asistencia activa: $e');
      throw Exception('No se pudo obtener la asistencia activa');
    }
  }

  /// Registra una nueva entrada de asistencia para un empleado.
  Future<void> registrarEntrada(Asistencia asistencia) async {
    final data = asistencia.toJson();
    // Convierte DateTime a Timestamp de Firestore para consistencia en la base de datos.
    data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
    // Guarda el timestamp del cliente como un número para propósitos de auditoría o comparación.
    data['networkTimestamp'] = asistencia.fechaHoraEntrada.millisecondsSinceEpoch;
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistencia.id).set(data);
  }

  /// Registra la salida para un registro de asistencia existente.
  ///
  /// @param asistenciaId El ID del documento de asistencia a actualizar.
  /// @param salidaData Un mapa con los datos de la salida (ej. ubicación, foto, etc.).
  Future<void> registrarSalida(String asistenciaId, Map<String, dynamic> salidaData) async {
    final data = {...salidaData};
    // Utiliza FieldValue.serverTimestamp() para asegurar que la hora de salida sea la del servidor de Firebase,
    // evitando inconsistencias por la hora del dispositivo del cliente.
    data['fechaHoraSalida'] = FieldValue.serverTimestamp();
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistenciaId).update(data);
  }

  /// Obtiene un único registro de asistencia por su ID de documento.
  Future<Asistencia?> getAsistenciaById(String id) async {
    final doc = await _firestore.collection(AppConfig.asistenciasCollection).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Asistencia.fromJson(data);
    }
    return null;
  }

  /// Obtiene todas las asistencias registradas el día de hoy.
  Future<List<Asistencia>> getAsistenciasDeHoy() async {
    // 1. Define el rango del día de hoy (desde las 00:00 hasta las 23:59)
    final ahora = DateTime.now();
    final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    // 2. Crea la consulta a Firestore
    final querySnapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('fechaHoraEntrada', isGreaterThanOrEqualTo: inicioDelDia)
        .where('fechaHoraEntrada', isLessThan: finDelDia)
        .get();

    // 3. Convierte los documentos a objetos Asistencia
    return querySnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Asistencia.fromJson(data);
        })
        .toList();
  }

  /// Obtiene una lista de asistencias filtrada por un rango de fechas y, opcionalmente, por una sede.
  Future<List<Asistencia>> getAsistenciasFiltradas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? sedeId,
  }) async {
    try {
      // Construcción de la consulta base.
      Query query = _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: fechaInicio)
          .where('fechaHoraEntrada', isLessThan: fechaFin) // Usar 'isLessThan' para el final del día es una práctica común.
          .orderBy('fechaHoraEntrada', descending: true);

      // Añade el filtro por sede si se proporciona un sedeId.
      if (sedeId != null && sedeId.isNotEmpty) {
        query = query.where('sedeId', isEqualTo: sedeId);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Asistencia.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener asistencias filtradas: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias filtradas');
    }
  }

  /// Verifica si un empleado ya completó su jornada de hoy (es decir, tiene una entrada Y una salida).
  /// Utiliza la hora de red para determinar el día actual de forma fiable.
  Future<Asistencia?> getCompletedAsistenciaForToday(String empleadoId) async {
    try {
      final networkTime = await TimeService.getCurrentNetworkTime();
      final startOfDay = DateTime(networkTime.year, networkTime.month, networkTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('empleadoId', isEqualTo: empleadoId)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: startOfDay)
          .where('fechaHoraEntrada', isLessThan: endOfDay)
          .where('fechaHoraSalida', isNotEqualTo: null) // Filtro clave: solo asistencias con salida.
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error al buscar asistencia completada para hoy: $e');
      return null; // Devuelve null en caso de error para no bloquear el flujo.
    }
  }

  /// Obtiene el registro de asistencia de un empleado para el día de hoy, ya sea que esté completa (con salida) o incompleta (solo entrada).
  /// Utiliza la hora de red para determinar el día actual.
  Future<Asistencia?> getTodayAsistencia(String empleadoId) async {
    try {
      final networkTime = await TimeService.getCurrentNetworkTime();
      final startOfDay = DateTime(networkTime.year, networkTime.month, networkTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('empleadoId', isEqualTo: empleadoId)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: startOfDay)
          .where('fechaHoraEntrada', isLessThan: endOfDay)
          .orderBy('fechaHoraEntrada', descending: true) // Ordena para obtener la más reciente del día.
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener asistencia del día: $e');
      throw Exception('No se pudo obtener la asistencia del día');
    }
  }

  /// Obtiene todos los registros de asistencia asociados a una sede específica.
  Future<List<Asistencia>> getAsistenciasBySede(String sedeId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('sedeId', isEqualTo: sedeId)
        .orderBy('fechaHoraEntrada', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Asistencia.fromJson(data);
    }).toList();
  }

  /// Obtiene todos los registros de asistencia de la base de datos, ordenados por fecha de entrada.
  /// Nota: Este método puede ser costoso en rendimiento si la colección es muy grande.
  Future<List<Asistencia>> getAllAsistencias() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .orderBy('fechaHoraEntrada', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Asistencia.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener todas las asistencias: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias');
    }
  }
}

