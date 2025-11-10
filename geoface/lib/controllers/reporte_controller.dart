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

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/asistencia.dart';
import '../models/empleado.dart';
import '../models/sede.dart';
import '../models/estadistica_asistencia.dart';
import '../services/empleado_service.dart';
import '../services/asistencia_service.dart';
import '../utils/pdf_report_generator.dart';

// Clase para estadísticas por empleado
class EstadisticaEmpleado {
  final String empleadoId;
  final String nombreEmpleado;
  final String sedeId;
  final String sedeNombre;
  final int totalAsistencias;
  final int totalAusencias;
  final int totalTardanzas;
  final double porcentajeAsistencia;

  EstadisticaEmpleado({
    required this.empleadoId,
    required this.nombreEmpleado,
    required this.sedeId,
    required this.sedeNombre,
    required this.totalAsistencias,
    required this.totalAusencias,
    required this.totalTardanzas,
    required this.porcentajeAsistencia,
  });
}

// Clase auxiliar para agrupar todos los datos de un reporte generado.
class ReporteDetallado {
  final EstadisticaAsistencia resumen;
  final Map<DateTime, List<Asistencia>> asistenciasPorDia;
  final Map<DateTime, List<Empleado>> ausenciasPorDia;
  final List<EstadisticaEmpleado> estadisticasPorEmpleado;

  ReporteDetallado({
    required this.resumen,
    required this.asistenciasPorDia,
    required this.ausenciasPorDia,
    required this.estadisticasPorEmpleado,
  });
}

// Controlador para la lógica de negocio de la generación de reportes de asistencia.
class ReporteController extends ChangeNotifier {
  final EmpleadoService _empleadoService = EmpleadoService();
  final AsistenciaService _asistenciaService = AsistenciaService();

  // Estado interno del controlador.
  ReporteDetallado? _reporte;
  List<Empleado> _todosLosEmpleados = [];
  Map<String, Empleado>? _empleadoMapCache; // Cache para búsquedas rápidas O(1)
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
  // OPTIMIZADO: Usa un mapa para búsqueda O(1) en lugar de O(n) con firstWhere
  Empleado? getEmpleadoById(String id) {
    if (id.isEmpty || _todosLosEmpleados.isEmpty) {
      return null;
    }
    // Crear mapa si no existe (lazy initialization para mejor rendimiento)
    _empleadoMapCache ??= {for (var e in _todosLosEmpleados) e.id: e};
    return _empleadoMapCache![id];
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
      // Validación: Verificar que las fechas sean válidas
      if (fechaInicio.isAfter(fechaFin)) {
        _errorMessage = 'La fecha de inicio debe ser anterior a la fecha de fin.';
        _loading = false;
        notifyListeners();
        return;
      }

      // Validación: Limitar el rango de fechas a máximo 12 meses
      final diferenciaMeses = (fechaFin.year - fechaInicio.year) * 12 + (fechaFin.month - fechaInicio.month);
      if (diferenciaMeses > 12) {
        _errorMessage = 'El rango de fechas no puede ser mayor a 12 meses.';
        _loading = false;
        notifyListeners();
        return;
      }

      // Validación: Verificar que la fecha de fin no sea futura (incluye ajuste de horas)
      final ahora = DateTime.now();
      final fechaFinAjustada = fechaFin.add(const Duration(hours: 23, minutes: 59));
      if (fechaFinAjustada.isAfter(ahora)) {
        _errorMessage = 'La fecha de fin no puede ser futura.';
        _loading = false;
        notifyListeners();
        return;
      }

      // Validación: Verificar que hay sedes disponibles si se selecciona una sede
      if (sedeId != null && sedeId.isNotEmpty) {
        // Validar que el ID no esté vacío o sea solo espacios (seguridad)
        final sedeIdLimpio = sedeId.trim();
        if (sedeIdLimpio.isEmpty) {
          _errorMessage = 'ID de sede inválido.';
          _loading = false;
          notifyListeners();
          return;
        }
        // Usar mapa para búsqueda O(1) en lugar de O(n) - optimización de rendimiento
        final mapaSedesIds = {for (var s in sedes) s.id: s};
        if (!mapaSedesIds.containsKey(sedeIdLimpio)) {
          _errorMessage = 'La sede seleccionada no existe.';
          _loading = false;
          notifyListeners();
          return;
        }
      }
      // 1. Obtenemos la lista completa de empleados una sola vez para optimizar.
      _todosLosEmpleados = await _empleadoService.getEmpleados();
      // Limpiar cache al cargar nuevos empleados
      _empleadoMapCache = null;
      
      // Validación: Verificar que se cargaron empleados
      if (_todosLosEmpleados.isEmpty) {
        _errorMessage = 'No se encontraron empleados en el sistema.';
        _loading = false;
        notifyListeners();
        return;
      }

      // 2. Filtramos los empleados que aplican al reporte (activos y de la sede seleccionada).
      final empleadosActivos = _todosLosEmpleados.where((e) {
        final perteneceSede = sedeId == null || e.sedeId == sedeId;
        return e.activo && perteneceSede;
      }).toList();
      
      // Validación: Verificar que hay empleados activos para la sede seleccionada
      if (empleadosActivos.isEmpty) {
        _errorMessage = sedeId != null
            ? 'No hay empleados activos en la sede seleccionada para el período especificado.'
            : 'No hay empleados activos en el sistema.';
        _loading = false;
        notifyListeners();
        return;
      }

      // 3. Obtenemos solo las asistencias del rango de fechas y sede.
      final asistencias = await _asistenciaService.getAsistenciasFiltradas(
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
      // OPTIMIZADO: Iteramos sobre cada día del rango seleccionado.
      // =========================================================================
      final ausenciasPorDia = <DateTime, List<Empleado>>{};
      final diasEnRango = fechaFin.difference(fechaInicio).inDays;
      
      // Validación de seguridad: Limitar el número máximo de días para evitar problemas de rendimiento
      const maxDiasPermitidos = 366; // 1 año
      if (diasEnRango > maxDiasPermitidos) {
        _errorMessage = 'El rango de fechas es demasiado grande. Por favor, seleccione un período menor.';
        _loading = false;
        notifyListeners();
        return;
      }

      for (var i = 0; i <= diasEnRango; i++) {
        // Se itera día por día dentro del rango de fechas.
        final diaActual = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day).add(Duration(days: i));
        
        final asistenciasDelDia = asistenciasPorDia[diaActual] ?? [];
        // Usar Set para búsqueda O(1) en lugar de O(n)
        final idsEmpleadosConAsistencia = asistenciasDelDia.map((a) => a.empleadoId).toSet();
        
        // Comparamos la lista de empleados activos con los que asistieron para encontrar a los ausentes.
        // OPTIMIZADO: Filtrar usando el mapa de empleados activos
        final empleadosAusentes = empleadosActivos
            .where((e) => !idsEmpleadosConAsistencia.contains(e.id))
            .toList(growable: false); // growable: false para mejor rendimiento
            
        // Solo agregar al mapa si hay ausentes (optimización de memoria)
        if (empleadosAusentes.isNotEmpty) {
          ausenciasPorDia[diaActual] = empleadosAusentes;
        }
      }
      // =========================================================================

      // 5. Se calcula el total de tardanzas basado en una hora de entrada fija.
      // OPTIMIZADO: Usar comparación directa de DateTime en lugar de TimeOfDay
      final horaLimiteEntrada = 9; // Hora límite: 9:00 AM
      final horaLimiteMinutos = 0;
      int totalTardanzas = 0;
      final tardanzasPorEmpleado = <String, int>{};
      
      for (var asistencia in asistencias) {
        final horaEntrada = asistencia.fechaHoraEntrada;
        // Comparar directamente horas y minutos (más eficiente que TimeOfDay)
        if (horaEntrada.hour > horaLimiteEntrada || 
            (horaEntrada.hour == horaLimiteEntrada && horaEntrada.minute > horaLimiteMinutos)) {
          totalTardanzas++;
          tardanzasPorEmpleado[asistencia.empleadoId] = (tardanzasPorEmpleado[asistencia.empleadoId] ?? 0) + 1;
        }
      }
      
      // 6. Se calculan los totales para el resumen general del reporte.
      final totalAsistencias = asistencias.length;
      final totalAusencias = ausenciasPorDia.values.fold<int>(0, (sum, list) => sum + list.length);
      final totalPosiblesAsistencias = empleadosActivos.length * (diasEnRango + 1);
      
      final porcentajeAsistencia = totalPosiblesAsistencias > 0
          ? (totalAsistencias / totalPosiblesAsistencias) * 100
          : 0.0;
      
      // Obtener nombre de sede de forma segura (O(1) con mapa)
      final mapaSedesNombre = {for (var s in sedes) s.id: s.nombre};
      final String sedeNombre = sedeId != null 
        ? (mapaSedesNombre[sedeId] ?? 'Sede Desconocida')
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

      // 8. Calcular estadísticas por empleado (OPTIMIZADO)
      final estadisticasPorEmpleado = <EstadisticaEmpleado>[];
      
      // Agrupar asistencias por empleado (O(n))
      final asistenciasPorEmpleado = groupBy<Asistencia, String>(
        asistencias,
        (a) => a.empleadoId,
      );
      
      // Crear un mapa de sedeId -> nombre de sede para búsqueda rápida O(1)
      final mapaSedes = {for (var s in sedes) s.id: s.nombre};
      
      // Crear un mapa de ausencias por empleado para búsqueda O(1) en lugar de O(n)
      // Estructura: {empleadoId: {dia1, dia2, ...}}
      final ausenciasPorEmpleadoMap = <String, Set<DateTime>>{};
      for (var entry in ausenciasPorDia.entries) {
        final dia = entry.key;
        final empleadosAusentes = entry.value;
        for (var empleado in empleadosAusentes) {
          ausenciasPorEmpleadoMap.putIfAbsent(empleado.id, () => <DateTime>{}).add(dia);
        }
      }
      
      // Calcular estadísticas para cada empleado (O(n) en lugar de O(n*m))
      for (var empleado in empleadosActivos) {
        final asistenciasEmpleado = asistenciasPorEmpleado[empleado.id] ?? [];
        final totalAsistenciasEmpleado = asistenciasEmpleado.length;
        
        // Obtener ausencias del empleado usando el mapa (O(1))
        final diasAusentes = ausenciasPorEmpleadoMap[empleado.id] ?? <DateTime>{};
        final totalAusenciasEmpleado = diasAusentes.length;
        
        // Obtener tardanzas del empleado (O(1))
        final totalTardanzasEmpleado = tardanzasPorEmpleado[empleado.id] ?? 0;
        
        // Calcular porcentaje de asistencia
        final totalDiasLaborables = diasEnRango + 1;
        final porcentajeAsistenciaEmpleado = totalDiasLaborables > 0
            ? (totalAsistenciasEmpleado / totalDiasLaborables) * 100
            : 0.0;
        
        // Obtener nombre de la sede (O(1))
        final nombreSede = mapaSedes[empleado.sedeId] ?? 'Sede Desconocida';
        
        estadisticasPorEmpleado.add(
          EstadisticaEmpleado(
            empleadoId: empleado.id,
            nombreEmpleado: empleado.nombreCompleto,
            sedeId: empleado.sedeId,
            sedeNombre: nombreSede,
            totalAsistencias: totalAsistenciasEmpleado,
            totalAusencias: totalAusenciasEmpleado,
            totalTardanzas: totalTardanzasEmpleado,
            porcentajeAsistencia: porcentajeAsistenciaEmpleado,
          ),
        );
      }
      
      // Ordenar por sede y luego por nombre
      estadisticasPorEmpleado.sort((a, b) {
        final comparacionSede = a.sedeNombre.compareTo(b.sedeNombre);
        if (comparacionSede != 0) return comparacionSede;
        return a.nombreEmpleado.compareTo(b.nombreEmpleado);
      });

      // 9. Se ensambla el reporte final y se actualiza el estado.
      _reporte = ReporteDetallado(
        resumen: resumen,
        asistenciasPorDia: asistenciasPorDia,
        ausenciasPorDia: ausenciasPorDia,
        estadisticasPorEmpleado: estadisticasPorEmpleado,
      );
      _reporteGenerado = true;

    } catch (e, stackTrace) {
      // No exponer detalles técnicos al usuario por seguridad
      log('Error al generar reporte: $e', error: e, stackTrace: stackTrace);
      _errorMessage = 'Error al generar el reporte. Por favor, intente nuevamente.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Delega la creación y la acción de compartir el PDF a una clase especializada.
  // Retorna true si se exportó exitosamente, false en caso de error.
  Future<bool> exportarReporteAPDF() async {
    // Validación: Verificar que hay un reporte generado
    if (_reporte == null) {
      _errorMessage = 'No hay un reporte generado para exportar.';
      notifyListeners();
      return false;
    }

    // Validación: Verificar que hay empleados cargados
    if (_todosLosEmpleados.isEmpty) {
      _errorMessage = 'No se pudieron cargar los datos de empleados.';
      notifyListeners();
      return false;
    }

    // Validación: Verificar que hay datos en el reporte
    final tieneDatos = _reporte!.asistenciasPorDia.isNotEmpty || _reporte!.ausenciasPorDia.isNotEmpty;
    if (!tieneDatos) {
      _errorMessage = 'El reporte no contiene datos para exportar.';
      notifyListeners();
      return false;
    }

    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pdfGenerator = PdfReportGenerator(
        reporte: _reporte!,
        todosLosEmpleados: _todosLosEmpleados,
      );
      final exito = await pdfGenerator.generateAndSharePdf();
      
      if (!exito) {
        _errorMessage = 'Error al generar el PDF. Por favor, intente nuevamente.';
        notifyListeners();
        return false;
      }
      
      return true;
    } catch (e, stackTrace) {
      // No exponer detalles técnicos al usuario por seguridad
      log('Error al exportar reporte: $e', error: e, stackTrace: stackTrace);
      _errorMessage = 'Error al exportar el reporte. Por favor, intente nuevamente.';
      notifyListeners();
      return false;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}