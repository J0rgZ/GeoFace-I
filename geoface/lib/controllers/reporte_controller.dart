// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Reportes
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo contiene la lógica de negocio para generar y
//               exportar reportes detallados de asistencia. El controlador
//               se encarga de obtener los datos de empleados y asistencias,
//               procesarlos para calcular ausencias y tardanzas, y ensamblar
//               un reporte completo que puede ser visualizado en la UI o
//               exportado a PDF.
//
// @NombreControlador: ReporteController
// @Ubicacion:    lib/controllers/reporte_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/asistencia.dart';
import '../models/empleado.dart';
import '../models/sede.dart';
import '../models/estadistica_asistencia.dart';
import '../services/firebase_service.dart';
import '../utils/pdf_report_generator.dart';

// Clase auxiliar para agrupar todos los datos de un reporte generado.
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

// Controlador para la lógica de negocio de la generación de reportes de asistencia.
class ReporteController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // Estado interno del controlador.
  ReporteDetallado? _reporte;
  List<Empleado> _todosLosEmpleados = [];
  bool _loading = false;
  bool _isExporting = false;
  String? _errorMessage;
  bool _reporteGenerado = false;

  // Getters públicos para que la UI acceda al estado de forma segura.
  ReporteDetallado? get reporte => _reporte;
  bool get loading => _loading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  bool get reporteGenerado => _reporteGenerado;

  // Función de utilidad para buscar un empleado por su ID en la lista local.
  // Evita hacer múltiples llamadas a la base de datos.
  Empleado? getEmpleadoById(String id) {
    try {
      return _todosLosEmpleados.firstWhere((e) => e.id == id);
    } catch (e) {
      // Si no se encuentra, devuelve null.
      return null;
    }
  }

  // Método principal para generar el reporte detallado de asistencias y ausencias.
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
      // 1. Obtenemos la lista completa de empleados una sola vez para optimizar.
      _todosLosEmpleados = await _firebaseService.getEmpleados(); 

      // 2. Filtramos los empleados que aplican al reporte (activos y de la sede seleccionada).
      final empleadosActivos = _todosLosEmpleados.where((e) {
        final perteneceSede = sedeId == null || e.sedeId == sedeId;
        return e.activo && perteneceSede;
      }).toList();

      // 3. Obtenemos solo las asistencias del rango de fechas y sede.
      final asistencias = await _firebaseService.getAsistenciasFiltradas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sedeId: sedeId,
      );

      // 4. Agrupamos las asistencias por día para un acceso más fácil.
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
        // Se itera día por día dentro del rango de fechas.
        final diaActual = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day).add(Duration(days: i));
        
        final asistenciasDelDia = asistenciasPorDia[diaActual] ?? [];
        final idsEmpleadosConAsistencia = asistenciasDelDia.map((a) => a.empleadoId).toSet();
        
        // Comparamos la lista de empleados activos con los que asistieron para encontrar a los ausentes.
        final empleadosAusentes = empleadosActivos
            .where((e) => !idsEmpleadosConAsistencia.contains(e.id))
            .toList();
            
        ausenciasPorDia[diaActual] = empleadosAusentes;
      }
      // =========================================================================

      // 5. Se calcula el total de tardanzas basado en una hora de entrada fija.
      int totalTardanzas = 0;
      final horaLimiteEntrada = TimeOfDay(hour: 9, minute: 0);
      for (var asistencia in asistencias) {
          final horaEntrada = TimeOfDay.fromDateTime(asistencia.fechaHoraEntrada);
          if (horaEntrada.hour > horaLimiteEntrada.hour || (horaEntrada.hour == horaLimiteEntrada.hour && horaEntrada.minute > horaLimiteEntrada.minute)) {
              totalTardanzas++;
          }
      }
      
      // 6. Se calculan los totales para el resumen general del reporte.
      final totalAsistencias = asistencias.length;
      final totalAusencias = ausenciasPorDia.values.fold<int>(0, (sum, list) => sum + list.length);
      final totalPosiblesAsistencias = empleadosActivos.length * (diasEnRango + 1);
      
      final porcentajeAsistencia = totalPosiblesAsistencias > 0
          ? (totalAsistencias / totalPosiblesAsistencias) * 100
          : 0.0;
      
      final String sedeNombre = sedeId != null 
        ? sedes.firstWhere((s) => s.id == sedeId, orElse: () => Sede.empty()).nombre
        : 'Todas las Sedes';

      // 7. Se construye el objeto de resumen (EstadisticaAsistencia).
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

      // 8. Se ensambla el reporte final y se actualiza el estado.
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

  // Delega la creación y la acción de compartir el PDF a una clase especializada.
  Future<void> exportarReporteAPDF() async {
    if (_reporte == null || _todosLosEmpleados.isEmpty) return;

    _isExporting = true;
    notifyListeners();

    try {
      final pdfGenerator = PdfReportGenerator(
        reporte: _reporte!,
        todosLosEmpleados: _todosLosEmpleados,
      );
      await pdfGenerator.generateAndSharePdf();
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}