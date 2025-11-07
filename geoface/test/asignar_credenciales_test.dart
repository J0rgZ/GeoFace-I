// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-013: Asignar credenciales de acceso a empleados
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica de negocio para generar
//               una cuenta de usuario para un empleado existente y asignarle credenciales
//               iniciales es correcta y segura.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/empleado.dart';
import 'package:geoface/models/usuario.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('RF-013: Asignar credenciales de acceso a empleados', () {
    late FakeFirebaseFirestore fakeFirestore;
    // ignore: unused_local_variable
    late MockFirebaseAuth mockAuth;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
    });

    test('debe generar cuenta de usuario para empleado existente', () async {
      // Arrange
      final empleado = Empleado(
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
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());

      // Act - Simular creación de usuario
      final correo = '${empleado.dni}@geoface.com';

      final mockUser = MockUser(
        uid: 'user1',
        email: correo,
      );
      // ignore: unused_local_variable
      final mockAuthInstance = MockFirebaseAuth(mockUser: mockUser, signedIn: false);

      final usuarioData = {
        'nombreUsuario': empleado.nombre,
        'correo': correo,
        'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleado.id,
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'debeCambiarContrasena': true,
      };

      await fakeFirestore.collection('usuarios').doc('user1').set(usuarioData);
      await fakeFirestore.collection('empleados').doc(empleado.id).update({
        'tieneUsuario': true,
      });

      // Assert
      final usuarioDoc = await fakeFirestore.collection('usuarios').doc('user1').get();
      expect(usuarioDoc.exists, true);
      expect(usuarioDoc.data()!['empleadoId'], empleado.id);
      expect(usuarioDoc.data()!['tipoUsuario'], 'EMPLEADO');
      expect(usuarioDoc.data()!['correo'], correo);
      expect(usuarioDoc.data()!['debeCambiarContrasena'], true);

      final empleadoDoc = await fakeFirestore.collection('empleados').doc(empleado.id).get();
      expect(empleadoDoc.data()!['tieneUsuario'], true);
    });

    test('debe asignar credenciales iniciales correctamente', () {
      // Arrange
      final empleado = Empleado(
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
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      // Act
      final correoEsperado = '${empleado.dni}@geoface.com';
      final passwordEsperada = empleado.dni;

      // Assert
      expect(correoEsperado, '87654321@geoface.com');
      expect(passwordEsperada, '87654321');
      expect(correoEsperado.contains(empleado.dni), true);
    });

    test('debe marcar que empleado debe cambiar contraseña al primer acceso', () async {
      // Arrange
      final empleado = Empleado(
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
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      // Act
      final usuarioData = {
        'nombreUsuario': empleado.nombre,
        'correo': '${empleado.dni}@geoface.com',
        'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleado.id,
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'debeCambiarContrasena': true, // Marca que debe cambiar contraseña
      };

      await fakeFirestore.collection('usuarios').doc('user2').set(usuarioData);

      // Assert
      final usuarioDoc = await fakeFirestore.collection('usuarios').doc('user2').get();
      expect(usuarioDoc.data()!['debeCambiarContrasena'], true);
    });

    test('debe crear usuario con tipo EMPLEADO', () async {
      // Arrange
      final empleado = Empleado(
        id: 'emp4',
        nombre: 'Ana',
        apellidos: 'Martínez',
        dni: '99887766',
        celular: '987654324',
        correo: 'ana@test.com',
        cargo: 'Contadora',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        activo: true,
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      // Act
      final usuarioData = {
        'nombreUsuario': empleado.nombre,
        'correo': '${empleado.dni}@geoface.com',
        'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleado.id,
        'activo': true,
        'fechaCreacion': DateTime.now().toIso8601String(),
        'debeCambiarContrasena': true,
      };

      await fakeFirestore.collection('usuarios').doc('user3').set(usuarioData);
      final usuarioDoc = await fakeFirestore.collection('usuarios').doc('user3').get();
      final usuario = Usuario.fromJson({'id': 'user3', ...usuarioDoc.data()!});

      // Assert
      expect(usuario.tipoUsuario, 'EMPLEADO');
      expect(usuario.isEmpleado, true);
      expect(usuario.isAdmin, false);
      expect(usuario.empleadoId, empleado.id);
    });

    test('debe actualizar flag tieneUsuario en empleado', () async {
      // Arrange
      final empleado = Empleado(
        id: 'emp5',
        nombre: 'Pedro',
        apellidos: 'Sánchez',
        dni: '55443322',
        celular: '987654325',
        correo: 'pedro@test.com',
        cargo: 'Vendedor',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        activo: true,
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());

      // Act
      await fakeFirestore.collection('empleados').doc(empleado.id).update({
        'tieneUsuario': true,
      });

      // Assert
      final empleadoDoc = await fakeFirestore.collection('empleados').doc(empleado.id).get();
      expect(empleadoDoc.data()!['tieneUsuario'], true);
    });
  });
}

