// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-007: Visualizar detalle de asistencia diaria
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica para recuperar y
//               formatear los registros de asistencia de un empleado específico es correcta.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/asistencia.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('RF-007: Visualizar detalle de asistencia diaria (Empleado)', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe recuperar registros de asistencia de un empleado específico', () async {
      // Arrange
      final empleadoId = 'emp1';
      final asistencias = [
        Asistencia(
          id: 'asist1',
          empleadoId: empleadoId,
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
          fechaHoraSalida: DateTime(2025, 1, 15, 17, 0),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
          latitudSalida: -12.0464,
          longitudSalida: -77.0428,
        ),
        Asistencia(
          id: 'asist2',
          empleadoId: empleadoId,
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 16, 8, 30),
          fechaHoraSalida: DateTime(2025, 1, 16, 17, 30),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
          latitudSalida: -12.0464,
          longitudSalida: -77.0428,
        ),
      ];

      for (final asistencia in asistencias) {
        final data = asistencia.toJson();
        data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
        data['fechaHoraSalida'] = Timestamp.fromDate(asistencia.fechaHoraSalida!);
        await fakeFirestore.collection('asistencias').doc(asistencia.id).set(data);
      }

      // Act
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('empleadoId', isEqualTo: empleadoId)
          .orderBy('fechaHoraEntrada', descending: true)
          .get();

      final asistenciasRecuperadas = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Asistencia.fromJson(data);
      }).toList();

      // Assert
      expect(asistenciasRecuperadas.length, 2);
      expect(asistenciasRecuperadas.every((a) => a.empleadoId == empleadoId), true);
      expect(asistenciasRecuperadas.first.fechaHoraEntrada.isAfter(
          asistenciasRecuperadas.last.fechaHoraEntrada), true);
    });

    test('debe formatear correctamente los datos de asistencia para visualización', () {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist3',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
        fechaHoraSalida: DateTime(2025, 1, 15, 17, 0),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        latitudSalida: -12.0464,
        longitudSalida: -77.0428,
      );

      // Act
      final tiempoTrabajado = asistencia.tiempoTrabajado;
      final registroCompleto = asistencia.registroCompleto;

      // Assert
      expect(registroCompleto, true);
      expect(tiempoTrabajado.inHours, 9);
      expect(asistencia.fechaHoraEntrada.day, 15);
      expect(asistencia.fechaHoraSalida?.day, 15);
    });

    test('debe manejar asistencia sin salida (jornada incompleta)', () {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist4',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
      );

      // Assert
      expect(asistencia.registroCompleto, false);
      expect(asistencia.fechaHoraSalida, isNull);
    });

    test('debe ordenar asistencias por fecha descendente', () async {
      // Arrange
      final empleadoId = 'emp2';
      final fechas = [
        DateTime(2025, 1, 10, 8, 0),
        DateTime(2025, 1, 12, 8, 0),
        DateTime(2025, 1, 11, 8, 0),
      ];

      for (var i = 0; i < fechas.length; i++) {
        final asistencia = Asistencia(
          id: 'asist$i',
          empleadoId: empleadoId,
          sedeId: 'sede1',
          fechaHoraEntrada: fechas[i],
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        );
        final data = asistencia.toJson();
        data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
        await fakeFirestore.collection('asistencias').doc(asistencia.id).set(data);
      }

      // Act
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('empleadoId', isEqualTo: empleadoId)
          .orderBy('fechaHoraEntrada', descending: true)
          .get();

      final asistenciasOrdenadas = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Asistencia.fromJson(data);
      }).toList();

      // Assert
      expect(asistenciasOrdenadas.length, 3);
      expect(asistenciasOrdenadas[0].fechaHoraEntrada.day, 12);
      expect(asistenciasOrdenadas[1].fechaHoraEntrada.day, 11);
      expect(asistenciasOrdenadas[2].fechaHoraEntrada.day, 10);
    });

    test('debe recuperar asistencias filtradas por rango de fechas', () async {
      // Arrange
      final empleadoId = 'emp3';
      final fechaInicio = DateTime(2025, 1, 1);
      final fechaFin = DateTime(2025, 1, 31);

      final asistencias = [
        Asistencia(
          id: 'asist5',
          empleadoId: empleadoId,
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
        Asistencia(
          id: 'asist6',
          empleadoId: empleadoId,
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 2, 1, 8, 0), // Fuera del rango
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
      ];

      for (final asistencia in asistencias) {
        final data = asistencia.toJson();
        data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
        await fakeFirestore.collection('asistencias').doc(asistencia.id).set(data);
      }

      // Act
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('empleadoId', isEqualTo: empleadoId)
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: fechaInicio)
          .where('fechaHoraEntrada', isLessThan: fechaFin)
          .get();

      final asistenciasFiltradas = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Asistencia.fromJson(data);
      }).toList();

      // Assert
      expect(asistenciasFiltradas.length, 1);
      expect(asistenciasFiltradas.first.id, 'asist5');
    });
  });
}


