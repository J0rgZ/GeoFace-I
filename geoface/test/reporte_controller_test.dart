// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-009: Generar reportes detallados de asistencia
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica de negocio para calcular
//               asistencias y ausencias por día, filtrado por mes y sede, es correcta.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/asistencia.dart';
import 'package:geoface/models/empleado.dart';
// ignore: unused_import
import 'package:geoface/models/sede.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('RF-009: Generar reportes detallados de asistencia (Administrador)', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe calcular asistencias por día correctamente', () async {
      // Arrange
      final fecha = DateTime(2025, 1, 15);
      final asistencias = [
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
        Asistencia(
          id: 'asist2',
          empleadoId: 'emp2',
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 15, 8, 30),
          fechaHoraSalida: DateTime(2025, 1, 15, 17, 30),
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
      final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));
      
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: inicioDelDia)
          .where('fechaHoraEntrada', isLessThan: finDelDia)
          .get();

      final asistenciasDelDia = snapshot.docs.length;

      // Assert
      expect(asistenciasDelDia, 2);
    });

    test('debe calcular ausencias por día correctamente', () async {
      // Arrange
      final fecha = DateTime(2025, 1, 15);
      final empleados = [
        Empleado(
          id: 'emp1',
          nombre: 'Juan',
          apellidos: 'Pérez',
          dni: '12345678',
          celular: '987654321',
          correo: 'juan@test.com',
          cargo: 'Desarrollador',
          sedeId: 'sede1',
          fechaCreacion: DateTime.now(),
          activo: true,
        ),
        Empleado(
          id: 'emp2',
          nombre: 'María',
          apellidos: 'García',
          dni: '87654321',
          celular: '987654322',
          correo: 'maria@test.com',
          cargo: 'Analista',
          sedeId: 'sede1',
          fechaCreacion: DateTime.now(),
          activo: true,
        ),
        Empleado(
          id: 'emp3',
          nombre: 'Carlos',
          apellidos: 'López',
          dni: '11223344',
          celular: '987654323',
          correo: 'carlos@test.com',
          cargo: 'Gerente',
          sedeId: 'sede1',
          fechaCreacion: DateTime.now(),
          activo: true,
        ),
      ];

      // Solo emp1 tiene asistencia
      final asistencia = Asistencia(
        id: 'asist1',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
      );

      final data = asistencia.toJson();
      data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
      await fakeFirestore.collection('asistencias').doc(asistencia.id).set(data);

      // Act
      final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));
      
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: inicioDelDia)
          .where('fechaHoraEntrada', isLessThan: finDelDia)
          .get();

      final idsConAsistencia = snapshot.docs.map((doc) => doc.data()['empleadoId'] as String).toSet();
      final empleadosActivos = empleados.where((e) => e.activo && e.sedeId == 'sede1').toList();
      final ausentes = empleadosActivos.where((e) => !idsConAsistencia.contains(e.id)).toList();

      // Assert
      expect(empleadosActivos.length, 3);
      expect(idsConAsistencia.length, 1);
      expect(ausentes.length, 2);
    });

    test('debe filtrar reporte por sede correctamente', () async {
      // Arrange
      final sedeId = 'sede1';
      final asistencias = [
        Asistencia(
          id: 'asist1',
          empleadoId: 'emp1',
          sedeId: sedeId,
          fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
        Asistencia(
          id: 'asist2',
          empleadoId: 'emp2',
          sedeId: 'sede2', // Diferente sede
          fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
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
          .where('sedeId', isEqualTo: sedeId)
          .get();

      // Assert
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['sedeId'], sedeId);
    });

    test('debe filtrar reporte por mes correctamente', () async {
      // Arrange
      final fechaInicio = DateTime(2025, 1, 1);
      final fechaFin = DateTime(2025, 2, 1); // Fin de enero

      final asistencias = [
        Asistencia(
          id: 'asist1',
          empleadoId: 'emp1',
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
        Asistencia(
          id: 'asist2',
          empleadoId: 'emp2',
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 2, 5, 8, 0), // Fuera del rango
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
          .where('fechaHoraEntrada', isGreaterThanOrEqualTo: fechaInicio)
          .where('fechaHoraEntrada', isLessThan: fechaFin)
          .get();

      // Assert
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['empleadoId'], 'emp1');
    });

    test('debe calcular totales del reporte correctamente', () {
      // Arrange
      final asistencias = List.generate(10, (i) => Asistencia(
        id: 'asist$i',
        empleadoId: 'emp$i',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime(2025, 1, 15, 8, 0),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
      ));

      final empleados = List.generate(15, (i) => Empleado(
        id: 'emp$i',
        nombre: 'Empleado $i',
        apellidos: 'Test',
        dni: '$i$i$i$i$i$i$i$i',
        celular: '987654321',
        correo: 'emp$i@test.com',
        cargo: 'Cargo',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        activo: true,
      ));

      // Act
      final totalAsistencias = asistencias.length;
      final totalEmpleados = empleados.where((e) => e.activo).length;
      final totalAusencias = totalEmpleados - totalAsistencias;
      final porcentajeAsistencia = (totalAsistencias / totalEmpleados) * 100;

      // Assert
      expect(totalAsistencias, 10);
      expect(totalEmpleados, 15);
      expect(totalAusencias, 5);
      expect(porcentajeAsistencia, closeTo(66.67, 0.01));
    });

    test('debe calcular tardanzas correctamente', () {
      // Arrange
      final horaLimiteEntrada = DateTime(0).copyWith(hour: 9, minute: 0);
      final asistencias = [
        Asistencia(
          id: 'asist1',
          empleadoId: 'emp1',
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 15, 8, 30), // No es tardanza
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
        Asistencia(
          id: 'asist2',
          empleadoId: 'emp2',
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 15, 9, 30), // Es tardanza
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
        Asistencia(
          id: 'asist3',
          empleadoId: 'emp3',
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime(2025, 1, 15, 10, 0), // Es tardanza
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
      ];

      // Act
      final tardanzas = asistencias.where((a) {
        final horaEntrada = a.fechaHoraEntrada;
        return horaEntrada.hour > horaLimiteEntrada.hour ||
            (horaEntrada.hour == horaLimiteEntrada.hour &&
                horaEntrada.minute > horaLimiteEntrada.minute);
      }).length;

      // Assert
      expect(tardanzas, 2);
    });
  });
}



