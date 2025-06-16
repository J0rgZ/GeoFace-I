// utils/pdf_report_generator.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../controllers/reporte_controller.dart'; // Para acceder a ReporteDetallado
import '../models/asistencia.dart';
import '../models/empleado.dart';

class PdfReportGenerator {
  final ReporteDetallado reporte;
  final List<Empleado> todosLosEmpleados;

  PdfReportGenerator({
    required this.reporte,
    required this.todosLosEmpleados,
  });

  // Helper para buscar el nombre de un empleado por su ID
  String _getNombreEmpleado(String empleadoId) {
    try {
      final empleado = todosLosEmpleados.firstWhere((e) => e.id == empleadoId);
      return empleado.nombreCompleto;
    } catch (e) {
      return 'ID: ${empleadoId.substring(0, 5)}...'; // Fallback más informativo
    }
  }

  Future<void> generateAndSharePdf() async {
    final doc = pw.Document();

    // Carga de fuentes (esencial para caracteres latinos como 'ñ' y acentos)
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFont = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    // Creación de un tema para aplicar estilos de forma consistente
    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: boldTtf,
      fontFallback: [await PdfGoogleFonts.notoColorEmoji()], // Para emojis (opcional pero recomendado)
    );

    bool esTardanza(Asistencia a) {
      final horaLimite = a.fechaHoraEntrada.copyWith(hour: 9, minute: 0, second: 0);
      return a.fechaHoraEntrada.isAfter(horaLimite);
    }

    final diasOrdenados = reporte.asistenciasPorDia.keys.toList()..sort();
    final fechaFinReporte = diasOrdenados.isNotEmpty ? diasOrdenados.last : reporte.resumen.fecha;

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitle(fechaFinReporte),
          pw.SizedBox(height: 20),
          _buildSummaryTable(),
          pw.SizedBox(height: 20),
          _buildDetails(diasOrdenados, esTardanza),
        ],
      ),
    );

    // Usar 'printing' para mostrar, compartir o imprimir el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'reporte_asistencia_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  // --- Widgets de construcción del PDF ---

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Text(
        'Reporte de Asistencia',
        style: pw.Theme.of(context).defaultTextStyle.copyWith(
          color: PdfColors.grey,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20.0),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: pw.Theme.of(context).defaultTextStyle.copyWith(
          color: PdfColors.grey,
          fontSize: 10,
        ),
      ),
    );
  }
  
  pw.Widget _buildTitle(DateTime fechaFin) {
    final resumen = reporte.resumen;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Reporte Detallado de Asistencia', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Sede: ${resumen.sedeNombre}', style: const pw.TextStyle(fontSize: 16)),
        pw.Text('Periodo: ${DateFormat.yMMMd('es').format(resumen.fecha)} al ${DateFormat.yMMMd('es').format(fechaFin)}', style: const pw.TextStyle(fontSize: 16)),
        pw.Divider(height: 25, thickness: 1.5),
      ],
    );
  }
  
  pw.Widget _buildSummaryTable() {
    final r = reporte.resumen;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
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
        pw.Text(title, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
      ]
    );
  }

  pw.Widget _buildDetails(List<DateTime> dias, Function(Asistencia) esTardanza) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Detalle Diario', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...dias.map((dia) {
          final asistenciasDelDia = reporte.asistenciasPorDia[dia] ?? [];
          final ausenciasDelDia = reporte.ausenciasPorDia[dia] ?? [];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Text(DateFormat.yMMMMEEEEd('es').format(dia), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              _buildDailyTable(asistenciasDelDia, ausenciasDelDia, esTardanza),
              pw.SizedBox(height: 20),
            ]
          );
        }).toList(),
      ]
    );
  }

  pw.Widget _buildDailyTable(List<Asistencia> asistencias, List<Empleado> ausentes, Function(Asistencia) esTardanza) {
    final headers = ['Empleado', 'Entrada', 'Salida', 'Estado'];
    
    // Construir la lista de datos para la tabla
    final allRows = <List<pw.Widget>>[];

    // Filas de asistencias
    for (var a in asistencias) {
      final isLate = esTardanza(a);
      allRows.add([
        pw.Text(_getNombreEmpleado(a.empleadoId)),
        pw.Text(DateFormat.jm('es').format(a.fechaHoraEntrada)),
        pw.Text(a.fechaHoraSalida != null ? DateFormat.jm('es').format(a.fechaHoraSalida!) : '---'),
        pw.Text(
          isLate ? 'Tardanza' : 'Asistió',
          style: pw.TextStyle(color: isLate ? PdfColors.orange : PdfColors.green),
        ),
      ]);
    }

    // Filas de ausencias
    for (var e in ausentes) {
      allRows.add([
        pw.Text(e.nombreCompleto),
        pw.Text('---'),
        pw.Text('---'),
        pw.Text('Ausente', style: const pw.TextStyle(color: PdfColors.red)),
      ]);
    }

    if (allRows.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text('No hay registros para este día.'),
      );
    }
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Fila de cabecera
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(header, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          )).toList(),
        ),
        // Filas de datos
        ...allRows.map((row) => pw.TableRow(
          children: row.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: cell,
          )).toList(),
        )),
      ],
    );
  }
}