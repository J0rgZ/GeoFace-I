// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_config.dart';
import '../models/empleado.dart';
import '../models/sede.dart';
import '../models/asistencia.dart';
import '../models/usuario.dart';

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

  // Get current user
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
        final data = snapshot.docs.first.data();
        print('Datos del usuario encontrado: $data'); // Para depuración
        return Usuario.fromJson({
          'id': snapshot.docs.first.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario por email: $e');
      throw e;
    }
  }

  Future<List<Asistencia>> getAllAsistencias() async {
    try {
      final querySnapshot = await _firestore
          .collection('asistencias')
          .orderBy('fechaHoraEntrada', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Asistencia.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener todas las asistencias: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias');
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
        final data = snapshot.docs.first.data();
        return Empleado.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error al buscar empleado por DNI: ${e.toString()}');
      throw Exception('No se pudo obtener el empleado por DNI');
    }
  }

  Future<void> addEmpleado(Empleado empleado) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).set(empleado.toJson());
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
    return snapshot.docs.map((doc) => Asistencia.fromJson(doc.data())).toList();
  }

  Future<List<Asistencia>> getAsistenciasBySede(String sedeId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('sedeId', isEqualTo: sedeId)
        .orderBy('fechaHoraEntrada', descending: true)
        .get();
    return snapshot.docs.map((doc) => Asistencia.fromJson(doc.data())).toList();
  }

  Future<Asistencia?> getActiveAsistencia(String empleadoId) async {
    final snapshot = await _firestore
        .collection(AppConfig.asistenciasCollection)
        .where('empleadoId', isEqualTo: empleadoId)
        .where('fechaHoraSalida', isNull: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return Asistencia.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

   Future<void> registrarEntrada(Asistencia asistencia) async {
    // Usamos el timestamp del servidor para la máxima fiabilidad.
    final data = asistencia.toJson();
    data['fechaHoraEntrada'] = FieldValue.serverTimestamp();
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistencia.id).set(data);
  }

  Future<void> registrarSalida(String asistenciaId, Map<String, dynamic> salidaData) async {
    // Actualizamos la asistencia existente con los datos de salida.
    final data = {...salidaData};
    data['fechaHoraSalida'] = FieldValue.serverTimestamp();
    await _firestore.collection(AppConfig.asistenciasCollection).doc(asistenciaId).update(data);
  }

  // Necesario para la lógica de salida en el controller
  Future<Asistencia?> getAsistenciaById(String id) async {
    final doc = await _firestore.collection(AppConfig.asistenciasCollection).doc(id).get();
    if (doc.exists) {
      return Asistencia.fromJson(doc.data()!);
    }
    return null;
  }

  /// Obtiene asistencias filtradas por un rango de fechas y opcionalmente por sede.
  /// Es mucho más eficiente que obtener todas las asistencias y filtrarlas en el cliente.
  Future<List<Asistencia>> getAsistenciasFiltradas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? sedeId,
  }) async {
    try {
      // Construimos la consulta base con el filtro de fecha
      Query query = _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: fechaInicio)
          .where('fechaHoraEntrada', isLessThan: fechaFin)
          .orderBy('fechaHoraEntrada', descending: true);

      // Si se proporciona un sedeId, añadimos ese filtro a la consulta
      if (sedeId != null && sedeId.isNotEmpty) {
        query = query.where('sedeId', isEqualTo: sedeId);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => Asistencia.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener asistencias filtradas: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias filtradas');
    }
  }

   /// Busca si existe una asistencia ya completada (con entrada y salida) para un empleado en el día actual.
  Future<Asistencia?> getCompletedAsistenciaForToday(String empleadoId) async {
    try {
      final now = DateTime.now();
      // Define el rango del día actual (desde las 00:00:00 hasta las 23:59:59)
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(AppConfig.asistenciasCollection)
          .where('empleadoId', isEqualTo: empleadoId)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: startOfDay)
          .where('fechaHoraEntrada', isLessThan: endOfDay)
          .where('fechaHoraSalida', isNotEqualTo: null) // La clave: que ya tenga hora de salida.
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Asistencia.fromJson(snapshot.docs.first.data());
      }
      return null; // No hay jornada completada hoy.
    } catch (e) {
      print('Error al buscar asistencia completada: $e');
      return null;
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
}