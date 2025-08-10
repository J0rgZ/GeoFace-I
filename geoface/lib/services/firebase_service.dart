// services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/api_config.dart';
import '../models/empleado.dart';
import '../models/sede.dart';
import '../models/asistencia.dart';
import '../models/usuario.dart';
import '../models/network_time_result.dart';
import '../services/time_service.dart';

/// Servicio centralizado para todas las interacciones con Firebase.
///
/// Encapsula la lógica de Firestore y FirebaseAuth, proveyendo una API
/// limpia y robusta al resto de la aplicación. Utiliza inyección de
/// dependencias para el [TimeService], lo que mejora la testabilidad.
class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TimeService _timeService;

  /// Constructor que recibe las instancias de los servicios de Firebase
  /// y nuestro TimeService personalizado.
  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    TimeService? timeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _timeService = timeService ?? const TimeService();

  // --- MÉTODOS DE AUTENTICACIÓN ---

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- MÉTODOS CRUD (Create, Read, Update, Delete) ---

  // --- Métodos para Usuario ---

  Future<Usuario?> getUsuarioByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        return Usuario.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener usuario por email: $e');
      throw Exception('No se pudo obtener la información del usuario.');
    }
  }

  // --- Métodos para Empleado ---

  Future<List<Empleado>> getEmpleados() async {
    try {
      final snapshot = await _firestore.collection('empleados').get();
      return _mapDocsToList<Empleado>(snapshot.docs, Empleado.fromJson);
    } catch (e) {
      debugPrint('Error al obtener empleados: $e');
      throw Exception('No se pudieron cargar los empleados.');
    }
  }

  Future<void> setEmpleado(Empleado empleado) async {
    try {
      await _firestore.collection('empleados').doc(empleado.id).set(empleado.toJson());
    } catch (e) {
      debugPrint('Error al guardar empleado: $e');
      throw Exception('No se pudo guardar la información del empleado.');
    }
  }
  
  // --- Métodos para Sede ---

  Future<List<Sede>> getSedes() async {
    try {
      final snapshot = await _firestore.collection('sedes').get();
      return _mapDocsToList<Sede>(snapshot.docs, Sede.fromJson);
    } catch (e) {
      debugPrint('Error al obtener las sedes: $e');
      throw Exception('No se pudieron cargar las sedes.');
    }
  }

  Future<Sede?> getSedeById(String id) async {
    try {
      final doc = await _firestore.collection('sedes').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Sede.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener sede por ID $id: $e');
      throw Exception('No se pudo obtener la información de la sede.');
    }
  }

  Future<void> setSede(Sede sede) async {
    try {
      await _firestore.collection('sedes').doc(sede.id).set(sede.toJson());
    } catch (e) {
      debugPrint('Error al guardar la sede con ID ${sede.id}: $e');
      throw Exception('No se pudo guardar la información de la sede.');
    }
  }

  Future<void> updateSedeStatus(String id, bool activa) async {
    try {
      await _firestore.collection('sedes').doc(id).update({
        Sede.fieldActiva: activa,
        Sede.fieldFechaModificacion: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al actualizar el estado de la sede con ID $id: $e');
      throw Exception('No se pudo cambiar el estado de la sede.');
    }
  }

  Future<void> deleteSede(String id) async {
    try {
      await _firestore.collection('sedes').doc(id).delete();
    } catch (e) {
      debugPrint('Error al eliminar la sede con ID $id: $e');
      throw Exception('No se pudo eliminar la sede.');
    }
  }

  // --- Métodos para Asistencia ---

  Future<void> registrarEntrada(Asistencia asistencia) async {
    try {
      final data = asistencia.toJson();
      data[Asistencia.fieldFechaHoraEntrada] = FieldValue.serverTimestamp();
      await _firestore.collection('asistencias').doc(asistencia.id).set(data);
    } catch (e) {
      debugPrint('Error al registrar entrada: $e');
      throw Exception('No se pudo registrar la entrada.');
    }
  }

  Future<void> registrarSalida(String asistenciaId, Map<String, dynamic> salidaData) async {
    try {
      final data = {...salidaData};
      data[Asistencia.fieldFechaHoraSalida] = FieldValue.serverTimestamp();
      await _firestore.collection('asistencias').doc(asistenciaId).update(data);
    } catch (e) {
      debugPrint('Error al registrar salida: $e');
      throw Exception('No se pudo registrar la salida.');
    }
  }

  Future<Asistencia?> getActiveAsistencia(String empleadoId) async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where(Asistencia.fieldEmpleadoId, isEqualTo: empleadoId)
          .where(Asistencia.fieldFechaHoraSalida, isNull: true)
          .orderBy(Asistencia.fieldFechaHoraEntrada, descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener asistencia activa: $e');
      throw Exception('No se pudo obtener la asistencia activa.');
    }
  }
  
  Future<Asistencia?> getTodayAsistencia(String empleadoId) async {
    try {
      final NetworkTimeResult networkTimeResult = await _timeService.getCurrentNetworkTime();
      final DateTime currentTime = networkTimeResult.time;

      final startOfDay = DateTime(currentTime.year, currentTime.month, currentTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('asistencias')
          .where(Asistencia.fieldEmpleadoId, isEqualTo: empleadoId)
          .where(Asistencia.fieldFechaHoraEntrada, isGreaterThanOrEqualTo: startOfDay)
          .where(Asistencia.fieldFechaHoraEntrada, isLessThan: endOfDay)
          .orderBy(Asistencia.fieldFechaHoraEntrada, descending: true)
          .limit(1)
          .get();
          
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        return Asistencia.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener asistencia del día: $e');
      throw Exception('No se pudo obtener la asistencia del día.');
    }
  }

  // --- MÉTODOS PARA CONFIGURACIÓN DE LA API ---

  Future<void> saveApiConfig(ApiConfig config) async {
    try {
      await _firestore.collection('app_config').doc('settings').set(config.toJson());
    } catch (e) {
      debugPrint("Error al guardar la configuración de la API: $e");
      throw Exception("No se pudo guardar la configuración.");
    }
  }

  Future<ApiConfig?> getApiConfig() async {
    try {
      final docSnapshot = await _firestore.collection('app_config').doc('settings').get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        try {
          return ApiConfig.fromJson(docSnapshot.data()!);
        } catch (e) {
          debugPrint("Configuración de API corrupta en Firestore: $e. Se tratará como nula.");
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error al obtener la configuración de la API desde Firestore: $e");
      throw Exception("No se pudo cargar la configuración de la API.");
    }
  }

  // --- MÉTODO DE AYUDA PRIVADO ---

  /// Convierte una lista de documentos de Firestore en una lista de modelos.
  ///
  /// Utiliza un `try-catch` dentro del `map` para evitar que un solo
  /// documento mal formado detenga todo el proceso (robustez).
  List<T> _mapDocsToList<T>(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return docs.map((doc) {
      try {
        final data = doc.data();
        data['id'] = doc.id;
        return fromJson(data);
      } catch (e) {
        debugPrint('Error al parsear el documento con ID ${doc.id}: $e');
        return null;
      }
    }).whereType<T>().toList();
  }
}