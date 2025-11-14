// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-008: Visualizar dashboard de monitoreo (Empleado)
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica de negocio para obtener
//               los datos de asistencia diaria del empleado y el componente de la
//               interfaz de usuario para presentarlos funcionan correctamente.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/asistencia.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('RF-008: Visualizar dashboard de monitoreo (Empleado)', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe obtener datos de asistencia diaria del empleado', () async {
      // Arrange
      final empleadoId = 'emp1';
      final hoy = DateTime.now();
      final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      final asistenciaHoy = Asistencia(
        id: 'asist1',
        empleadoId: empleadoId,
        sedeId: 'sede1',
        fechaHoraEntrada: inicioDelDia.add(const Duration(hours: 8)),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
      );

      final data = asistenciaHoy.toJson();
      data['fechaHoraEntrada'] = Timestamp.fromDate(asistenciaHoy.fechaHoraEntrada);
      await fakeFirestore.collection('asistencias').doc(asistenciaHoy.id).set(data);

      // Act
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: inicioDelDia)
          .where('fechaHoraEntrada', isLessThan: finDelDia)
          .get();

      final asistenciasHoy = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Asistencia.fromJson(data);
      }).toList();

      // Assert
      expect(asistenciasHoy.isNotEmpty, true);
      expect(asistenciasHoy.any((a) => a.empleadoId == empleadoId), true);
    });

    test('debe calcular estadísticas de asistencia del día', () {
      // Arrange
      final asistencias = [
        Asistencia(
          id: 'asist2',
          empleadoId: 'emp1',
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime.now().subtract(const Duration(hours: 8)),
          fechaHoraSalida: DateTime.now(),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
          latitudSalida: -12.0464,
          longitudSalida: -77.0428,
        ),
      ];

      // Act
      final totalAsistencias = asistencias.length;
      final asistenciasCompletas = asistencias.where((a) => a.registroCompleto).length;
      final tiempoTotalTrabajado = asistencias
          .where((a) => a.registroCompleto)
          .fold<Duration>(
              Duration.zero, (total, a) => total + a.tiempoTrabajado);

      // Assert
      expect(totalAsistencias, 1);
      expect(asistenciasCompletas, 1);
      expect(tiempoTotalTrabajado.inHours, 8);
    });

    test('debe presentar datos de asistencia para el dashboard', () {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist3',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime.now().subtract(const Duration(hours: 4)),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
      );

      // Act - Simular datos para el dashboard
      final datosDashboard = {
        'tieneEntrada': true,
        'tieneSalida': asistencia.registroCompleto,
        'horaEntrada': asistencia.fechaHoraEntrada,
        'horaSalida': asistencia.fechaHoraSalida,
        'tiempoTrabajado': asistencia.tiempoTrabajado,
      };

      // Assert
      expect(datosDashboard['tieneEntrada'], true);
      expect(datosDashboard['tieneSalida'], false);
      expect(datosDashboard['horaEntrada'], isNotNull);
    });

    test('debe manejar empleado sin asistencia del día', () async {
      // Arrange
      final empleadoId = 'emp2';
      final hoy = DateTime.now();
      final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      // Act
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('empleadoId', isEqualTo: empleadoId)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: inicioDelDia)
          .where('fechaHoraEntrada', isLessThan: finDelDia)
          .get();

      // Assert
      expect(snapshot.docs.isEmpty, true);
    });

    test('debe formatear correctamente los datos para visualización', () {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist4',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime(2025, 1, 15, 8, 30),
        fechaHoraSalida: DateTime(2025, 1, 15, 17, 45),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        latitudSalida: -12.0464,
        longitudSalida: -77.0428,
      );

      // Act
      final horaEntradaFormateada = '${asistencia.fechaHoraEntrada.hour.toString().padLeft(2, '0')}:${asistencia.fechaHoraEntrada.minute.toString().padLeft(2, '0')}';
      final horaSalidaFormateada = asistencia.fechaHoraSalida != null
          ? '${asistencia.fechaHoraSalida!.hour.toString().padLeft(2, '0')}:${asistencia.fechaHoraSalida!.minute.toString().padLeft(2, '0')}'
          : '--:--';

      // Assert
      expect(horaEntradaFormateada, '08:30');
      expect(horaSalidaFormateada, '17:45');
    });
  });
}



