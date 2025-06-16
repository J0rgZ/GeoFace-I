// controllers/reporte_controller.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/asistencia.dart';
import '../models/empleado.dart';
import '../models/sede.dart';
import '../models/estadistica_asistencia.dart';
import '../services/firebase_service.dart';
import '../utils/pdf_report_generator.dart';

class ReporteDetallado {
  final EstadisticaAsistencia resumen;
  final Map<DateTime, List<Asistencia>> asistenciasPorDia;
  final Map<DateTime, List<Empleado>> ausenciasPorDia;

  ReporteDetallado({
    required this.resumen,
    required this.asistenciasPorDia,
    required this.ausenciasPorDia,
  });
}

class ReporteController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  ReporteDetallado? _reporte;
  List<Empleado> _todosLosEmpleados = [];
  bool _loading = false;
  bool _isExporting = false;
  String? _errorMessage;
  bool _reporteGenerado = false;

  ReporteDetallado? get reporte => _reporte;
  bool get loading => _loading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  bool get reporteGenerado => _reporteGenerado;

  Empleado? getEmpleadoById(String id) {
    try {
      return _todosLosEmpleados.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> generarReporteDetallado({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<Sede> sedes,
    String? sedeId,
  }) async {
    _loading = true;
    _reporteGenerado = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _todosLosEmpleados = await _firebaseService.getEmpleados(); 

      final empleadosActivos = _todosLosEmpleados.where((e) {
        final perteneceSede = sedeId == null || e.sedeId == sedeId;
        return e.activo && perteneceSede;
      }).toList();

      final asistencias = await _firebaseService.getAsistenciasFiltradas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sedeId: sedeId,
      );

      final asistenciasPorDia = groupBy<Asistencia, DateTime>(
        asistencias,
        (a) => DateTime(a.fechaHoraEntrada.year, a.fechaHoraEntrada.month, a.fechaHoraEntrada.day),
      );

      // =========================================================================
      // ¡LÓGICA CORREGIDA! Iteramos sobre cada día del rango seleccionado.
      // =========================================================================
      final ausenciasPorDia = <DateTime, List<Empleado>>{};
      final diasEnRango = fechaFin.difference(fechaInicio).inDays;

      for (var i = 0; i <= diasEnRango; i++) {
        // Obtenemos el día actual dentro del bucle
        final diaActual = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day).add(Duration(days: i));
        
        // Buscamos las asistencias para este día específico
        final asistenciasDelDia = asistenciasPorDia[diaActual] ?? [];
        final idsEmpleadosConAsistencia = asistenciasDelDia.map((a) => a.empleadoId).toSet();
        
        // Calculamos los ausentes comparando con la lista completa de empleados activos
        final empleadosAusentes = empleadosActivos
            .where((e) => !idsEmpleadosConAsistencia.contains(e.id))
            .toList();
            
        // Guardamos los ausentes para este día, incluso si es toda la plantilla
        ausenciasPorDia[diaActual] = empleadosAusentes;
      }
      // =========================================================================

      // El cálculo de tardanzas sigue siendo el mismo, se hace sobre las asistencias que sí existen.
      int totalTardanzas = 0;
      final horaLimiteEntrada = TimeOfDay(hour: 9, minute: 0);
      for (var asistencia in asistencias) {
          final horaEntrada = TimeOfDay.fromDateTime(asistencia.fechaHoraEntrada);
          if (horaEntrada.hour > horaLimiteEntrada.hour || (horaEntrada.hour == horaLimiteEntrada.hour && horaEntrada.minute > horaLimiteEntrada.minute)) {
              totalTardanzas++;
          }
      }
      
      final totalAsistencias = asistencias.length;
      // El total de ausencias ahora es la suma de todas las ausencias calculadas por día.
      final totalAusencias = ausenciasPorDia.values.fold<int>(0, (sum, list) => sum + list.length);
      final totalPosiblesAsistencias = empleadosActivos.length * (diasEnRango + 1);
      
      final porcentajeAsistencia = totalPosiblesAsistencias > 0
          ? (totalAsistencias / totalPosiblesAsistencias) * 100
          : 0.0;
      
      final String sedeNombre = sedeId != null 
        ? sedes.firstWhere((s) => s.id == sedeId, orElse: () => Sede.empty()).nombre
        : 'Todas las Sedes';

      final resumen = EstadisticaAsistencia(
        sedeId: sedeId ?? 'todas',
        sedeNombre: sedeNombre,
        fecha: fechaInicio,
        totalEmpleados: empleadosActivos.length,
        totalAsistencias: totalAsistencias,
        totalAusencias: totalAusencias,
        totalTardanzas: totalTardanzas,
        porcentajeAsistencia: porcentajeAsistencia,
      );

      _reporte = ReporteDetallado(
        resumen: resumen,
        asistenciasPorDia: asistenciasPorDia,
        ausenciasPorDia: ausenciasPorDia,
      );
      _reporteGenerado = true;

    } catch (e) {
      _errorMessage = 'Error al generar reporte: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> exportarReporteAPDF() async {
    if (_reporte == null) return;
    if (_todosLosEmpleados.isEmpty) return;

    _isExporting = true;
    notifyListeners();

    try {
      final pdfGenerator = PdfReportGenerator(
        reporte: _reporte!,
        todosLosEmpleados: _todosLosEmpleados,
      );
      await pdfGenerator.generateAndSharePdf();
    } catch (e) {
      print("Error al generar o compartir el PDF: $e");
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}