class ApiConfig {
  final String identificationApiUrl;
  final String syncApiUrl;

  ApiConfig({
    required this.identificationApiUrl,
    required this.syncApiUrl,
  });

  /// Deriva la URL base (sin /endpoint) desde la URL de identificación.
  String get baseUrl {
    if (identificationApiUrl.endsWith('/identificar')) {
      return identificationApiUrl.substring(0, identificationApiUrl.length - '/identificar'.length);
    }
    if (syncApiUrl.endsWith('/sync-database')) {
       return syncApiUrl.substring(0, syncApiUrl.length - '/sync-database'.length);
    }
    // Si no tiene el formato esperado, devolvemos la de identificación como fallback.
    return identificationApiUrl;
  }

  factory ApiConfig.fromMap(Map<String, dynamic> map) {
    return ApiConfig(
      identificationApiUrl: map['identificationApiUrl'] as String? ?? '',
      syncApiUrl: map['syncApiUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identificationApiUrl': identificationApiUrl,
      'syncApiUrl': syncApiUrl,
    };
  }

  static ApiConfig get empty => ApiConfig(identificationApiUrl: '', syncApiUrl: '');
}