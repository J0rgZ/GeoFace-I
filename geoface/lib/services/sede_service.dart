// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Sedes
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `SedeService`, que actúa como una
//               capa de servicio para todas las operaciones relacionadas con sedes
//               en Firebase. Centraliza las operaciones CRUD con Cloud Firestore
//               para la colección de sedes, desacoplando la lógica de la base de
//               datos de los controladores y la interfaz de usuario. Este enfoque
//               mejora la mantenibilidad y la organización del código.
//
// @NombreArchivo: sede_service.dart
// @Ubicacion:    lib/services/sede_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';
import '../models/sede.dart';

/// Clase de servicio para gestionar todas las operaciones relacionadas con sedes.
///
/// Centraliza las operaciones de Firestore para la colección de sedes,
/// manteniendo el código organizado y desacoplado de la lógica de la interfaz.
class SedeService {
  // Instancia de Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene una lista de todas las sedes.
  Future<List<Sede>> getSedes() async {
    final snapshot = await _firestore.collection(AppConfig.sedesCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Sede.fromJson(data);
    }).toList();
  }

  /// Obtiene una sede específica por su ID de documento.
  Future<Sede?> getSedeById(String id) async {
    final doc = await _firestore.collection(AppConfig.sedesCollection).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Sede.fromJson(data);
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
}


