import 'package:flutter/foundation.dart';

/// Almacena las URLs de la API necesarias para la comunicación con el servidor.
///
/// Esta clase es inmutable y requiere que todas las URLs sean explícitas y válidas
/// durante su creación para garantizar una configuración robusta.
@immutable
class ApiConfig {
  /// Nombres de los campos para la serialización y deserialización.
  static const String fieldBaseUrl = 'baseUrl';
  static const String fieldIdentificationApiUrl = 'identificationApiUrl';
  static const String fieldSyncApiUrl = 'syncApiUrl';

  /// La URL base del servidor, sin endpoints. Ejemplo: `https://api.miempresa.com`
  final String baseUrl;

  /// La URL completa para el endpoint de identificación.
  final String identificationApiUrl;

  /// La URL completa para el endpoint de sincronización.
  final String syncApiUrl;

  /// Constructor principal para una instancia de [ApiConfig].
  const ApiConfig({
    required this.baseUrl,
    required this.identificationApiUrl,
    required this.syncApiUrl,
  });

  /// Construye una instancia de [ApiConfig] a partir de un mapa JSON.
  ///
  /// Lanza [FormatException] si alguna de las URLs requeridas falta, está vacía
  /// o no tiene un formato de URI válido. Este enfoque "Fail Fast" previene
  /// la creación de una configuración inválida que podría causar errores en tiempo de ejecución.
  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    final baseUrl = json[fieldBaseUrl] as String?;
    final identificationApiUrl = json[fieldIdentificationApiUrl] as String?;
    final syncApiUrl = json[fieldSyncApiUrl] as String?;

    // Validación "Fail Fast": Se verifica que las URLs no sean nulas ni vacías.
    if (baseUrl == null || baseUrl.isEmpty) {
      throw FormatException("El campo '$fieldBaseUrl' es requerido en la configuración de la API.");
    }
    if (identificationApiUrl == null || identificationApiUrl.isEmpty) {
      throw FormatException("El campo '$fieldIdentificationApiUrl' es requerido en la configuración de la API.");
    }
    if (syncApiUrl == null || syncApiUrl.isEmpty) {
      throw FormatException("El campo '$fieldSyncApiUrl' es requerido en la configuración de la API.");
    }

    // Validación adicional: Se verifica que las URLs tengan un formato válido.
    if (Uri.tryParse(baseUrl)?.hasAbsolutePath != true) {
      throw FormatException("La '$fieldBaseUrl' proporcionada no es una URL válida: '$baseUrl'");
    }

    return ApiConfig(
      baseUrl: baseUrl,
      identificationApiUrl: identificationApiUrl,
      syncApiUrl: syncApiUrl,
    );
  }

  /// Convierte la instancia a un mapa JSON, ideal para guardar en almacenamiento local.
  Map<String, dynamic> toJson() {
    return {
      fieldBaseUrl: baseUrl,
      fieldIdentificationApiUrl: identificationApiUrl,
      fieldSyncApiUrl: syncApiUrl,
    };
  }

  /// Crea una copia de esta instancia, reemplazando los campos proporcionados.
  ApiConfig copyWith({
    String? baseUrl,
    String? identificationApiUrl,
    String? syncApiUrl,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      identificationApiUrl: identificationApiUrl ?? this.identificationApiUrl,
      syncApiUrl: syncApiUrl ?? this.syncApiUrl,
    );
  }
}