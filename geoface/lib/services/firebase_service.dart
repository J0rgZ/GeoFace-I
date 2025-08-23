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

/// Clase de servicio para gestionar todas las interacciones con Firebase.
///
/// Centraliza las operaciones de Firestore (lectura/escritura de datos)
/// y Firebase Auth (autenticación de usuarios) para mantener el código
/// organizado y desacoplado de la lógica de la interfaz de usuario.
class FirebaseService {
  // Instancias de los servicios de Firebase.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ------------------------------------------------------------------
  // --- MÉTODOS DE AUTENTICACIÓN (Auth methods) ---
  // ------------------------------------------------------------------

  /// Inicia sesión de un usuario con su correo electrónico y contraseña.
  ///
  /// @param email El correo electrónico del usuario.
  /// @param password La contraseña del usuario.
  /// @returns Un [Future] que completa con las credenciales del usuario ([UserCredential]) si el inicio de sesión es exitoso.
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Cierra la sesión del usuario actualmente autenticado.
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  /// Obtiene el usuario de Firebase actualmente autenticado.
  ///
  /// @returns El objeto [User] si hay un usuario autenticado, de lo contrario, `null`.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ------------------------------------------------------------------
  // --- MÉTODOS DE USUARIO (Usuario methods) ---
  // ------------------------------------------------------------------

  /// Obtiene un documento de usuario de la colección 'usuarios' basado en su email.
  ///
  /// @param email El correo electrónico a buscar.
  /// @returns Un [Future] que completa con el objeto [Usuario] si se encuentra, de lo contrario, `null`.
  /// @throws Lanza una excepción si ocurre un error durante la consulta a Firestore.
  Future<Usuario?> getUsuarioByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        // Combina el ID del documento con sus datos para crear el objeto Usuario.
        return Usuario.fromJson({
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      print('Error al obtener usuario por email: $e');
      throw e; // Relanza la excepción para que sea manejada por el llamador.
    }
  }

  // ------------------------------------------------------------------
  // --- MÉTODOS DE EMPLEADO (Empleado methods) ---
  // ------------------------------------------------------------------

  /// Obtiene una lista con todos los empleados de la colección.
  Future<List<Empleado>> getEmpleados() async {
    final snapshot = await _firestore.collection(AppConfig.empleadosCollection).get();
    return snapshot.docs.map((doc) => Empleado.fromJson(doc.data())).toList();
  }

  /// Obtiene un empleado específico por su ID de documento.
  Future<Empleado?> getEmpleadoById(String id) async {
    final doc = await _firestore.collection(AppConfig.empleadosCollection).doc(id).get();
    if (doc.exists) {
      return Empleado.fromJson(doc.data()!);
    }
    return null;
  }

  /// Busca y obtiene un empleado por su número de DNI.
  ///
  /// Limita la búsqueda a 1 para mayor eficiencia, ya que el DNI debe ser único.
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

  /// Añade un nuevo documento de empleado a la colección.
  Future<void> addEmpleado(Empleado empleado) async {
    final docRef = _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id);
    await docRef.set(empleado.toJson());
  }

  /// Actualiza los datos de un empleado existente en la colección.
  Future<void> updateEmpleado(Empleado empleado) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).update(empleado.toJson());
  }

  /// Elimina un documento de empleado de la colección por su ID.
  Future<void> deleteEmpleado(String id) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(id).delete();
  }

  // ------------------------------------------------------------------
  // --- MÉTODOS DE SEDE (Sede methods) ---
  // ------------------------------------------------------------------

  /// Obtiene una lista de todas las sedes.
  Future<List<Sede>> getSedes() async {
    final snapshot = await _firestore.collection(AppConfig.sedesCollection).get();
    return snapshot.docs.map((doc) => Sede.fromJson(doc.data())).toList();
  }

  /// Obtiene una sede específica por su ID de documento.
  Future<Sede?> getSedeById(String id) async {
    final doc = await _firestore.collection(AppConfig.sedesCollection).doc(id).get();
    if (doc.exists) {
      return Sede.fromJson(doc.data()!);
    }
    return null;
  }

  /// Añade una nueva sede a la colección.
  Future<void> addSede(Sede sede) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(sede.id).set(sede.toJson());
  }

  /// Actualiza los datos de una sede existente.
  Future<void> updateSede(Sede sede) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(sede.id).update(sede.toJson());
  }

  /// Elimina una sede de la colección por su ID.
  Future<void> deleteSede(String id) async {
    await _firestore.collection(AppConfig.sedesCollection).doc(id).delete();
  }

  /// Actualiza el estado (activa/inactiva) de una sede y la fecha de modificación.
  Future<void> updateSedeStatus(String id, bool activa) async {
    return _firestore.collection(AppConfig.sedesCollection).doc(id).update({
      'activa': activa,
      'fechaModificacion': Timestamp.now(), // Usa el timestamp del servidor.
    });
  }

  // ------------------------------------------------------------------
  // --- MÉTODOS DE ASISTENCIA (Asistencia methods) ---
  // ------------------------------------------------------------------

  /// Obtiene todos los registros de asistencia para un empleado específico, ordenados por fecha de entrada descendente.
  Future<List<Asistencia>> getAsistenciasByEmpleado(String empleadoId) async {
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
      print('Error al obtener asistencia activa: $e');
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

  Future<List<Asistencia>> getAsistenciasDeHoy() async {
    // 1. Define el rango del día de hoy (desde las 00:00 hasta las 23:59)
    final ahora = DateTime.now();
    final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    // 2. Crea la consulta a Firestore
    final querySnapshot = await _firestore
        .collection('asistencias')
        .where('fechaHoraEntrada', isGreaterThanOrEqualTo: inicioDelDia)
        .where('fechaHoraEntrada', isLessThan: finDelDia)
        .get();

    // 3. Convierte los documentos a objetos Asistencia
    return querySnapshot.docs
        .map((doc) => Asistencia.fromJson({'id': doc.id, ...doc.data()}))
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
      print('Error al obtener asistencias filtradas: ${e.toString()}');
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
      print('Error al buscar asistencia completada para hoy: $e');
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
      print('Error al obtener asistencia del día: $e');
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
          .collection('asistencias')
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
      print('Error al obtener todas las asistencias: ${e.toString()}');
      throw Exception('No se pudieron cargar las asistencias');
    }
  }

  // ------------------------------------------------------------------
  // --- MÉTODOS DE ADMINISTRADOR ---
  // ------------------------------------------------------------------

  /// Obtiene una lista de todos los usuarios con el rol de 'ADMIN'.
  Future<List<Usuario>> getAdministradores() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'ADMIN')
          .get();

      if (snapshot.docs.isEmpty) {
        return []; // Retorna una lista vacía si no se encuentran administradores.
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

  /// Envía un correo electrónico para restablecer la contraseña.
  /// TODO: Implementar la lógica para llamar a `_auth.sendPasswordResetEmail(email: correo)`.
  sendPasswordResetEmail(String correo) {}

  // ------------------------------------------------------------------
  // --- MÉTODOS PARA LA CONFIGURACIÓN DE LA API ---
  // ------------------------------------------------------------------

  /// Guarda o actualiza el objeto de configuración de la API en un único documento de Firestore.
  ///
  /// @param config El objeto [ApiConfig] a guardar.
  /// Utiliza `SetOptions(merge: true)` para no sobrescribir campos que no estén en el objeto `config`.
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

  /// Obtiene el objeto de configuración de la API desde Firestore.
  ///
  /// @returns Un [Future] que completa con el objeto [ApiConfig].
  /// Si el documento no existe, devuelve una configuración por defecto con `ApiConfig.empty`.
  Future<ApiConfig> getApiConfig() async {
    try {
      final docSnapshot = await _firestore.collection('app_config').doc('settings').get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ApiConfig.fromMap(docSnapshot.data()!);
      }
      // Si el documento no existe, devuelve una configuración vacía/predeterminada.
      return ApiConfig.empty;
    } catch (e) {
      print("Error al obtener la configuración de la API: $e");
      throw Exception("No se pudo cargar la configuración de la API.");
    }
  }
}