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

  static const _logoAssetPath = 'assets/images/logo.png'; // <- ¡Asegúrate de que esta ruta sea correcta!
  static const _fontRegularPath = 'assets/fonts/Roboto-Regular.ttf';
  static const _fontBoldPath = 'assets/fonts/Roboto-Bold.ttf';
  
  // Definir la hora límite como una constante para fácil configuración.
  static final _horaLimiteTardanza = DateTime(0).copyWith(hour: 9, minute: 1);

  PdfReportGenerator({
    required this.reporte,
    required List<Empleado> todosLosEmpleados,
  }) : _empleadoMap = { for (var e in todosLosEmpleados) e.id: e };

  /// Busca el nombre de un empleado por su ID usando el mapa pre-construido.
  String _getNombreEmpleado(String empleadoId) {
    final empleado = _empleadoMap[empleadoId];
    return empleado?.nombreCompleto ?? 'Empleado Desconocido (ID: ${empleadoId.substring(0, 5)}...)';
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
      return pw.ThemeData.withFont(
        base: ttf,
        bold: boldTtf,
        fontFallback: [await PdfGoogleFonts.notoColorEmoji()], // Para emojis (opcional)
      );
    } catch (e) {
      // Registrar el error es crucial para la depuración.
      log('Error al cargar fuentes para el PDF: $e');
      // Retornar null para que el método principal sepa que hubo un fallo.
      return null;
    }
  }

  /// Carga el logo de la empresa de forma segura.
  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final logoData = await rootBundle.load(_logoAssetPath);
      return pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      log('Error al cargar el logo: $e. El logo no se mostrará.');
      return null;
    }
  }

  /// Genera y muestra la pantalla para compartir/imprimir el PDF.
  Future<void> generateAndSharePdf() async {
    final theme = await _loadThemeData();
    if (theme == null) {
      // Aquí podrías mostrar un SnackBar o Toast al usuario informando del error.
      log("No se pudo generar el PDF por un problema con las fuentes.");
      return;
    }

    final logo = await _loadLogo();
    final doc = pw.Document();
    
    // Ordenar los días para asegurar una secuencia cronológica en el reporte.
    final diasOrdenados = reporte.asistenciasPorDia.keys.toList()..sort();

    // Comprobación para manejar reportes sin datos.
    if (diasOrdenados.isEmpty && reporte.ausenciasPorDia.isEmpty) {
       doc.addPage(_buildEmptyReportPage(theme));
    } else {
      final fechaFinReporte = diasOrdenados.isNotEmpty ? diasOrdenados.last : reporte.resumen.fecha;

      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          header: (context) => _buildHeader(context, logo),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildTitle(fechaFinReporte),
            pw.SizedBox(height: 20),
            _buildSummaryTable(),
            pw.SizedBox(height: 25),
            _buildDetails(diasOrdenados),
          ],
        ),
      );
    }

    // Usar 'printing' para mostrar, compartir o imprimir el PDF.
    // NOTA: Para que 'es' funcione correctamente, asegúrate de haber inicializado
    // los locales en tu main.dart:
    // await initializeDateFormatting('es_ES', null);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'reporte_asistencia_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }
  
  // --- Widgets de construcción del PDF ---

  pw.Widget _buildHeader(pw.Context context, pw.ImageProvider? logo) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _lightGreyColor, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10.0),
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Reporte de Asistencia', style: pw.TextStyle(color: _darkGreyColor, fontSize: 12)),
          if (logo != null) pw.Image(logo, height: 40),
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
  
  pw.Widget _buildTitle(DateTime fechaFin) {
    final resumen = reporte.resumen;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Reporte Detallado de Asistencia', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
        pw.SizedBox(height: 8),
        pw.Text('Sede: ${resumen.sedeNombre}', style: pw.TextStyle(fontSize: 16)),
        pw.Text('Periodo: ${DateFormat.yMMMd('es').format(resumen.fecha)} al ${DateFormat.yMMMd('es').format(fechaFin)}', style: pw.TextStyle(fontSize: 16)),
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
  
  pw.Widget _buildDetails(List<DateTime> dias) {
    bool esTardanza(Asistencia a) {
      // Comparar solo la hora y el minuto con la hora límite
      final horaEntrada = a.fechaHoraEntrada;
      final horaLimiteHoy = horaEntrada.copyWith(hour: _horaLimiteTardanza.hour, minute: _horaLimiteTardanza.minute, second: 0, millisecond: 0, microsecond: 0);
      return horaEntrada.isAfter(horaLimiteHoy);
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
        }).toList(),
      ]
    );
  }

  pw.Widget _buildDailyTable(List<Asistencia> asistencias, List<Empleado> ausentes, bool Function(Asistencia) esTardanza) {
    final headers = ['Empleado', 'Entrada', 'Salida', 'Estado'];
    
    final allData = <Map<String, dynamic>>[];

    // Filas de asistencias
    for (var a in asistencias) {
      allData.add({
        'nombre': _getNombreEmpleado(a.empleadoId),
        'entrada': DateFormat.jm('es').format(a.fechaHoraEntrada),
        'salida': a.fechaHoraSalida != null ? DateFormat.jm('es').format(a.fechaHoraSalida!) : '---',
        'tardanza': esTardanza(a),
        'presente': true,
      });
    }

    // Filas de ausencias
    for (var e in ausentes) {
       allData.add({
        'nombre': e.nombreCompleto,
        'entrada': '---',
        'salida': '---',
        'presente': false,
      });
    }
    
    // Ordenar por nombre de empleado para unificar la lista
    allData.sort((a, b) => a['nombre'].compareTo(b['nombre']));

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
  
  /// Página que se muestra cuando no hay datos para el reporte.
  pw.Page _buildEmptyReportPage(pw.ThemeData theme) {
    return pw.Page(
      theme: theme,
      build: (context) {
        return pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Reporte de Asistencia', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
              pw.SizedBox(height: 30),
              pw.Text('No hay datos disponibles para el periodo seleccionado.', style: pw.TextStyle(fontSize: 16, color: _darkGreyColor)),
              pw.SizedBox(height: 10),
              pw.Text('Por favor, intente con otro rango de fechas o sede.', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
            ],
          ),
        );
      },
    );
  }
}