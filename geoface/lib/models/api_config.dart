// -----------------------------------------------------------------------------
// @Header:      Configuración de Endpoints de API
// @Author:      Jorge Luis Briceño Diaz
// @Description: Define el modelo `ApiConfig` para gestionar las URLs de los
//              endpoints de la API, como la de identificación y sincronización.
//              Facilita la gestión centralizada de las configuraciones de la API
//              y la derivación de URLs base.
//
// @ModelName:   ApiConfig
// @Location:    lib/config/api_config.dart
// @StartDate:   15/07/2025
// @EndDate:     30/07/2025
// -----------------------------------------------------------------------------
// @Modification: [Numero de modificacion]
// @Date:        [Fecha de Modificación]
// @Author:      [Nombre de quien modificó]
// @Description: [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

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