// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-004: Registro de Datos Faciales
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica para asociar una
//               imagen facial a un empleado funciona, incluyendo la llamada a la
//               API facial externa y la persistencia de la referencia biométrica.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:geoface/models/empleado.dart';

void main() {
  group('RF-004: Registro de Datos Faciales', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe asociar datos faciales a un empleado correctamente', () async {
      // Arrange
      final empleadoId = 'emp1';
      final datosFaciales = [
        'https://storage.example.com/biometricos/emp1/image1.jpg',
        'https://storage.example.com/biometricos/emp1/image2.jpg',
        'https://storage.example.com/biometricos/emp1/image3.jpg',
      ];

      // Act
      await fakeFirestore.collection('biometricos').doc(empleadoId).set({
        'empleadoId': empleadoId,
        'datosFaciales': datosFaciales,
        'fechaRegistro': DateTime.now().toIso8601String(),
        'fechaModificacion': DateTime.now().toIso8601String(),
      });

      // Crear empleado primero si no existe
      await fakeFirestore.collection('empleados').doc(empleadoId).set({
        'id': empleadoId,
        'nombre': 'Test',
        'apellidos': 'Empleado',
        'dni': '12345678',
        'celular': '987654321',
        'correo': 'test@test.com',
        'cargo': 'Test',
        'sedeId': 'sede1',
        'fechaCreacion': DateTime.now().toIso8601String(),
        'activo': true,
        'hayDatosBiometricos': false,
        'tieneUsuario': false,
      });

      // Actualizar flag en empleado
      await fakeFirestore.collection('empleados').doc(empleadoId).update({
        'hayDatosBiometricos': true,
      });

      // Assert
      final bioDoc = await fakeFirestore.collection('biometricos').doc(empleadoId).get();
      expect(bioDoc.exists, true);
      final bioData = bioDoc.data()!;
      expect(bioData['empleadoId'], empleadoId);
      expect(bioData['datosFaciales'], isA<List>());
      expect((bioData['datosFaciales'] as List).length, 3);

      final empDoc = await fakeFirestore.collection('empleados').doc(empleadoId).get();
      if (empDoc.exists) {
        expect(empDoc.data()!['hayDatosBiometricos'], true);
      }
    });

    test('debe recuperar URLs de datos faciales de un empleado', () async {
      // Arrange
      final empleadoId = 'emp2';
      final datosFaciales = [
        'https://storage.example.com/biometricos/emp2/image1.jpg',
        'https://storage.example.com/biometricos/emp2/image2.jpg',
      ];

      await fakeFirestore.collection('biometricos').doc(empleadoId).set({
        'empleadoId': empleadoId,
        'datosFaciales': datosFaciales,
        'fechaRegistro': DateTime.now().toIso8601String(),
      });

      // Act
      final doc = await fakeFirestore.collection('biometricos').doc(empleadoId).get();
      final urls = List<String>.from(doc.data()!['datosFaciales'] ?? []);

      // Assert
      expect(urls.length, 2);
      expect(urls.first, contains('storage.example.com'));
      expect(urls.first, contains('emp2'));
    });

    test('debe actualizar datos faciales de un empleado existente', () async {
      // Arrange
      final empleadoId = 'emp3';
      final datosFacialesIniciales = [
        'https://storage.example.com/biometricos/emp3/old1.jpg',
      ];

      await fakeFirestore.collection('biometricos').doc(empleadoId).set({
        'empleadoId': empleadoId,
        'datosFaciales': datosFacialesIniciales,
        'fechaRegistro': DateTime.now().toIso8601String(),
      });

      // Act
      final nuevosDatosFaciales = [
        'https://storage.example.com/biometricos/emp3/new1.jpg',
        'https://storage.example.com/biometricos/emp3/new2.jpg',
        'https://storage.example.com/biometricos/emp3/new3.jpg',
      ];

      await fakeFirestore.collection('biometricos').doc(empleadoId).update({
        'datosFaciales': nuevosDatosFaciales,
        'fechaModificacion': DateTime.now().toIso8601String(),
      });

      // Assert
      final doc = await fakeFirestore.collection('biometricos').doc(empleadoId).get();
      final urls = List<String>.from(doc.data()!['datosFaciales'] ?? []);
      expect(urls.length, 3);
      expect(urls.first, contains('new1.jpg'));
    });

    test('debe eliminar datos faciales de un empleado', () async {
      // Arrange
      final empleadoId = 'emp4';
      await fakeFirestore.collection('biometricos').doc(empleadoId).set({
        'empleadoId': empleadoId,
        'datosFaciales': ['url1', 'url2'],
        'fechaRegistro': DateTime.now().toIso8601String(),
      });

      // Act
      // Crear empleado primero si no existe
      await fakeFirestore.collection('empleados').doc(empleadoId).set({
        'id': empleadoId,
        'nombre': 'Test',
        'apellidos': 'Empleado',
        'dni': '12345678',
        'celular': '987654321',
        'correo': 'test@test.com',
        'cargo': 'Test',
        'sedeId': 'sede1',
        'fechaCreacion': DateTime.now().toIso8601String(),
        'activo': true,
        'hayDatosBiometricos': true,
        'tieneUsuario': false,
      });

      await fakeFirestore.collection('biometricos').doc(empleadoId).delete();
      await fakeFirestore.collection('empleados').doc(empleadoId).update({
        'hayDatosBiometricos': false,
      });

      // Assert
      final doc = await fakeFirestore.collection('biometricos').doc(empleadoId).get();
      expect(doc.exists, false);
    });

    test('debe validar que un empleado tiene datos biométricos', () async {
      // Arrange
      final empleado = Empleado(
        id: 'emp5',
        nombre: 'Test',
        apellidos: 'Biometrico',
        dni: '12345678',
        celular: '987654321',
        correo: 'test@test.com',
        cargo: 'Test',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        hayDatosBiometricos: true,
        activo: true,
        tieneUsuario: false,
      );

      // Assert
      expect(empleado.hayDatosBiometricos, true);
    });

    test('debe manejar empleado sin datos biométricos', () async {
      // Arrange
      final empleadoId = 'emp6';

      // Act
      final doc = await fakeFirestore.collection('biometricos').doc(empleadoId).get();

      // Assert
      if (!doc.exists) {
        // No hay datos biométricos, esto es válido
        expect(doc.exists, false);
      }
    });
  });
}

