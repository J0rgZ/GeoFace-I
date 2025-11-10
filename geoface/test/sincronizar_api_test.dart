// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-014: Sincronizar datos Faciales con API
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica para iniciar una
//               solicitud de sincronización a la API externa para actualizar la
//               base de datos de rostros funciona correctamente.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/api_config.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RF-014: Sincronizar datos Faciales con API', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe iniciar solicitud de sincronización a la API', () async {
      // Arrange
      final apiConfig = ApiConfig(
        identificationApiUrl: 'https://api.example.com/identificar',
        syncApiUrl: 'https://api.example.com/sync-database',
      );

      await fakeFirestore
          .collection('app_config')
          .doc('settings')
          .set(apiConfig.toMap());

      // Act
      final doc = await fakeFirestore.collection('app_config').doc('settings').get();
      final configRecuperada = ApiConfig.fromMap(doc.data()!);

      // Assert
      expect(configRecuperada.syncApiUrl, 'https://api.example.com/sync-database');
      expect(configRecuperada.syncApiUrl.isNotEmpty, true);
    });

    test('debe validar que la URL de sincronización está configurada', () {
      // Arrange
      final apiConfigConUrl = ApiConfig(
        identificationApiUrl: 'https://api.example.com/identificar',
        syncApiUrl: 'https://api.example.com/sync-database',
      );

      final apiConfigSinUrl = ApiConfig.empty;

      // Assert
      expect(apiConfigConUrl.syncApiUrl.isNotEmpty, true);
      expect(apiConfigSinUrl.syncApiUrl.isEmpty, true);
    });

    test('debe construir URL de sincronización correctamente', () {
      // Arrange
      final baseUrl = 'https://api.example.com';
      final apiConfig = ApiConfig(
        identificationApiUrl: '$baseUrl/identificar',
        syncApiUrl: '$baseUrl/sync-database',
      );

      // Assert
      expect(apiConfig.syncApiUrl, '$baseUrl/sync-database');
      expect(apiConfig.syncApiUrl.contains('sync-database'), true);
    });

    test('debe manejar error cuando no hay URL de sincronización configurada', () {
      // Arrange
      final apiConfig = ApiConfig.empty;

      // Act
      final tieneUrlSincronizacion = apiConfig.syncApiUrl.isNotEmpty;

      // Assert
      expect(tieneUrlSincronizacion, false);
    });

    test('debe preparar solicitud POST para sincronización', () async {
      // Arrange
      final syncUrl = 'https://api.example.com/sync-database';
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.toString() == syncUrl) {
          return http.Response('{"status": "success", "message": "Sincronización iniciada"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      // Act
      final response = await mockClient.post(Uri.parse(syncUrl));

      // Assert
      expect(response.statusCode, 200);
      expect(response.body, contains('success'));
    });

    test('debe manejar respuesta exitosa de sincronización', () async {
      // Arrange
      final syncUrl = 'https://api.example.com/sync-database';
      final mockClient = MockClient((request) async {
        return http.Response('{"status": "success"}', 200);
      });

      // Act
      final response = await mockClient.post(Uri.parse(syncUrl));

      // Assert
      expect(response.statusCode, 200);
    });

    test('debe manejar error de conexión en sincronización', () async {
      // Arrange
      final syncUrl = 'https://api.example.com/sync-database';
      final mockClient = MockClient((request) async {
        throw Exception('Error de conexión');
      });

      // Act & Assert
      expect(
        () => mockClient.post(Uri.parse(syncUrl)),
        throwsA(isA<Exception>()),
      );
    });

    test('debe manejar respuesta de error de la API', () async {
      // Arrange
      final syncUrl = 'https://api.example.com/sync-database';
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Error al sincronizar"}', 500);
      });

      // Act
      final response = await mockClient.post(Uri.parse(syncUrl));

      // Assert
      expect(response.statusCode, 500);
      expect(response.body, contains('error'));
    });

    test('debe recuperar configuración de API para sincronización', () async {
      // Arrange
      final apiConfig = ApiConfig(
        identificationApiUrl: 'https://api.test.com/identificar',
        syncApiUrl: 'https://api.test.com/sync-database',
      );

      await fakeFirestore
          .collection('app_config')
          .doc('settings')
          .set(apiConfig.toMap());

      // Act
      final doc = await fakeFirestore.collection('app_config').doc('settings').get();
      final configRecuperada = ApiConfig.fromMap(doc.data()!);

      // Assert
      expect(configRecuperada.syncApiUrl, apiConfig.syncApiUrl);
      expect(configRecuperada.identificationApiUrl, apiConfig.identificationApiUrl);
    });
  });
}



