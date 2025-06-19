// lib/models/api_config.dart

class ApiConfig {
  final String faceRecognitionApiUrl;

  ApiConfig({required this.faceRecognitionApiUrl});

  /// Factory para crear una instancia desde un mapa (como el de Firestore)
  factory ApiConfig.fromMap(Map<String, dynamic> map) {
    return ApiConfig(
      faceRecognitionApiUrl: map['faceRecognitionApiUrl'] as String? ?? '',
    );
  }

  /// Método para convertir la instancia a un mapa (para guardarlo en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'faceRecognitionApiUrl': faceRecognitionApiUrl,
    };
  }

  /// Un objeto vacío para estados iniciales o de error
  static ApiConfig get empty => ApiConfig(faceRecognitionApiUrl: '');
}