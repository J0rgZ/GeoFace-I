// -----------------------------------------------------------------------------
// @Encabezado:   Generador de Reporte PDF de Pruebas Unitarias
// @Autor:        Sistema Automatizado
// @Descripción:  Script para generar un reporte PDF con los resultados de
//               todas las pruebas unitarias ejecutadas.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class TestReportGenerator {
  final List<TestResult> testResults;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final DateTime executionDate;

  TestReportGenerator({
    required this.testResults,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.executionDate,
  });

  Future<void> generatePDF(String outputPath) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildSummary(),
          pw.SizedBox(height: 30),
          _buildTestDetails(),
          pw.SizedBox(height: 30),
          _buildRequisitosSummary(),
        ],
        header: (context) => _buildPageHeader(context),
        footer: (context) => _buildPageFooter(context),
      ),
    );

    final file = File(outputPath);
    await file.writeAsBytes(await doc.save());
    debugPrint('✅ Reporte PDF generado exitosamente en: $outputPath');
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REPORTE DE PRUEBAS UNITARIAS',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Sistema GeoFace - Control de Asistencia Laboral',
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Fecha de ejecución: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(executionDate)}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(thickness: 2, color: PdfColors.blueGrey800),
      ],
    );
  }

  pw.Widget _buildPageHeader(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Text(
        'Reporte de Pruebas Unitarias - GeoFace',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado automáticamente',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary() {
    final successRate = totalTests > 0 ? (passedTests / totalTests * 100) : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blueGrey200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMEN EJECUTIVO',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total de Pruebas', totalTests.toString(), PdfColors.blueGrey800),
              _buildStatCard('Pruebas Exitosas', passedTests.toString(), PdfColors.green700),
              _buildStatCard('Pruebas Fallidas', failedTests.toString(), PdfColors.red700),
              _buildStatCard('Tasa de Éxito', '${successRate.toStringAsFixed(1)}%', 
                successRate >= 90 ? PdfColors.green700 : PdfColors.orange700),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTestDetails() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALLE DE PRUEBAS POR REQUISITO FUNCIONAL',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 15),
        ...testResults.map((result) => _buildTestResultCard(result)),
      ],
    );
  }

  pw.Widget _buildTestResultCard(TestResult result) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: result.status == 'PASSED' ? PdfColors.green50 : PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: result.status == 'PASSED' ? PdfColors.green300 : PdfColors.red300,
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: result.status == 'PASSED' ? PdfColors.green700 : PdfColors.red700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  result.requisitoId,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  result.requisitoNombre,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: result.status == 'PASSED' ? PdfColors.green700 : PdfColors.red700,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  result.status,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Tests: ${result.testCount} | Archivo: ${result.testFile}',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          if (result.tests.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Pruebas individuales:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 5),
            ...result.tests.map((test) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 15, bottom: 3),
              child: pw.Row(
                children: [
                  pw.Text(
                    '✓ ',
                    style: pw.TextStyle(
                      color: PdfColors.green700,
                      fontSize: 10,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      test,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildRequisitosSummary() {
    final requisitosGrupo = <String, List<TestResult>>{};
    
    for (var result in testResults) {
      requisitosGrupo.putIfAbsent(result.requisitoId, () => []).add(result);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RESUMEN POR REQUISITO FUNCIONAL',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: [
                _buildTableCell('Requisito', isHeader: true),
                _buildTableCell('Nombre', isHeader: true),
                _buildTableCell('Tests', isHeader: true),
                _buildTableCell('Estado', isHeader: true),
              ],
            ),
            ...requisitosGrupo.entries.map((entry) {
              final results = entry.value;
              final totalTestsRequisito = results.fold<int>(0, (sum, r) => sum + r.testCount);
              final allPassed = results.every((r) => r.status == 'PASSED');
              
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: allPassed ? PdfColors.green50 : PdfColors.red50,
                ),
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell(results.first.requisitoNombre),
                  _buildTableCell(totalTestsRequisito.toString()),
                  _buildTableCell(
                    allPassed ? '✓ EXITOSO' : '✗ FALLIDO',
                    color: allPassed ? PdfColors.green700 : PdfColors.red700,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.blueGrey900 : PdfColors.grey800),
        ),
      ),
    );
  }
}

class TestResult {
  final String requisitoId;
  final String requisitoNombre;
  final String testFile;
  final int testCount;
  final String status;
  final List<String> tests;

  TestResult({
    required this.requisitoId,
    required this.requisitoNombre,
    required this.testFile,
    required this.testCount,
    required this.status,
    required this.tests,
  });
}



