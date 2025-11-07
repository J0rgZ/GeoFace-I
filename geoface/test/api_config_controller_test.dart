// -----------------------------------------------------------------------------
// @Encabezado:   Pruebas Unitarias - RF-005: Configurar URLs de API
// @Autor:        Sistema Automatizado
// @Descripción:  Pruebas unitarias para validar que la lógica de persistencia y
//               recuperación de las URLs base de la API externa se realiza correctamente.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:geoface/models/api_config.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('RF-005: Configurar URLs de API', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('debe guardar configuración de API correctamente', () async {
      // Arrange
      final apiConfig = ApiConfig(
        identificationApiUrl: 'https://api.example.com/identificar',
        syncApiUrl: 'https://api.example.com/sync-database',
      );

      // Act
      await fakeFirestore
          .collection('app_config')
          .doc('settings')
          .set(apiConfig.toMap());

      final doc = await fakeFirestore.collection('app_config').doc('settings').get();

      // Assert
      expect(doc.exists, true);
      final data = doc.data()!;
      expect(data['identificationApiUrl'], 'https://api.example.com/identificar');
      expect(data['syncApiUrl'], 'https://api.example.com/sync-database');
    });

    test('debe recuperar configuración de API correctamente', () async {
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
      expect(configRecuperada.identificationApiUrl, 'https://api.test.com/identificar');
      expect(configRecuperada.syncApiUrl, 'https://api.test.com/sync-database');
    });

    test('debe actualizar configuración de API correctamente', () async {
      // Arrange
      final apiConfigInicial = ApiConfig(
        identificationApiUrl: 'https://api.old.com/identificar',
        syncApiUrl: 'https://api.old.com/sync-database',
      );
      await fakeFirestore
          .collection('app_config')
          .doc('settings')
          .set(apiConfigInicial.toMap());

      // Act
      final apiConfigNueva = ApiConfig(
        identificationApiUrl: 'https://api.new.com/identificar',
        syncApiUrl: 'https://api.new.com/sync-database',
      );
      await fakeFirestore
          .collection('app_config')
          .doc('settings')
          .update(apiConfigNueva.toMap());

      // Assert
      final doc = await fakeFirestore.collection('app_config').doc('settings').get();
      final configActualizada = ApiConfig.fromMap(doc.data()!);
      expect(configActualizada.identificationApiUrl, 'https://api.new.com/identificar');
      expect(configActualizada.syncApiUrl, 'https://api.new.com/sync-database');
    });

    test('debe derivar URL base correctamente desde identificationApiUrl', () {
      // Arrange
      final apiConfig = ApiConfig(
        identificationApiUrl: 'https://api.example.com/identificar',
        syncApiUrl: 'https://api.example.com/sync-database',
      );

      // Act
      final baseUrl = apiConfig.baseUrl;

      // Assert
      expect(baseUrl, 'https://api.example.com');
    });

    test('debe derivar URL base correctamente desde syncApiUrl si identificationApiUrl no termina correctamente', () {
      // Arrange
      final apiConfig = ApiConfig(
        identificationApiUrl: 'https://api.example.com',
        syncApiUrl: 'https://api.example.com/sync-database',
      );

      // Act
      final baseUrl = apiConfig.baseUrl;

      // Assert
      expect(baseUrl, contains('api.example.com'));
    });

    test('debe manejar configuración vacía correctamente', () {
      // Arrange
      final emptyConfig = ApiConfig.empty;

      // Assert
      expect(emptyConfig.identificationApiUrl, '');
      expect(emptyConfig.syncApiUrl, '');
    });

    test('debe convertir desde y hacia Map correctamente', () {
      // Arrange
      final apiConfig = ApiConfig(
        identificationApiUrl: 'https://api.test.com/identificar',
        syncApiUrl: 'https://api.test.com/sync-database',
      );

      // Act
      final map = apiConfig.toMap();
      final configFromMap = ApiConfig.fromMap(map);

      // Assert
      expect(configFromMap.identificationApiUrl, apiConfig.identificationApiUrl);
      expect(configFromMap.syncApiUrl, apiConfig.syncApiUrl);
    });
  });
}


