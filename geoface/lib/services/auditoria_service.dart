// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Auditoría
// @Autor:        Sistema GeoFace
// @Descripción:  Servicio para registrar y consultar eventos de auditoría
//               en Firestore.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/auditoria.dart';
import '../app_config.dart';

class AuditoriaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Registra un evento de auditoría en Firestore
  Future<void> registrarAuditoria({
    required String usuarioId,
    required String usuarioNombre,
    required TipoAccion tipoAccion,
    required TipoEntidad tipoEntidad,
    String? entidadId,
    String? entidadNombre,
    required String descripcion,
    Map<String, dynamic>? datosAdicionales,
    String? dispositivoId,
    String? dispositivoMarca,
    String? dispositivoModelo,
    String? ipAddress,
  }) async {
    try {
      final auditoria = Auditoria(
        id: _uuid.v4(),
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        tipoAccion: tipoAccion,
        tipoEntidad: tipoEntidad,
        entidadId: entidadId,
        entidadNombre: entidadNombre,
        descripcion: descripcion,
        datosAdicionales: datosAdicionales,
        dispositivoId: dispositivoId,
        dispositivoMarca: dispositivoMarca,
        dispositivoModelo: dispositivoModelo,
        fechaHora: DateTime.now(),
        ipAddress: ipAddress,
      );

      await _firestore
          .collection(AppConfig.auditoriaCollection)
          .doc(auditoria.id)
          .set(auditoria.toJson());
    } catch (e) {
      // No lanzar excepción para no interrumpir el flujo principal
      // Solo registrar el error
      print('Error al registrar auditoría: $e');
    }
  }

  /// Obtiene todos los eventos de auditoría ordenados por fecha descendente
  Future<List<Auditoria>> obtenerAuditoria({
    int? limite,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    TipoAccion? tipoAccion,
    String? usuarioId,
    String? usuarioNombre,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConfig.auditoriaCollection)
          .orderBy('fechaHora', descending: true);

      if (fechaInicio != null) {
        query = query.where('fechaHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
      }

      if (fechaFin != null) {
        query = query.where('fechaHora',
            isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
      }

      if (tipoAccion != null) {
        query = query.where('tipoAccion', isEqualTo: tipoAccion.name);
      }

      if (usuarioId != null) {
        query = query.where('usuarioId', isEqualTo: usuarioId);
      }

      if (usuarioNombre != null && usuarioNombre.isNotEmpty) {
        // Buscar por nombre de usuario (requiere índice compuesto o filtrado en memoria)
        // Por ahora, filtramos en memoria después de obtener los resultados
      }

      if (limite != null) {
        query = query.limit(limite);
      }

      final snapshot = await query.get();
      var resultados = snapshot.docs
          .map((doc) => Auditoria.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
          .toList();

      // Filtro adicional por nombre de usuario si se proporciona
      if (usuarioNombre != null && usuarioNombre.isNotEmpty) {
        resultados = resultados.where((a) => 
          a.usuarioNombre.toLowerCase().contains(usuarioNombre.toLowerCase())
        ).toList();
      }

      return resultados;
    } catch (e) {
      print('Error al obtener auditoría: $e');
      return [];
    }
  }

  /// Obtiene eventos de auditoría en tiempo real
  Stream<List<Auditoria>> obtenerAuditoriaEnTiempoReal({
    int? limite,
    TipoAccion? tipoAccion,
    String? usuarioId,
  }) {
    Query query = _firestore
        .collection(AppConfig.auditoriaCollection)
        .orderBy('fechaHora', descending: true);

    if (tipoAccion != null) {
      query = query.where('tipoAccion', isEqualTo: tipoAccion.name);
    }

    if (usuarioId != null) {
      query = query.where('usuarioId', isEqualTo: usuarioId);
    }

    if (limite != null) {
      query = query.limit(limite);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Auditoria.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
          .toList();
    });
  }
}

