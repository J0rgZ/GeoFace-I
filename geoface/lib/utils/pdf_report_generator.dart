// -----------------------------------------------------------------------------
// @Encabezado:   Generador de Reportes PDF
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `PdfReportGenerator`, que se
//               encarga de generar reportes detallados de asistencia en formato
//               PDF. Utiliza el paquete `pdf` para crear documentos con
//               tablas, gráficos y formato profesional, incluyendo resúmenes
//               estadísticos y detalles diarios de asistencias y ausencias.
//
// @NombreArchivo: pdf_report_generator.dart
// @Ubicacion:    lib/utils/pdf_report_generator.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:collection/collection.dart';
import '../controllers/reporte_controller.dart';
import '../models/asistencia.dart';
import '../models/empleado.dart';

class PdfReportGenerator {
  final ReporteDetallado reporte;
  // Usamos un Map para búsqueda O(1), mucho más eficiente que List.firstWhere en un bucle.
  final Map<String, Empleado> _empleadoMap;

  // --- CONSTANTES DE DISEÑO Y CONFIGURACIÓN ---
  // Mover valores fijos a constantes mejora la mantenibilidad y previene errores.
  static const _primaryColor = PdfColors.blueGrey800;
  static const _accentColor = PdfColors.blueGrey50;
  static const _lightGreyColor = PdfColors.grey200;
  static const _darkGreyColor = PdfColors.grey700;
  
  static const _successColor = PdfColors.green600;
  static const _warningColor = PdfColors.orange600;
  static const _errorColor = PdfColors.red600;

  static const _fontRegularPath = 'assets/fonts/Roboto-Regular.ttf';
  static const _fontBoldPath = 'assets/fonts/Roboto-Bold.ttf';
  
  // Definir la hora límite como una constante para fácil configuración.
  static final _horaLimiteTardanza = DateTime(0).copyWith(hour: 9, minute: 1);

  PdfReportGenerator({
    required this.reporte,
    required List<Empleado> todosLosEmpleados,
  }) : _empleadoMap = { for (var e in todosLosEmpleados) e.id: e };

  /// Busca el nombre de un empleado por su ID usando el mapa pre-construido.
  /// Retorna un nombre seguro sin exponer información sensible.
  String _getNombreEmpleado(String empleadoId) {
    if (empleadoId.isEmpty) {
      return 'Empleado Desconocido';
    }
    final empleado = _empleadoMap[empleadoId];
    if (empleado != null) {
      return empleado.nombreCompleto;
    }
    // Si el ID es muy corto, no mostrar substring para evitar errores
    final idPreview = empleadoId.length > 8 
        ? '${empleadoId.substring(0, 8)}...'
        : '***';
    return 'Empleado Desconocido (ID: $idPreview)';
  }

  /// Carga las fuentes y el logo de forma segura y crea el tema del PDF.
  Future<pw.ThemeData?> _loadThemeData() async {
    try {
      // Carga de fuentes (esencial para caracteres latinos como 'ñ' y acentos)
      final fontData = await rootBundle.load(_fontRegularPath);
      final boldFontData = await rootBundle.load(_fontBoldPath);

      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);

      // Creación de un tema para aplicar estilos de forma consistente
      // Nota: Se omite PdfGoogleFonts para evitar dependencias externas y mejorar rendimiento
      return pw.ThemeData.withFont(
        base: ttf,
        bold: boldTtf,
      );
    } catch (e) {
      // Registrar el error es crucial para la depuración.
      log('Error al cargar fuentes para el PDF: $e');
      // Retornar null para que el método principal sepa que hubo un fallo.
      return null;
    }
  }


  /// Genera y muestra la pantalla para compartir/imprimir el PDF.
  /// Retorna true si se generó exitosamente, false en caso de error.
  Future<bool> generateAndSharePdf() async {
    try {
      // Validar que hay datos para el reporte
      final diasConAsistencias = reporte.asistenciasPorDia.keys.toList();
      final diasConAusencias = reporte.ausenciasPorDia.keys.toList();
      
      // Combinar todos los días únicos y ordenarlos
      final todosLosDias = {...diasConAsistencias, ...diasConAusencias}.toList()..sort();
      
      final tieneDatos = todosLosDias.isNotEmpty;
      
      if (!tieneDatos) {
        log("No hay datos para generar el reporte PDF.");
        return false;
      }

      final theme = await _loadThemeData();
      if (theme == null) {
        log("No se pudo cargar las fuentes para el PDF.");
        return false;
      }

      final doc = pw.Document();
      final fechaFinReporte = todosLosDias.isNotEmpty ? todosLosDias.last : reporte.resumen.fecha;
      final fechaInicioReporte = todosLosDias.isNotEmpty ? todosLosDias.first : reporte.resumen.fecha;

      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(context),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildTitle(fechaInicioReporte, fechaFinReporte),
            pw.SizedBox(height: 20),
            _buildSummaryTable(),
            pw.SizedBox(height: 25),
            _buildResumenPorEmpleado(),
            pw.SizedBox(height: 25),
            _buildDetails(todosLosDias),
          ],
        ),
      );

      // Usar 'printing' para mostrar, compartir o imprimir el PDF.
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'reporte_asistencia_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      );
      
      return true;
    } catch (e) {
      log('Error al generar el PDF: $e');
      return false;
    }
  }
  
  // --- Widgets de construcción del PDF ---

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _lightGreyColor, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10.0),
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'GeoFace - Reporte de Asistencia',
            style: pw.TextStyle(
              color: _darkGreyColor,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            DateFormat('dd/MM/yyyy HH:mm', 'es').format(DateTime.now()),
            style: pw.TextStyle(color: _darkGreyColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20.0),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: pw.TextStyle(color: _darkGreyColor, fontSize: 10),
      ),
    );
  }
  
  pw.Widget _buildTitle(DateTime fechaInicio, DateTime fechaFin) {
    final resumen = reporte.resumen;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Reporte Detallado de Asistencia',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _accentColor,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sede: ${resumen.sedeNombre}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Período: ${DateFormat('dd/MM/yyyy', 'es').format(fechaInicio)} - ${DateFormat('dd/MM/yyyy', 'es').format(fechaFin)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total de Empleados: ${resumen.totalEmpleados}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Divider(thickness: 1.5, color: _lightGreyColor),
      ],
    );
  }
  
  pw.Widget _buildSummaryTable() {
    final r = reporte.resumen;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _accentColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryCell('Asistencias', r.totalAsistencias.toString()),
          _summaryCell('Ausencias', r.totalAusencias.toString()),
          _summaryCell('Tardanzas', r.totalTardanzas.toString()),
          _summaryCell('% Asistencia', '${r.porcentajeAsistencia.toStringAsFixed(1)}%'),
        ]
      ),
    );
  }

  pw.Widget _summaryCell(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(color: _darkGreyColor, fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: _primaryColor)),
      ]
    );
  }
  
  /// Construye la sección de resumen por empleado, agrupada por sede si hay múltiples sedes
  pw.Widget _buildResumenPorEmpleado() {
    if (reporte.estadisticasPorEmpleado.isEmpty) {
      return pw.SizedBox.shrink();
    }
    
    // Verificar si hay múltiples sedes
    final sedesUnicas = reporte.estadisticasPorEmpleado.map((e) => e.sedeId).toSet();
    final hayMultiplesSedes = sedesUnicas.length > 1;
    
    if (hayMultiplesSedes) {
      // Agrupar por sede
      final estadisticasPorSede = groupBy<EstadisticaEmpleado, String>(
        reporte.estadisticasPorEmpleado,
        (e) => e.sedeId,
      );
      
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen por Empleado',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 15),
          ...estadisticasPorSede.entries.map((entry) {
            final estadisticas = entry.value;
            final nombreSede = estadisticas.first.sedeNombre;
            
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: pw.BoxDecoration(
                    color: _primaryColor,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Text(
                    'Sede: $nombreSede',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildTablaEmpleados(estadisticas),
                pw.Container(
                  height: 1,
                  color: _lightGreyColor,
                ),
                pw.SizedBox(height: 15),
              ],
            );
          }),
        ],
      );
    } else {
      // Solo una sede, mostrar directamente
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen por Empleado',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildTablaEmpleados(reporte.estadisticasPorEmpleado),
        ],
      );
    }
  }
  
  /// Construye la tabla de estadísticas de empleados
  pw.Widget _buildTablaEmpleados(List<EstadisticaEmpleado> estadisticas) {
    final headers = ['Empleado', 'Asistencias', 'Ausencias', 'Tardanzas', '% Asistencia'];
    
    return pw.Table(
      border: pw.TableBorder.all(color: _lightGreyColor),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
      },
      children: [
        // Fila de cabecera
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _accentColor),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: pw.TextAlign.center,
            ),
          )).toList(),
        ),
        
        // Filas de datos
        for (var i = 0; i < estadisticas.length; i++)
          _buildFilaEmpleado(estadisticas[i], i % 2 == 0),
      ],
    );
  }
  
  /// Construye una fila de la tabla de empleados
  pw.TableRow _buildFilaEmpleado(EstadisticaEmpleado estadistica, bool isEven) {
    final style = pw.TextStyle(fontSize: 9);
    
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven ? PdfColors.white : _accentColor,
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            estadistica.nombreEmpleado,
            style: style,
            maxLines: 2,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            estadistica.totalAsistencias.toString(),
            style: style.copyWith(color: _successColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            estadistica.totalAusencias.toString(),
            style: style.copyWith(color: _errorColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            estadistica.totalTardanzas.toString(),
            style: style.copyWith(color: _warningColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            '${estadistica.porcentajeAsistencia.toStringAsFixed(1)}%',
            style: style,
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  pw.Widget _buildDetails(List<DateTime> dias) {
    // OPTIMIZADO: Función de tardanza más eficiente sin crear nuevos DateTime
    bool esTardanza(Asistencia a) {
      final horaEntrada = a.fechaHoraEntrada;
      final horaLimite = _horaLimiteTardanza.hour;
      final minutoLimite = _horaLimiteTardanza.minute;
      // Comparación directa más eficiente
      return horaEntrada.hour > horaLimite || 
             (horaEntrada.hour == horaLimite && horaEntrada.minute > minutoLimite);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Detalle Diario', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
        pw.SizedBox(height: 10),
        ...dias.map((dia) {
          final asistenciasDelDia = reporte.asistenciasPorDia[dia] ?? [];
          final ausenciasDelDia = reporte.ausenciasPorDia[dia] ?? [];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: const pw.BoxDecoration(color: _primaryColor),
                child: pw.Text(DateFormat.yMMMMEEEEd('es').format(dia), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
              _buildDailyTable(asistenciasDelDia, ausenciasDelDia, esTardanza),
              pw.SizedBox(height: 20),
            ]
          );
        }),
      ]
    );
  }

  pw.Widget _buildDailyTable(List<Asistencia> asistencias, List<Empleado> ausentes, bool Function(Asistencia) esTardanza) {
    final headers = ['Empleado', 'Entrada', 'Salida', 'Estado'];
    
    // Pre-allocar lista con capacidad estimada para mejor rendimiento
    final allData = <Map<String, dynamic>>[];

    // Filas de asistencias - sanitizar nombres antes de agregar
    for (var a in asistencias) {
      final nombreEmpleado = _getNombreEmpleado(a.empleadoId);
      if (nombreEmpleado.isNotEmpty) {
        allData.add({
          'nombre': nombreEmpleado,
          'entrada': DateFormat.jm('es').format(a.fechaHoraEntrada),
          'salida': a.fechaHoraSalida != null 
              ? DateFormat.jm('es').format(a.fechaHoraSalida!) 
              : '---',
          'tardanza': esTardanza(a),
          'presente': true,
        });
      }
    }

    // Filas de ausencias - sanitizar nombres antes de agregar
    for (var e in ausentes) {
      final nombreCompleto = e.nombreCompleto.trim();
      if (nombreCompleto.isNotEmpty) {
        allData.add({
          'nombre': nombreCompleto,
          'entrada': '---',
          'salida': '---',
          'presente': false,
        });
      }
    }
    
    // Ordenar por nombre de empleado para unificar la lista
    if (allData.isNotEmpty) {
      allData.sort((a, b) {
        final nombreA = a['nombre'] as String;
        final nombreB = b['nombre'] as String;
        return nombreA.compareTo(nombreB);
      });
    }

    if (allData.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(15),
        child: pw.Text('No hay registros de asistencia o ausencia para este día.', style: pw.TextStyle(color: _darkGreyColor)),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: _lightGreyColor),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.2), // Un poco más de espacio para el estado con icono
      },
      children: [
        // Fila de cabecera
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _accentColor),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(header, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
        
        // Filas de datos con Zebra-Striping
        for (var i = 0; i < allData.length; i++)
          _buildDataRow(allData[i], isEven: i % 2 == 0)
      ],
    );
  }

  pw.TableRow _buildDataRow(Map<String, dynamic> data, {required bool isEven}) {
    final style = pw.TextStyle(fontSize: 9.5);
    final isPresent = data['presente'] as bool;
    final isLate = isPresent && (data['tardanza'] as bool);

    pw.Widget statusWidget;
    if (isPresent) {
      statusWidget = _statusCell(
        isLate ? 'Tardanza' : 'Asistió',
        isLate ? _warningColor : _successColor
      );
    } else {
      statusWidget = _statusCell('Ausente', _errorColor);
    }

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : _accentColor),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['nombre'], style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['entrada'], style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['salida'], style: style)),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: statusWidget),
      ],
    );
  }

  /// Widget para la celda de estado con un indicador de color.
  pw.Widget _statusCell(String text, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 6),
        pw.Text(text, style: pw.TextStyle(color: color, fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
      ]
    );
  }
  
}