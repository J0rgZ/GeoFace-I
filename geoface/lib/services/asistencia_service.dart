// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Gestión de Asistencias
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Esta clase actúa como la capa de acceso a datos para todo lo
//               relacionado con los registros de asistencia. Centraliza todas
//               las operaciones de Firestore (lectura, escritura, actualización)
//               para el modelo Asistencia, proveyendo una API limpia para el
//               resto de la aplicación.
//
// @NombreArchivo: asistencia_service.dart
// @Ubicacion:    lib/services/asistencia_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: 1
// @Fecha:        22/08/2025
// @Autor:        Gemini
// @Descripción:  Se tradujeron todos los comentarios al español, se cambió el
//               estilo de /// a // y se corrigió el método `getAllAsistencias`
//               para que use `Asistencia.fromJson` en lugar del obsoleto
//               `Asistencia.fromMap`.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/asistencia.dart';
import '../app_config.dart'; 
import '../services/time_service.dart';

class AsistenciaService { 
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------------------------------------------------------
  // --- MÉTODOS DE ASISTENCIA ---
  // ------------------------------------------------------------------

  // Obtiene todos los registros de asistencia para un empleado específico, ordenados por fecha de entrada descendente.
  Future<List<Asistencia>> getAsistenciasByEmpleado(String empleadoId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where(Asistencia.campoEmpleadoId, isEqualTo: empleadoId)
        .orderBy(Asistencia.campoFechaHoraEntrada, descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Asegura que el ID del documento se incluya en el objeto.
      return Asistencia.fromJson(data);
    }).toList();
  }

  // Obtiene la asistencia activa (entrada registrada pero sin salida) para un empleado.
  // Es útil para saber si un empleado está actualmente "trabajando".
  Future<Asistencia?> getActiveAsistencia(String empleadoId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .where(Asistencia.campoEmpleadoId, isEqualTo: empleadoId)
          .where(Asistencia.campoFechaHoraSalida, isNull: true) // La clave: busca registros sin fecha de salida.
          .orderBy(Asistencia.campoFechaHoraEntrada, descending: true) 
          .limit(1) // Solo nos interesa el más reciente.
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('No se pudo obtener la asistencia activa');
    }
  }

  // Registra una nueva entrada de asistencia para un empleado.
  Future<void> registrarEntrada(Asistencia asistencia) async {
    final data = asistencia.toJson();
    // Convierte DateTime a Timestamp de Firestore para consistencia en la base de datos.
    data[Asistencia.campoFechaHoraEntrada] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistencia.id).set(data);
  }

  // Registra la salida para un registro de asistencia existente.
  // @param asistenciaId El ID del documento de asistencia a actualizar.
  // @param salidaData Un mapa con los datos de la salida (ej. ubicación, foto, etc.).
  Future<void> registrarSalida(String asistenciaId, Map<String, dynamic> salidaData) async {
    final data = {...salidaData};
    // Utiliza FieldValue.serverTimestamp() para asegurar que la hora de salida sea la del servidor.
    data[Asistencia.campoFechaHoraSalida] = FieldValue.serverTimestamp();
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistenciaId).update(data);
  }

  // Obtiene un único registro de asistencia por su ID de documento.
  Future<Asistencia?> getAsistenciaById(String id) async {
    final doc = await _firestore.collection(AppConfig.asistenciasCollection).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Asistencia.fromJson(data);
    }
    return null;
  }

  // Obtiene una lista de asistencias filtrada por un rango de fechas y, opcionalmente, por una sede.
  Future<List<Asistencia>> getAsistenciasFiltradas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? sedeId,
  }) async {
    try {
      // Construcción de la consulta base.
      Query query = _firestore
          .collection(AppConfig.asistenciasCollection)
          .where(Asistencia.campoFechaHoraEntrada, isGreaterThanOrEqualTo: fechaInicio)
          .where(Asistencia.campoFechaHoraEntrada, isLessThan: fechaFin)
          .orderBy(Asistencia.campoFechaHoraEntrada, descending: true);

      // Añade el filtro por sede si se proporciona un sedeId.
      if (sedeId != null && sedeId.isNotEmpty) {
        query = query.where(Asistencia.campoSedeId, isEqualTo: sedeId);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Asistencia.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener asistencias filtradas: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias filtradas');
    }
  }

  // Obtiene el registro de asistencia de un empleado para el día de hoy, ya sea que esté completa o incompleta.
  // Utiliza la hora de red para determinar el día actual.
  Future<Asistencia?> getTodayAsistencia(String empleadoId) async {
    try {
      final networkTime = await TimeService.getCurrentNetworkTime();
      final inicioDelDia = DateTime(networkTime.year, networkTime.month, networkTime.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .where(Asistencia.campoEmpleadoId, isEqualTo: empleadoId)
          .where(Asistencia.campoFechaHoraEntrada, isGreaterThanOrEqualTo: inicioDelDia)
          .where(Asistencia.campoFechaHoraEntrada, isLessThan: finDelDia)
          .orderBy(Asistencia.campoFechaHoraEntrada, descending: true) // Ordena para obtener la más reciente del día.
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('No se pudo obtener la asistencia del día');
    }
  }

  // Obtiene todos los registros de asistencia de la base de datos, ordenados por fecha de entrada.
  // Nota: Este método puede ser costoso en rendimiento si la colección es muy grande.
  Future<List<Asistencia>> getAllAsistencias() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .orderBy(Asistencia.campoFechaHoraEntrada, descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // ** SOLUCIÓN AL ERROR **
        // Se cambió Asistencia.fromMap(data) por Asistencia.fromJson(data)
        // para coincidir con el constructor factory definido en tu modelo.
        return Asistencia.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('No se pudieron cargar las asistencias');
    }
  }
}