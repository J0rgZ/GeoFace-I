// -----------------------------------------------------------------------------
// @Encabezado:   Modelo de Información del Dispositivo
// @Autor:        Sistema GeoFace
// @Descripción:  Modelo para almacenar información del dispositivo que
//               instala la aplicación.
// -----------------------------------------------------------------------------

class DispositivoInfo {
  final String id; // ID único del dispositivo
  final String marca;
  final String modelo;
  final String? sistemaOperativo;
  final String? versionSO;
  final DateTime fechaRegistro;
  final DateTime? fechaUltimaActualizacion;

  DispositivoInfo({
    required this.id,
    required this.marca,
    required this.modelo,
    this.sistemaOperativo,
    this.versionSO,
    required this.fechaRegistro,
    this.fechaUltimaActualizacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marca': marca,
      'modelo': modelo,
      'sistemaOperativo': sistemaOperativo,
      'versionSO': versionSO,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'fechaUltimaActualizacion': fechaUltimaActualizacion?.toIso8601String(),
    };
  }

  factory DispositivoInfo.fromJson(Map<String, dynamic> json) {
    return DispositivoInfo(
      id: json['id'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      sistemaOperativo: json['sistemaOperativo'] as String?,
      versionSO: json['versionSO'] as String?,
      fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
      fechaUltimaActualizacion: json['fechaUltimaActualizacion'] != null
          ? DateTime.parse(json['fechaUltimaActualizacion'] as String)
          : null,
    );
  }

  String get nombreCompleto => '$marca $modelo';
}


