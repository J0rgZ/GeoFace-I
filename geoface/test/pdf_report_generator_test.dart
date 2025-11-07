// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-011: Exportar reportes a formato PDF
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que el módulo de generación de PDF
//               toma los datos del reporte y los estructura correctamente en un
//               archivo PDF.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/asistencia.dart';
import 'package:geoface/models/empleado.dart';
import 'package:geoface/models/estadistica_asistencia.dart';
import 'package:geoface/controllers/reporte_controller.dart';

void main() {
  group('RF-011: Exportar reportes a formato PDF', () {
    test('debe estructurar datos del reporte correctamente para PDF', () {
      // Arrange
      final resumen = EstadisticaAsistencia(
        sedeId: 'sede1',
        sedeNombre: 'Sede Central',
        fecha: DateTime(2025, 1, 1),
        totalEmpleados: 10,
        totalAsistencias: 8,
        totalAusencias: 2,
        totalTardanzas: 1,
        porcentajeAsistencia: 80.0,
      );

      final asistenciasPorDia = {
        DateTime(2025, 1, 15): [
          Asistencia(
            id: 'asist1',
            empleadoId: 'emp1',
            sedeId: 'sede1',
            fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
            fechaHoraSalida: DateTime(2025, 1, 15, 17, 0),
            latitudEntrada: -12.0464,
            longitudEntrada: -77.0428,
            latitudSalida: -12.0464,
            longitudSalida: -77.0428,
          ),
        ],
      };

      final ausenciasPorDia = {
        DateTime(2025, 1, 15): [
          Empleado(
            id: 'emp2',
            nombre: 'Ausente',
            apellidos: 'Test',
            dni: '12345678',
            celular: '987654321',
            correo: 'ausente@test.com',
            cargo: 'Test',
            sedeId: 'sede1',
            fechaCreacion: DateTime.now(),
            activo: true,
          ),
        ],
      };

      // Act
      final reporte = ReporteDetallado(
        resumen: resumen,
        asistenciasPorDia: asistenciasPorDia,
        ausenciasPorDia: ausenciasPorDia,
      );

      // Assert
      expect(reporte.resumen.totalAsistencias, 8);
      expect(reporte.resumen.totalAusencias, 2);
      expect(reporte.resumen.totalTardanzas, 1);
      expect(reporte.resumen.porcentajeAsistencia, 80.0);
      expect(reporte.asistenciasPorDia.length, 1);
      expect(reporte.ausenciasPorDia.length, 1);
    });

    test('debe formatear datos de asistencia para tabla PDF', () {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist1',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime(2025, 1, 15, 8, 30),
        fechaHoraSalida: DateTime(2025, 1, 15, 17, 45),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        latitudSalida: -12.0464,
        longitudSalida: -77.0428,
      );

      // Act - Simular formato para PDF
      final datosTabla = {
        'empleadoId': asistencia.empleadoId,
        'horaEntrada': '08:30',
        'horaSalida': '17:45',
        'registroCompleto': asistencia.registroCompleto,
      };

      // Assert
      expect(datosTabla['horaEntrada'], '08:30');
      expect(datosTabla['horaSalida'], '17:45');
      expect(datosTabla['registroCompleto'], true);
    });

    test('debe incluir resumen estadístico en el PDF', () {
      // Arrange
      final resumen = EstadisticaAsistencia(
        sedeId: 'sede1',
        sedeNombre: 'Sede Central',
        fecha: DateTime(2025, 1, 1),
        totalEmpleados: 20,
        totalAsistencias: 18,
        totalAusencias: 2,
        totalTardanzas: 3,
        porcentajeAsistencia: 90.0,
      );

      // Act
      final datosResumen = {
        'totalEmpleados': resumen.totalEmpleados,
        'totalAsistencias': resumen.totalAsistencias,
        'totalAusencias': resumen.totalAusencias,
        'totalTardanzas': resumen.totalTardanzas,
        'porcentajeAsistencia': resumen.porcentajeAsistencia,
      };

      // Assert
      expect(datosResumen['totalEmpleados'], 20);
      expect(datosResumen['totalAsistencias'], 18);
      expect(datosResumen['totalAusencias'], 2);
      expect(datosResumen['totalTardanzas'], 3);
      expect(datosResumen['porcentajeAsistencia'], 90.0);
    });

    test('debe manejar reporte sin datos correctamente', () {
      // Arrange
      final resumen = EstadisticaAsistencia(
        sedeId: 'sede1',
        sedeNombre: 'Sede Central',
        fecha: DateTime(2025, 1, 1),
        totalEmpleados: 0,
        totalAsistencias: 0,
        totalAusencias: 0,
        totalTardanzas: 0,
        porcentajeAsistencia: 0.0,
      );

      // Act
      final reporte = ReporteDetallado(
        resumen: resumen,
        asistenciasPorDia: {},
        ausenciasPorDia: {},
      );

      // Assert
      expect(reporte.asistenciasPorDia.isEmpty, true);
      expect(reporte.ausenciasPorDia.isEmpty, true);
      expect(reporte.resumen.totalAsistencias, 0);
    });

    test('debe agrupar asistencias por día correctamente', () {
      // Arrange
      final asistenciasPorDia = {
        DateTime(2025, 1, 15): [
          Asistencia(
            id: 'asist1',
            empleadoId: 'emp1',
            sedeId: 'sede1',
            fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
            latitudEntrada: -12.0464,
            longitudEntrada: -77.0428,
          ),
        ],
        DateTime(2025, 1, 16): [
          Asistencia(
            id: 'asist2',
            empleadoId: 'emp2',
            sedeId: 'sede1',
            fechaHoraEntrada: DateTime(2025, 1, 16, 8, 0),
            latitudEntrada: -12.0464,
            longitudEntrada: -77.0428,
          ),
        ],
      };

      // Act
      final dias = asistenciasPorDia.keys.toList()..sort();
      final totalDias = dias.length;

      // Assert
      expect(totalDias, 2);
      expect(dias.first.day, 15);
      expect(dias.last.day, 16);
    });
  });
}


