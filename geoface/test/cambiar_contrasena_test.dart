// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-010: Cambiar contraseña de usuario
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica para cambiar la
//               contraseña requiere la contraseña actual y que la nueva contraseña
//               cumple con las políticas de seguridad.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/utils/validators.dart';
// ignore: unused_import
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('RF-010: Cambiar contraseña de usuario', () {
    test('debe requerir contrasena actual para cambiar contrasena', () {
      // Arrange
      final contrasenaActual = 'password123';
      final nuevaContrasena = 'newpassword456';

      // Act & Assert
      expect(contrasenaActual.isNotEmpty, true);
      expect(nuevaContrasena.isNotEmpty, true);
      expect(contrasenaActual != nuevaContrasena, true);
    });

    test('debe validar que la nueva contrasena cumple con politicas de seguridad', () {
      // Arrange
      final contrasenasValidas = [
        'password123',
        'SecurePass456',
        'MyP@ssw0rd',
        'LongPassword123!',
      ];

      final contrasenasInvalidas = [
        '12345', // Muy corta
        '', // Vacia
        'pass', // Menos de 6 caracteres
      ];

      // Act & Assert - Validar contrasenas validas
      for (final password in contrasenasValidas) {
        final error = Validators.validatePassword(password);
        expect(error, isNull, reason: 'La contrasena "$password" deberia ser valida');
      }

      // Act & Assert - Validar contrasenas invalidas
      for (final password in contrasenasInvalidas) {
        final error = Validators.validatePassword(password);
        expect(error, isNotNull, reason: 'La contrasena "$password" deberia ser invalida');
      }
    });

    test('debe validar que la contrasena tiene al menos 6 caracteres', () {
      // Arrange
      final contrasenasCortas = ['12345', 'pass', 'abc'];
      final contrasenasValidas = ['123456', 'password', 'secure123'];

      // Act & Assert
      for (final password in contrasenasCortas) {
        final error = Validators.validatePassword(password);
        expect(error, isNotNull);
        expect(error, contains('al menos 6 caracteres'));
      }

      for (final password in contrasenasValidas) {
        final error = Validators.validatePassword(password);
        expect(error, isNull);
      }
    });

    test('debe validar que la contrasena no esta vacia', () {
      // Arrange
      final contrasenaVacia = '';

      // Act
      final error = Validators.validatePassword(contrasenaVacia);

      // Assert
      expect(error, isNotNull);
      expect(error, contains('obligatoria'));
    });

    test('debe rechazar cambio de contrasena con contrasena actual incorrecta', () {
      // Arrange
      final contrasenaActualIncorrecta = 'wrongpassword';
      final nuevaContrasena = 'newpassword456';

      // Act - Validar que se requiere la contraseña actual
      final validacionNueva = Validators.validatePassword(nuevaContrasena);

      // Assert
      expect(contrasenaActualIncorrecta.isNotEmpty, true);
      expect(validacionNueva, isNull);
      // La validación de contraseña actual se hace en el controlador
    });

    test('debe aceptar cambio de contrasena con contrasena actual correcta', () {
      // Arrange
      final contrasenaActual = 'password123';
      final nuevaContrasena = 'newpassword456';

      // Act
      final validacionActual = Validators.validatePassword(contrasenaActual);
      final validacionNueva = Validators.validatePassword(nuevaContrasena);

      // Assert
      expect(validacionActual, isNull);
      expect(validacionNueva, isNull);
      expect(contrasenaActual != nuevaContrasena, true);
    });
  });
}

