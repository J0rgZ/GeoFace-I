// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Reportes Guardados
// @Autor:        Sistema GeoFace
// @Descripción:  Controlador para gestionar reportes guardados localmente.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../models/reporte_guardado.dart';
import '../services/reporte_local_service.dart';

class ReportesGuardadosController extends ChangeNotifier {
  final ReporteLocalService _reporteLocalService = ReporteLocalService();

  List<ReporteGuardado> _reportes = [];
  bool _loading = false;
  String? _errorMessage;

  List<ReporteGuardado> get reportes => _reportes;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarReportes({String? usuarioId}) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reporteLocalService.initialize();
      _reportes = await _reporteLocalService.obtenerReportesGuardados(
        usuarioId: usuarioId,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar los reportes: $e';
      _reportes = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarReporte(int id) async {
    try {
      final exito = await _reporteLocalService.eliminarReporte(id);
      if (exito) {
        await cargarReportes();
      }
      return exito;
    } catch (e) {
      _errorMessage = 'Error al eliminar el reporte: $e';
      notifyListeners();
      return false;
    }
  }
}


