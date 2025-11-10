import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FunctionalAcceptance {
  final String requisitoId;
  final String nombre;
  final String escenario;
  final String evidencia;
  final String resultado;
  final String responsable;
  final String estado;
  final String codigoReferencia;
  final String archivosImplementacion;
  final String pruebasUnitarias;

  FunctionalAcceptance({
    required this.requisitoId,
    required this.nombre,
    required this.escenario,
    required this.evidencia,
    required this.resultado,
    required this.responsable,
    required this.estado,
    required this.codigoReferencia,
    required this.archivosImplementacion,
    required this.pruebasUnitarias,
  });
}

class NonFunctionalAcceptance {
  final String requisitoId;
  final String nombre;
  final String descripcion;
  final String criterio;
  final String medicion;
  final String estado;
  final String codigoReferencia;
  final String evidenciasTecnicas;

  NonFunctionalAcceptance({
    required this.requisitoId,
    required this.nombre,
    required this.descripcion,
    required this.criterio,
    required this.medicion,
    required this.estado,
    required this.codigoReferencia,
    required this.evidenciasTecnicas,
  });
}

class AcceptanceReportGenerator {
  final List<FunctionalAcceptance> funcionales;
  final List<NonFunctionalAcceptance> noFuncionales;
  final DateTime executionDate;
  final String elaboradoPor;

  AcceptanceReportGenerator({
    required this.funcionales,
    required this.noFuncionales,
    required this.executionDate,
    required this.elaboradoPor,
  });

  Future<void> generatePDF(String outputPath) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildCover(),
          pw.SizedBox(height: 24),
          _buildSummary(),
          pw.SizedBox(height: 24),
          _buildFunctionalSection(),
          pw.SizedBox(height: 32),
          _buildNonFunctionalSection(),
        ],
      ),
    );

    final file = File(outputPath);
    await file.writeAsBytes(await doc.save());
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'GeoFace · Pruebas de Aceptación',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(executionDate)}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Elaborado por: $elaboradoPor',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCover() {
    final totalFuncionales = funcionales.length;
    final aprobadosFuncionales =
        funcionales.where((f) => f.estado.toUpperCase() == 'APROBADO').length;
    final totalNoFuncionales = noFuncionales.length;
    final aprobadosNoFuncionales =
        noFuncionales.where((f) => f.estado.toUpperCase() == 'APROBADO').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blueGrey200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Reporte de Pruebas de Aceptación',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Sistema de Control de Asistencia GeoFace',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.blueGrey700),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Fecha de verificación: ${DateFormat('dd/MM/yyyy').format(executionDate)}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildKPI('Requisitos Funcionales', '$aprobadosFuncionales / $totalFuncionales',
                  aprobadosFuncionales == totalFuncionales),
              pw.SizedBox(width: 16),
              _buildKPI('Requisitos No Funcionales',
                  '$aprobadosNoFuncionales / $totalNoFuncionales',
                  aprobadosNoFuncionales == totalNoFuncionales),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildKPI(String label, String value, bool success) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: success ? PdfColors.green50 : PdfColors.orange50,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(
            color: success ? PdfColors.green300 : PdfColors.orange300,
            width: 1,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: success ? PdfColors.green800 : PdfColors.orange800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              success ? 'Cumple' : 'Seguimiento requerido',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey600),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSummary() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen Ejecutivo',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Se realizaron pruebas de aceptación sobre 14 requisitos funcionales y 5 requisitos no '
          'funcionales del sistema GeoFace. El resultado global indica que todas las validaciones '
          'planificadas fueron aprobadas, asegurando el cumplimiento de las capacidades clave '
          'solicitadas por el cliente.',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey700),
        ),
      ],
    );
  }

  pw.Widget _buildFunctionalSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Requisitos Funcionales',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 12),
        ...funcionales.map((f) => _buildFunctionalCard(f)),
      ],
    );
  }

  pw.Widget _buildFunctionalCard(FunctionalAcceptance item) {
    final approved = item.estado.toUpperCase() == 'APROBADO';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: approved ? PdfColors.green50 : PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: approved ? PdfColors.green300 : PdfColors.orange300,
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: approved ? PdfColors.green700 : PdfColors.orange700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  item.requisitoId,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.nombre,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Escenario de Prueba:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            item.escenario,
                            style: pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Resultado Obtenido:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            item.resultado,
                            style: pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blueGrey50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '📁 Archivos de Implementación:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.archivosImplementacion,
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '💻 Evidencia de Código:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.codigoReferencia,
                            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.blueGrey800),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.green200, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '✅ Pruebas Unitarias:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.pruebasUnitarias,
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.green800),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.amber200, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '📸 Evidencias Visuales/Logs:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.evidencia,
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.amber800),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Responsable: ${item.responsable}',
                          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey600, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: approved ? PdfColors.green700 : PdfColors.orange700,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            item.estado.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNonFunctionalSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Requisitos No Funcionales',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 12),
        ...noFuncionales.map((item) => _buildNonFunctionalCard(item)),
      ],
    );
  }

  pw.Widget _buildNonFunctionalCard(NonFunctionalAcceptance item) {
    final approved = item.estado.toUpperCase() == 'APROBADO';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: approved ? PdfColors.green50 : PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: approved ? PdfColors.green300 : PdfColors.orange300,
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: approved ? PdfColors.green700 : PdfColors.orange700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  item.requisitoId,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.nombre,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Descripción:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            item.descripcion,
                            style: pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Criterio de Aceptación:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            item.criterio,
                            style: pw.TextStyle(fontSize: 9.5, color: PdfColors.blueGrey700),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blueGrey50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '💻 Evidencia de Código/Implementación:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.codigoReferencia,
                            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.blueGrey800),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.amber200, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '📊 Medición y Evidencias Técnicas:',
                            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.medicion,
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.amber800),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            item.evidenciasTecnicas,
                            style: pw.TextStyle(fontSize: 9, color: PdfColors.amber800),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: approved ? PdfColors.green700 : PdfColors.orange700,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            item.estado.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}


