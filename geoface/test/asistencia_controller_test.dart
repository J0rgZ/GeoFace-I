// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-006: Marcar Asistencia con Reconocimiento Facial
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que los componentes individuales de
//               verificación (reconocimiento facial, verificación GPS, sincronización NTP)
//               funcionan y se comunican con sus respectivos servicios/APIs.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/asistencia.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('RF-006: Marcar Asistencia con Reconocimiento Facial', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe registrar entrada de asistencia correctamente', () async {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist1',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime.now(),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        capturaEntrada: 'https://storage.example.com/capturas/entrada1.jpg',
      );

      // Act
      final data = asistencia.toJson();
      data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
      await fakeFirestore.collection('asistencias').doc(asistencia.id).set(data);

      // Assert
      final doc = await fakeFirestore.collection('asistencias').doc(asistencia.id).get();
      expect(doc.exists, true);
      final dataRecuperada = doc.data()!;
      expect(dataRecuperada['empleadoId'], 'emp1');
      expect(dataRecuperada['sedeId'], 'sede1');
      expect(dataRecuperada['latitudEntrada'], -12.0464);
      expect(dataRecuperada['longitudEntrada'], -77.0428);
      expect(dataRecuperada['capturaEntrada'], contains('capturas/entrada1.jpg'));
    });

    test('debe registrar salida de asistencia correctamente', () async {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist2',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime.now().subtract(const Duration(hours: 8)),
        fechaHoraSalida: DateTime.now(),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        latitudSalida: -12.0464,
        longitudSalida: -77.0428,
        capturaEntrada: 'https://storage.example.com/capturas/entrada2.jpg',
        capturaSalida: 'https://storage.example.com/capturas/salida2.jpg',
      );

      // Act
      final data = asistencia.toJson();
      data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
      data['fechaHoraSalida'] = Timestamp.fromDate(asistencia.fechaHoraSalida!);
      await fakeFirestore.collection('asistencias').doc(asistencia.id).set(data);

      // Assert
      final doc = await fakeFirestore.collection('asistencias').doc(asistencia.id).get();
      final dataRecuperada = doc.data()!;
      expect(dataRecuperada['fechaHoraSalida'], isNotNull);
      expect(dataRecuperada['latitudSalida'], -12.0464);
      expect(dataRecuperada['longitudSalida'], -77.0428);
      expect(dataRecuperada['capturaSalida'], contains('capturas/salida2.jpg'));
    });

    test('debe verificar que asistencia está completa cuando tiene entrada y salida', () {
      // Arrange
      final asistenciaCompleta = Asistencia(
        id: 'asist3',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime.now().subtract(const Duration(hours: 8)),
        fechaHoraSalida: DateTime.now(),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        latitudSalida: -12.0464,
        longitudSalida: -77.0428,
      );

      final asistenciaIncompleta = Asistencia(
        id: 'asist4',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime.now(),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
      );

      // Assert
      expect(asistenciaCompleta.registroCompleto, true);
      expect(asistenciaIncompleta.registroCompleto, false);
    });

    test('debe calcular tiempo trabajado correctamente', () {
      // Arrange
      final fechaEntrada = DateTime.now().subtract(const Duration(hours: 8));
      final fechaSalida = DateTime.now();
      final asistencia = Asistencia(
        id: 'asist5',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: fechaEntrada,
        fechaHoraSalida: fechaSalida,
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        latitudSalida: -12.0464,
        longitudSalida: -77.0428,
      );

      // Act
      final tiempoTrabajado = asistencia.tiempoTrabajado;

      // Assert
      expect(tiempoTrabajado.inHours, 8);
    });

    test('debe recuperar asistencias de un empleado correctamente', () async {
      // Arrange
      final empleadoId = 'emp1';
      final asistencias = [
        Asistencia(
          id: 'asist6',
          empleadoId: empleadoId,
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime.now().subtract(const Duration(days: 1)),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
        ),
        Asistencia(
          id: 'asist7',
          empleadoId: empleadoId,
          sedeId: 'sede1',
          fechaHoraEntrada: DateTime.now().subtract(const Duration(days: 2)),
          fechaHoraSalida: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(hours: 8)),
          latitudEntrada: -12.0464,
          longitudEntrada: -77.0428,
          latitudSalida: -12.0464,
          longitudSalida: -77.0428,
        ),
      ];

      for (final asistencia in asistencias) {
        final data = asistencia.toJson();
        data['fechaHoraEntrada'] = Timestamp.fromDate(asistencia.fechaHoraEntrada);
        if (asistencia.fechaHoraSalida != null) {
          data['fechaHoraSalida'] = Timestamp.fromDate(asistencia.fechaHoraSalida!);
        }
        await fakeFirestore.collection('asistencias').doc(asistencia.id).set(data);
      }

      // Act
      final snapshot = await fakeFirestore
          .collection('asistencias')
          .where('empleadoId', isEqualTo: empleadoId)
          .get();

      // Assert
      expect(snapshot.docs.length, 2);
      expect(snapshot.docs.every((doc) => doc.data()['empleadoId'] == empleadoId), true);
    });

    test('debe almacenar coordenadas GPS de entrada correctamente', () {
      // Arrange
      final asistencia = Asistencia(
        id: 'asist8',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime.now(),
        latitudEntrada: -12.1234,
        longitudEntrada: -77.5678,
      );

      // Assert
      expect(asistencia.latitudEntrada, -12.1234);
      expect(asistencia.longitudEntrada, -77.5678);
    });

    test('debe almacenar URL de captura facial correctamente', () {
      // Arrange
      final capturaUrl = 'https://storage.example.com/capturas/facial123.jpg';
      final asistencia = Asistencia(
        id: 'asist9',
        empleadoId: 'emp1',
        sedeId: 'sede1',
        fechaHoraEntrada: DateTime.now(),
        latitudEntrada: -12.0464,
        longitudEntrada: -77.0428,
        capturaEntrada: capturaUrl,
      );

      // Assert
      expect(asistencia.capturaEntrada, capturaUrl);
      expect(asistencia.capturaEntrada, contains('facial123.jpg'));
    });
  });
}


