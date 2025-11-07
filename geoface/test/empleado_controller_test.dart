// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-003: Gestión de Empleados
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que los métodos de creación y
//               asignación de empleados a una sede existente funcionan correctamente
//               a nivel de lógica de negocio y persistencia.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/empleado.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('RF-003: Gestión de Empleados', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe crear un empleado correctamente', () async {
      // Arrange
      final empleado = Empleado(
        id: 'emp1',
        nombre: 'Juan',
        apellidos: 'Pérez',
        dni: '12345678',
        celular: '987654321',
        correo: 'juan.perez@test.com',
        cargo: 'Desarrollador',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        activo: true,
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      // Act
      await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());
      final doc = await fakeFirestore.collection('empleados').doc(empleado.id).get();

      // Assert
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['nombre'], 'Juan');
      expect(data['apellidos'], 'Pérez');
      expect(data['dni'], '12345678');
      expect(data['celular'], '987654321');
      expect(data['correo'], 'juan.perez@test.com');
      expect(data['cargo'], 'Desarrollador');
      expect(data['sedeId'], 'sede1');
      expect(data['activo'], true);
    });

    test('debe asignar un empleado a una sede existente', () async {
      // Arrange
      final sedeId = 'sede1';
      final empleado = Empleado(
        id: 'emp2',
        nombre: 'María',
        apellidos: 'García',
        dni: '87654321',
        celular: '987654322',
        correo: 'maria.garcia@test.com',
        cargo: 'Analista',
        sedeId: sedeId,
        fechaCreacion: DateTime.now(),
        activo: true,
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      // Act
      await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());
      final doc = await fakeFirestore.collection('empleados').doc(empleado.id).get();
      final empleadoRecuperado = Empleado.fromJson({'id': doc.id, ...doc.data()!});

      // Assert
      expect(empleadoRecuperado.sedeId, sedeId);
    });

    test('debe actualizar los datos de un empleado correctamente', () async {
      // Arrange
      final empleado = Empleado(
        id: 'emp3',
        nombre: 'Carlos',
        apellidos: 'López',
        dni: '11223344',
        celular: '987654323',
        correo: 'carlos.lopez@test.com',
        cargo: 'Gerente',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        activo: true,
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );
      await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());

      // Act
      final empleadoActualizado = empleado.copyWith(
        nombre: 'Carlos Actualizado',
        cargo: 'Director',
        activo: false,
      );
      await fakeFirestore.collection('empleados').doc(empleado.id).update(empleadoActualizado.toJson());
      final doc = await fakeFirestore.collection('empleados').doc(empleado.id).get();
      final empleadoRecuperado = Empleado.fromJson({'id': doc.id, ...doc.data()!});

      // Assert
      expect(empleadoRecuperado.nombre, 'Carlos Actualizado');
      expect(empleadoRecuperado.cargo, 'Director');
      expect(empleadoRecuperado.activo, false);
    });

    test('debe recuperar un empleado por ID correctamente', () async {
      // Arrange
      final empleado = Empleado(
        id: 'emp4',
        nombre: 'Ana',
        apellidos: 'Martínez',
        dni: '99887766',
        celular: '987654324',
        correo: 'ana.martinez@test.com',
        cargo: 'Contadora',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        activo: true,
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );
      await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());

      // Act
      final doc = await fakeFirestore.collection('empleados').doc(empleado.id).get();
      final empleadoRecuperado = Empleado.fromJson({'id': doc.id, ...doc.data()!});

      // Assert
      expect(empleadoRecuperado.id, 'emp4');
      expect(empleadoRecuperado.nombre, 'Ana');
      expect(empleadoRecuperado.apellidos, 'Martínez');
      expect(empleadoRecuperado.dni, '99887766');
    });

    test('debe listar todos los empleados correctamente', () async {
      // Arrange
      final empleados = [
        Empleado(
          id: 'emp5',
          nombre: 'Pedro',
          apellidos: 'Sánchez',
          dni: '55443322',
          celular: '987654325',
          correo: 'pedro.sanchez@test.com',
          cargo: 'Vendedor',
          sedeId: 'sede1',
          fechaCreacion: DateTime.now(),
          activo: true,
          hayDatosBiometricos: false,
          tieneUsuario: false,
        ),
        Empleado(
          id: 'emp6',
          nombre: 'Laura',
          apellidos: 'Rodríguez',
          dni: '44332211',
          celular: '987654326',
          correo: 'laura.rodriguez@test.com',
          cargo: 'Secretaria',
          sedeId: 'sede1',
          fechaCreacion: DateTime.now(),
          activo: true,
          hayDatosBiometricos: false,
          tieneUsuario: false,
        ),
      ];

      for (final empleado in empleados) {
        await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());
      }

      // Act
      final snapshot = await fakeFirestore.collection('empleados').get();
      final empleadosRecuperados = snapshot.docs
          .map((doc) => Empleado.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      // Assert
      expect(empleadosRecuperados.length, 2);
      expect(empleadosRecuperados.any((e) => e.nombre == 'Pedro'), true);
      expect(empleadosRecuperados.any((e) => e.nombre == 'Laura'), true);
    });

    test('debe filtrar empleados por sede correctamente', () async {
      // Arrange
      final empleados = [
        Empleado(
          id: 'emp7',
          nombre: 'Roberto',
          apellidos: 'Fernández',
          dni: '33221100',
          celular: '987654327',
          correo: 'roberto.fernandez@test.com',
          cargo: 'Ingeniero',
          sedeId: 'sede1',
          fechaCreacion: DateTime.now(),
          activo: true,
          hayDatosBiometricos: false,
          tieneUsuario: false,
        ),
        Empleado(
          id: 'emp8',
          nombre: 'Sofía',
          apellidos: 'Morales',
          dni: '22110099',
          celular: '987654328',
          correo: 'sofia.morales@test.com',
          cargo: 'Diseñadora',
          sedeId: 'sede2',
          fechaCreacion: DateTime.now(),
          activo: true,
          hayDatosBiometricos: false,
          tieneUsuario: false,
        ),
      ];

      for (final empleado in empleados) {
        await fakeFirestore.collection('empleados').doc(empleado.id).set(empleado.toJson());
      }

      // Act
      final snapshot = await fakeFirestore
          .collection('empleados')
          .where('sedeId', isEqualTo: 'sede1')
          .get();
      final empleadosSede1 = snapshot.docs
          .map((doc) => Empleado.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      // Assert
      expect(empleadosSede1.length, 1);
      expect(empleadosSede1.first.sedeId, 'sede1');
      expect(empleadosSede1.first.nombre, 'Roberto');
    });

    test('debe calcular el nombre completo correctamente', () {
      // Arrange
      final empleado = Empleado(
        id: 'emp9',
        nombre: 'Luis',
        apellidos: 'Vargas',
        dni: '11009988',
        celular: '987654329',
        correo: 'luis.vargas@test.com',
        cargo: 'Asistente',
        sedeId: 'sede1',
        fechaCreacion: DateTime.now(),
        activo: true,
        hayDatosBiometricos: false,
        tieneUsuario: false,
      );

      // Assert
      expect(empleado.nombreCompleto, 'Luis Vargas');
    });
  });
}


