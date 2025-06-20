// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geoface/models/api_config.dart';
import '../app_config.dart';
import '../models/empleado.dart';
import '../models/sede.dart';
import '../models/asistencia.dart';
import '../models/usuario.dart';
import '../services/time_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth methods
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Usuario methods
  Future<Usuario?> getUsuarioByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return Usuario.fromJson({
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario por email: $e');
      throw e;
    }
  }

  // Empleado methods
  Future<List<Empleado>> getEmpleados() async {
    final snapshot = await _firestore.collection(AppConfig.empleadosCollection).get();
    return snapshot.docs.map((doc) => Empleado.fromJson(doc.data())).toList();
  }

  Future<Empleado?> getEmpleadoById(String id) async {
    final doc = await _firestore.collection(AppConfig.empleadosCollection).doc(id).get();
    if (doc.exists) {
      return Empleado.fromJson(doc.data()!);
    }
    return null;
  }

  Future<Empleado?> getEmpleadoByDNI(String dni) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.empleadosCollection)
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Empleado.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error al buscar empleado por DNI: ${e.toString()}');
      throw Exception('No se pudo obtener el empleado por DNI');
    }
  }

  Future<void> addEmpleado(Empleado empleado) async {
    final docRef = _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id);
    await docRef.set(empleado.toJson());
  }

  Future<void> updateEmpleado(Empleado empleado) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).update(empleado.toJson());
  }

  Future<void> deleteEmpleado(String id) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(id).delete();
  }

  // Sede methods
  Future<List<Sede>> getSedes() async {
    final snapshot = await _firestore.collection(AppConfig.sedesCollection).get();
    return snapshot.docs.map((doc) => Sede.fromJson(doc.data())).toList();
  }

  Future<Sede?> getSedeById(String id) async {
    final doc = await _firestore.collection(AppConfig.sedesCollection).doc(id).get();
    if (doc.exists) {
      return Sede.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> addSede(Sede sede) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(sede.id).set(sede.toJson());
  }

  Future<void> updateSede(Sede sede) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(sede.id).update(sede.toJson());
  }

  Future<void> deleteSede(String id) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(id).delete();
  }

  // Asistencia methods
  Future<List<Asistencia>> getAsistenciasByEmpleado(String empleadoId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('empleadoId', isEqualTo: empleadoId)
        .orderBy('fechaHoraEntrada', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Asegurar que el ID esté incluido
      return Asistencia.fromJson(data);
    }).toList();
  }

  /// Obtiene la asistencia activa (entrada sin salida) para un empleado
  Future<Asistencia?> getActiveAsistencia(String empleadoId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('empleadoId', isEqualTo: empleadoId)
          .where('fechaHoraSalida', isNull: true)
          .orderBy('fechaHoraEntrada', descending: true) // Obtener la más reciente
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id; // Asegurar que el ID esté incluido
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener asistencia activa: $e');
      throw Exception('No se pudo obtener la asistencia activa');
    }
  }

  Future<void> registrarEntrada(Asistencia asistencia) async {
    final data = asistencia.toJson();
    // Usar Timestamp de Firestore para la fecha de entrada
    data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
    // Agregar timestamp de hora de red para auditoria
    data['networkTimestamp'] = asistencia.fechaHoraEntrada.millisecondsSinceEpoch;
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistencia.id).set(data);
  }

  Future<void> registrarSalida(String asistenciaId, Map<String, dynamic> salidaData) async {
    final data = {...salidaData};
    // Usar FieldValue.serverTimestamp() para la fecha de salida
    data['fechaHoraSalida'] = FieldValue.serverTimestamp();
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistenciaId).update(data);
  }

  Future<Asistencia?> getAsistenciaById(String id) async {
    final doc = await _firestore.collection(AppConfig.asistenciasCollection).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Asistencia.fromJson(data);
    }
    return null;
  }

  Future<List<Asistencia>> getAsistenciasFiltradas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? sedeId,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: fechaInicio)
          .where('fechaHoraEntrada', isLessThan: fechaFin)
          .orderBy('fechaHoraEntrada', descending: true);

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
      print('Error al obtener asistencias filtradas: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias filtradas');
    }
  }

  /// Verifica si un empleado ya completó su jornada HOY (entrada Y salida)
  /// Usa hora de red para determinar "hoy"
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
          .where('fechaHoraSalida', isNotEqualTo: null) // Solo asistencias COMPLETAS
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al buscar asistencia completada para hoy: $e');
      return null;
    }
  }

  /// Nuevo método: Obtiene la asistencia del día (completa o incompleta)
  /// Usa hora de red para determinar "hoy"
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
          .orderBy('fechaHoraEntrada', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error al obtener asistencia del día: $e');
      throw Exception('No se pudo obtener la asistencia del día');
    }
  }

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

  Future<List<Asistencia>> getAllAsistencias() async {
    try {
      final querySnapshot = await _firestore
          .collection('asistencias')
          .orderBy('fechaHoraEntrada', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Asistencia.fromMap(data);
          })
          .toList();
    } catch (e) {
      print('Error al obtener todas las asistencias: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias');
    }
  }

  // --- MÉTODOS DE ADMINISTRADOR ---

  /// Obtiene una lista de todos los usuarios con el rol de Administrador.
  Future<List<Usuario>> getAdministradores() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'ADMIN')
          .get();

      if (snapshot.docs.isEmpty) {
        return []; // Retorna una lista vacía si no hay administradores
      }

      return snapshot.docs.map((doc) {
        return Usuario.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      print('Error al obtener administradores desde el servicio: $e');
      throw Exception('No se pudieron cargar los administradores.');
    }
  }

  sendPasswordResetEmail(String correo) {}

  // --- MÉTODOS PARA LA CONFIGURACIÓN DE LA API (VERSIÓN MEJORADA) ---
  /// Guarda el objeto de configuración completo de la API en Firestore.
  Future<void> saveApiConfig(ApiConfig config) async {
    try {
      await _firestore.collection('app_config').doc('settings').set(
        config.toMap(), 
        SetOptions(merge: true)
      );
    } catch (e) {
      print("Error al guardar la configuración de la API: $e");
      throw Exception("No se pudo guardar la configuración. Inténtalo de nuevo.");
    }
  }

  /// Obtiene el objeto de configuración completo de la API desde Firestore.
  Future<ApiConfig> getApiConfig() async {
    try {
      final docSnapshot = await _firestore.collection('app_config').doc('settings').get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ApiConfig.fromMap(docSnapshot.data()!);
      }
      // Si no existe, devuelve una configuración vacía.
      return ApiConfig.empty;
    } catch (e) {
      print("Error al obtener la configuración de la API: $e");
      throw Exception("No se pudo cargar la configuración de la API.");
    }
  }
}