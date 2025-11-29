// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Auditoría
// @Autor:        Sistema GeoFace
// @Descripción:  Controlador para gestionar la carga y visualización de
//               eventos de auditoría.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../models/auditoria.dart';
import '../services/auditoria_service.dart';

class AuditoriaController extends ChangeNotifier {
  final AuditoriaService _auditoriaService = AuditoriaService();

  List<Auditoria> _auditoria = [];
  bool _loading = false;
  String? _errorMessage;

  List<Auditoria> get auditoria => _auditoria;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarAuditoria({
    int? limite,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    TipoAccion? tipoAccion,
    String? usuarioId,
    String? usuarioNombre,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auditoria = await _auditoriaService.obtenerAuditoria(
        limite: limite ?? 1000, // Aumentar límite para permitir más eventos
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        tipoAccion: tipoAccion,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar la auditoría: $e';
      _auditoria = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

