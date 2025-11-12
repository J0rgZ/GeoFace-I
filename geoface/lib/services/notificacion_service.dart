// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Notificaciones
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `NotificacionService`, que actúa como
//               una capa de servicio para todas las operaciones relacionadas con
//               notificaciones en Firebase. Centraliza las operaciones CRUD con Cloud
//               Firestore para la colección de notificaciones, desacoplando la lógica
//               de la base de datos de los controladores y la interfaz de usuario.
//
// @NombreArchivo: notificacion_service.dart
// @Ubicacion:    lib/services/notificacion_service.dart
// @FechaInicio:  25/06/2025
// @FechaFin:     25/06/2025
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../app_config.dart';
import '../models/notificacion.dart';

/// Clase de servicio para gestionar todas las operaciones relacionadas con notificaciones.
///
/// Centraliza las operaciones de Firestore para la colección de notificaciones,
/// manteniendo el código organizado y desacoplado de la lógica de la interfaz.
class NotificacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crea una nueva notificación en Firestore
  Future<void> crearNotificacion(Notificacion notificacion) async {
    try {
      final data = notificacion.toJson();
      await _firestore
          .collection(AppConfig.notificacionesCollection)
          .doc(notificacion.id)
          .set(data);
    } catch (e) {
      debugPrint('Error al crear notificación: $e');
      throw Exception('No se pudo crear la notificación');
    }
  }

  /// Obtiene todas las notificaciones del día de hoy
  Future<List<Notificacion>> getNotificacionesDeHoy() async {
    try {
      final ahora = DateTime.now();
      final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(AppConfig.notificacionesCollection)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDelDia))
          .where('fecha', isLessThan: Timestamp.fromDate(finDelDia))
          .orderBy('fecha', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Notificacion.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener notificaciones de hoy: $e');
      throw Exception('No se pudieron cargar las notificaciones');
    }
  }

  /// Obtiene todas las notificaciones no leídas
  Future<List<Notificacion>> getNotificacionesNoLeidas() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConfig.notificacionesCollection)
          .where('leida', isEqualTo: false)
          .orderBy('fecha', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Notificacion.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener notificaciones no leídas: $e');
      throw Exception('No se pudieron cargar las notificaciones no leídas');
    }
  }

  /// Obtiene todas las notificaciones, ordenadas por fecha descendente
  Future<List<Notificacion>> getAllNotificaciones({int? limit}) async {
    try {
      Query query = _firestore
          .collection(AppConfig.notificacionesCollection)
          .orderBy('fecha', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Notificacion.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener todas las notificaciones: $e');
      throw Exception('No se pudieron cargar las notificaciones');
    }
  }

  /// Marca una notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      await _firestore
          .collection(AppConfig.notificacionesCollection)
          .doc(notificacionId)
          .update({'leida': true});
    } catch (e) {
      debugPrint('Error al marcar notificación como leída: $e');
      throw Exception('No se pudo marcar la notificación como leída');
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      final batch = _firestore.batch();
      final notificacionesNoLeidas = await getNotificacionesNoLeidas();

      for (var notificacion in notificacionesNoLeidas) {
        final ref = _firestore
            .collection(AppConfig.notificacionesCollection)
            .doc(notificacion.id);
        batch.update(ref, {'leida': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error al marcar todas las notificaciones como leídas: $e');
      throw Exception('No se pudieron marcar todas las notificaciones como leídas');
    }
  }

  /// Elimina una notificación
  Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      await _firestore
          .collection(AppConfig.notificacionesCollection)
          .doc(notificacionId)
          .delete();
    } catch (e) {
      debugPrint('Error al eliminar notificación: $e');
      throw Exception('No se pudo eliminar la notificación');
    }
  }

  /// Obtiene las notificaciones de una sede específica
  Future<List<Notificacion>> getNotificacionesBySede(String sedeId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConfig.notificacionesCollection)
          .where('sedeId', isEqualTo: sedeId)
          .orderBy('fecha', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Notificacion.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener notificaciones por sede: $e');
      throw Exception('No se pudieron cargar las notificaciones de la sede');
    }
  }

  /// Obtiene las notificaciones de un empleado específico
  Future<List<Notificacion>> getNotificacionesByEmpleado(String empleadoId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConfig.notificacionesCollection)
          .where('empleadoId', isEqualTo: empleadoId)
          .orderBy('fecha', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Notificacion.fromJson(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error al obtener notificaciones por empleado: $e');
      throw Exception('No se pudieron cargar las notificaciones del empleado');
    }
  }

  /// Stream de notificaciones del día de hoy (para actualizaciones en tiempo real)
  Stream<List<Notificacion>> streamNotificacionesDeHoy() {
    try {
      final ahora = DateTime.now();
      final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      return _firestore
          .collection(AppConfig.notificacionesCollection)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDelDia))
          .where('fecha', isLessThan: Timestamp.fromDate(finDelDia))
          .orderBy('fecha', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return Notificacion.fromJson(data);
                })
                .toList();
          });
    } catch (e) {
      debugPrint('Error al crear stream de notificaciones: $e');
      throw Exception('No se pudo crear el stream de notificaciones');
    }
  }
}

