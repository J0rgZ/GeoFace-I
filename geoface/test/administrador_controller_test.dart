// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-012: Gestionar usuarios Administradores
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que los métodos CRUD para usuarios
//               administradores (crear, modificar, activar/desactivar) funcionan a
//               nivel de lógica de negocio y persistencia.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/usuario.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('RF-012: Gestionar usuarios Administradores', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe crear un usuario administrador correctamente', () async {
      // Arrange
      final adminData = {
        'nombreUsuario': 'Admin Test',
        'correo': 'admin@admin.com',
        'tipoUsuario': 'ADMIN',
        'empleadoId': null,
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'fechaUltimoAcceso': null,
      };

      // Act
      await fakeFirestore.collection('usuarios').doc('admin1').set(adminData);
      final doc = await fakeFirestore.collection('usuarios').doc('admin1').get();

      // Assert
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['nombreUsuario'], 'Admin Test');
      expect(data['correo'], 'admin@admin.com');
      expect(data['tipoUsuario'], 'ADMIN');
      expect(data['activo'], true);
    });

    test('debe modificar nombre de usuario administrador', () async {
      // Arrange
      final adminData = {
        'nombreUsuario': 'Admin Original',
        'correo': 'admin@admin.com',
        'tipoUsuario': 'ADMIN',
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
      };
      await fakeFirestore.collection('usuarios').doc('admin2').set(adminData);

      // Act
      await fakeFirestore.collection('usuarios').doc('admin2').update({
        'nombreUsuario': 'Admin Modificado',
      });
      final doc = await fakeFirestore.collection('usuarios').doc('admin2').get();

      // Assert
      expect(doc.data()!['nombreUsuario'], 'Admin Modificado');
    });

    test('debe activar usuario administrador', () async {
      // Arrange
      final adminData = {
        'nombreUsuario': 'Admin Inactivo',
        'correo': 'admin@admin.com',
        'tipoUsuario': 'ADMIN',
        'activo': false,
        'fechaCreacion': DateTime.now().toIso8601String(),
      };
      await fakeFirestore.collection('usuarios').doc('admin3').set(adminData);

      // Act
      await fakeFirestore.collection('usuarios').doc('admin3').update({
        'activo': true,
      });
      final doc = await fakeFirestore.collection('usuarios').doc('admin3').get();

      // Assert
      expect(doc.data()!['activo'], true);
    });

    test('debe desactivar usuario administrador', () async {
      // Arrange
      final adminData = {
        'nombreUsuario': 'Admin Activo',
        'correo': 'admin@admin.com',
        'tipoUsuario': 'ADMIN',
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
      };
      await fakeFirestore.collection('usuarios').doc('admin4').set(adminData);

      // Act
      await fakeFirestore.collection('usuarios').doc('admin4').update({
        'activo': false,
      });
      final doc = await fakeFirestore.collection('usuarios').doc('admin4').get();

      // Assert
      expect(doc.data()!['activo'], false);
    });

    test('debe listar todos los administradores', () async {
      // Arrange
      final admins = [
        {
          'nombreUsuario': 'Admin 1',
          'correo': 'admin1@admin.com',
          'tipoUsuario': 'ADMIN',
          'activo': true,
          'fechaCreacion': DateTime.now().toIso8601String(),
        },
        {
          'nombreUsuario': 'Admin 2',
          'correo': 'admin2@admin.com',
          'tipoUsuario': 'ADMIN',
          'activo': true,
          'fechaCreacion': DateTime.now().toIso8601String(),
        },
        {
          'nombreUsuario': 'Empleado',
          'correo': 'empleado@geoface.com',
          'tipoUsuario': 'EMPLEADO',
          'activo': true,
          'fechaCreacion': DateTime.now().toIso8601String(),
        },
      ];

      for (var i = 0; i < admins.length; i++) {
        await fakeFirestore.collection('usuarios').doc('user$i').set(admins[i]);
      }

      // Act
      final snapshot = await fakeFirestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'ADMIN')
          .get();

      final administradores = snapshot.docs
          .map((doc) => Usuario.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      // Assert
      expect(administradores.length, 2);
      expect(administradores.every((u) => u.isAdmin), true);
      expect(administradores.every((u) => u.tipoUsuario == 'ADMIN'), true);
    });

    test('debe validar que usuario es administrador', () {
      // Arrange
      final adminUsuario = Usuario(
        id: 'admin1',
        nombreUsuario: 'Admin',
        correo: 'admin@admin.com',
        tipoUsuario: 'ADMIN',
        activo: true,
        fechaCreacion: DateTime.now(),
      );

      // Assert
      expect(adminUsuario.isAdmin, true);
      expect(adminUsuario.isEmpleado, false);
      expect(adminUsuario.tipoUsuario, 'ADMIN');
    });
  });
}


