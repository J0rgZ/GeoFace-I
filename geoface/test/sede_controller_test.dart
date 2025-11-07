// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-002: Gestión de Sedes con Perímetros
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que los métodos CRUD para la
//               gestión de sedes persisten y recuperan correctamente los datos
//               (nombre, dirección, coordenadas, radio).
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/sede.dart';
// ignore: unused_import
import 'package:geoface/services/sede_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('RF-002: Gestión de Sedes con Perímetros', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe crear una sede con todos los datos correctamente', () async {
      // Arrange
      final sede = Sede(
        id: 'sede1',
        nombre: 'Sede Central',
        direccion: 'Av. Principal 123',
        latitud: -12.0464,
        longitud: -77.0428,
        radioPermitido: 100,
        activa: true,
        fechaCreacion: DateTime.now(),
      );

      // Act
      await fakeFirestore.collection('sedes').doc(sede.id).set(sede.toJson());
      final doc = await fakeFirestore.collection('sedes').doc(sede.id).get();

      // Assert
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['nombre'], 'Sede Central');
      expect(data['direccion'], 'Av. Principal 123');
      expect(data['latitud'], -12.0464);
      expect(data['longitud'], -77.0428);
      expect(data['radioPermitido'], 100);
      expect(data['activa'], true);
    });

    test('debe recuperar una sede por ID correctamente', () async {
      // Arrange
      final sede = Sede(
        id: 'sede2',
        nombre: 'Sede Norte',
        direccion: 'Av. Norte 456',
        latitud: -12.0464,
        longitud: -77.0428,
        radioPermitido: 150,
        activa: true,
        fechaCreacion: DateTime.now(),
      );
      await fakeFirestore.collection('sedes').doc(sede.id).set(sede.toJson());

      // Act
      final doc = await fakeFirestore.collection('sedes').doc(sede.id).get();
      final sedeRecuperada = Sede.fromJson({'id': doc.id, ...doc.data()!});

      // Assert
      expect(sedeRecuperada.id, 'sede2');
      expect(sedeRecuperada.nombre, 'Sede Norte');
      expect(sedeRecuperada.direccion, 'Av. Norte 456');
      expect(sedeRecuperada.latitud, -12.0464);
      expect(sedeRecuperada.longitud, -77.0428);
      expect(sedeRecuperada.radioPermitido, 150);
    });

    test('debe actualizar los datos de una sede correctamente', () async {
      // Arrange
      final sede = Sede(
        id: 'sede3',
        nombre: 'Sede Sur',
        direccion: 'Av. Sur 789',
        latitud: -12.0464,
        longitud: -77.0428,
        radioPermitido: 200,
        activa: true,
        fechaCreacion: DateTime.now(),
      );
      await fakeFirestore.collection('sedes').doc(sede.id).set(sede.toJson());

      // Act
      final sedeActualizada = sede.copyWith(
        nombre: 'Sede Sur Actualizada',
        radioPermitido: 250,
        activa: false,
      );
      await fakeFirestore.collection('sedes').doc(sede.id).update(sedeActualizada.toJson());
      final doc = await fakeFirestore.collection('sedes').doc(sede.id).get();
      final sedeRecuperada = Sede.fromJson({'id': doc.id, ...doc.data()!});

      // Assert
      expect(sedeRecuperada.nombre, 'Sede Sur Actualizada');
      expect(sedeRecuperada.radioPermitido, 250);
      expect(sedeRecuperada.activa, false);
    });

    test('debe eliminar una sede correctamente', () async {
      // Arrange
      final sede = Sede(
        id: 'sede4',
        nombre: 'Sede Este',
        direccion: 'Av. Este 321',
        latitud: -12.0464,
        longitud: -77.0428,
        radioPermitido: 120,
        activa: true,
        fechaCreacion: DateTime.now(),
      );
      await fakeFirestore.collection('sedes').doc(sede.id).set(sede.toJson());

      // Act
      await fakeFirestore.collection('sedes').doc(sede.id).delete();
      final doc = await fakeFirestore.collection('sedes').doc(sede.id).get();

      // Assert
      expect(doc.exists, false);
    });

    test('debe listar todas las sedes correctamente', () async {
      // Arrange
      final sedes = [
        Sede(
          id: 'sede5',
          nombre: 'Sede A',
          direccion: 'Dirección A',
          latitud: -12.0464,
          longitud: -77.0428,
          radioPermitido: 100,
          activa: true,
          fechaCreacion: DateTime.now(),
        ),
        Sede(
          id: 'sede6',
          nombre: 'Sede B',
          direccion: 'Dirección B',
          latitud: -12.0564,
          longitud: -77.0528,
          radioPermitido: 150,
          activa: true,
          fechaCreacion: DateTime.now(),
        ),
      ];

      for (final sede in sedes) {
        await fakeFirestore.collection('sedes').doc(sede.id).set(sede.toJson());
      }

      // Act
      final snapshot = await fakeFirestore.collection('sedes').get();
      final sedesRecuperadas = snapshot.docs
          .map((doc) => Sede.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      // Assert
      expect(sedesRecuperadas.length, 2);
      expect(sedesRecuperadas.any((s) => s.nombre == 'Sede A'), true);
      expect(sedesRecuperadas.any((s) => s.nombre == 'Sede B'), true);
    });

    test('debe persistir coordenadas y radio correctamente', () {
      // Arrange
      final sede = Sede(
        id: 'sede7',
        nombre: 'Sede con Coordenadas',
        direccion: 'Dirección Test',
        latitud: -12.1234,
        longitud: -77.5678,
        radioPermitido: 200,
        activa: true,
        fechaCreacion: DateTime.now(),
      );

      // Act
      final json = sede.toJson();
      final sedeFromJson = Sede.fromJson({'id': sede.id, ...json});

      // Assert
      expect(sedeFromJson.latitud, -12.1234);
      expect(sedeFromJson.longitud, -77.5678);
      expect(sedeFromJson.radioPermitido, 200);
    });
  });
}

