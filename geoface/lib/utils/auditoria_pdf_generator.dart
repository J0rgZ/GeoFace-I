// -----------------------------------------------------------------------------
// @Encabezado:   Generador de PDF para Auditoría
// @Autor:        Sistema GeoFace
// @Descripción:  Genera reportes PDF de auditoría con filtros y ordenamiento.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/auditoria.dart';

class AuditoriaPdfGenerator {
  final List<Auditoria> eventos;
  final String? filtroTipoAccion;
  final String? filtroUsuario;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String titulo;

  AuditoriaPdfGenerator({
    required this.eventos,
    this.filtroTipoAccion,
    this.filtroUsuario,
    this.fechaInicio,
    this.fechaFin,
    String? tituloPersonalizado,
  }) : titulo = tituloPersonalizado ?? 'Reporte de Auditoría';

  static const _fontRegularPath = 'assets/fonts/Roboto-Regular.ttf';
  static const _fontBoldPath = 'assets/fonts/Roboto-Bold.ttf';
  static const _primaryColor = PdfColors.blueGrey800;
  static const _accentColor = PdfColors.blueGrey50;
  static const _lightGreyColor = PdfColors.grey200;
  static const _darkGreyColor = PdfColors.grey700;

  Future<pw.ThemeData?> _loadThemeData() async {
    try {
      final fontData = await rootBundle.load(_fontRegularPath);
      final boldFontData = await rootBundle.load(_fontBoldPath);
      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);
      return pw.ThemeData.withFont(base: ttf, bold: boldTtf);
    } catch (e) {
      return null;
    }
  }

  Future<List<int>?> generatePdfBytes() async {
    try {
      final theme = await _loadThemeData();
      if (theme == null) return null;

      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          orientation: pw.PageOrientation.portrait,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(context),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildTitle(),
            pw.SizedBox(height: 20),
            _buildFiltrosAplicados(),
            pw.SizedBox(height: 20),
            _buildResumen(),
            pw.SizedBox(height: 20),
            _buildTablaEventos(),
          ],
        ),
      );

      return await doc.save();
    } catch (e) {
      return null;
    }
  }

  Future<bool> generateAndSharePdf() async {
    File? archivoTemporal;
    try {
      final pdfBytes = await generatePdfBytes();
      if (pdfBytes == null) return false;

      final tempDir = await getTemporaryDirectory();
      final nombreArchivo = 'auditoria_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      archivoTemporal = File(path.join(tempDir.path, nombreArchivo));
      await archivoTemporal.writeAsBytes(pdfBytes);

      final xFile = XFile(archivoTemporal.path);
      await Share.shareXFiles(
        [xFile],
        subject: 'Reporte de Auditoría - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        text: 'Reporte de auditoría del sistema GeoFace',
      );

      await Future.delayed(const Duration(seconds: 2));
      if (await archivoTemporal.exists()) {
        try {
          await archivoTemporal.delete();
        } catch (e) {
          // No crítico
        }
      }

      return true;
    } catch (e) {
      if (archivoTemporal != null && await archivoTemporal.exists()) {
        try {
          await archivoTemporal.delete();
        } catch (e) {
          // No crítico
        }
      }
      return false;
    }
  }

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
            'GeoFace - Reporte de Auditoría',
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

  pw.Widget _buildTitle() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Total de eventos: ${eventos.length}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildFiltrosAplicados() {
    final filtros = <String>[];
    if (filtroTipoAccion != null) {
      filtros.add('Tipo: $filtroTipoAccion');
    }
    if (filtroUsuario != null) {
      filtros.add('Usuario: $filtroUsuario');
    }
    if (fechaInicio != null) {
      filtros.add('Desde: ${DateFormat('dd/MM/yyyy', 'es').format(fechaInicio!)}');
    }
    if (fechaFin != null) {
      filtros.add('Hasta: ${DateFormat('dd/MM/yyyy', 'es').format(fechaFin!)}');
    }

    if (filtros.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _accentColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Text('Filtros aplicados: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(filtros.join(' | '), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildResumen() {
    final resumenPorTipo = <String, int>{};
    for (var evento in eventos) {
      final tipo = evento.tipoAccionTexto;
      resumenPorTipo[tipo] = (resumenPorTipo[tipo] ?? 0) + 1;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _accentColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen por Tipo de Acción',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          ...resumenPorTipo.entries.map((entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(entry.value.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  pw.Widget _buildTablaEventos() {
    if (eventos.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Text(
          'No hay eventos de auditoría para mostrar',
          style: pw.TextStyle(color: _darkGreyColor),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _lightGreyColor),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _accentColor),
          children: [
            _buildHeaderCell('Fecha/Hora'),
            _buildHeaderCell('Usuario'),
            _buildHeaderCell('Acción'),
            _buildHeaderCell('Entidad'),
            _buildHeaderCell('Descripción'),
          ],
        ),
        // Filas de datos
        ...eventos.map((evento) => pw.TableRow(
              children: [
                _buildDataCell(DateFormat('dd/MM/yyyy\nHH:mm:ss', 'es').format(evento.fechaHora)),
                _buildDataCell(evento.usuarioNombre),
                _buildDataCell(evento.tipoAccionTexto),
                _buildDataCell(evento.entidadNombre ?? '-'),
                _buildDataCell(evento.descripcion, maxLines: 2),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildDataCell(String text, {int maxLines = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }
}


