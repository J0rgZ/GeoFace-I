/// Modelo que representa una Sede de la empresa.
class Sede {
  // Principio: "Evitemos los números mágicos".
  // Se define el 100 como una constante para que tenga un nombre claro.
  static const int kRadioPermitidoPorDefecto = 100;

  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final int radioPermitido;
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime? fechaModificacion;

  Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.radioPermitido,
    required this.activa,
    required this.fechaCreacion,
    this.fechaModificacion,
  });

  /// Construye una instancia de Sede desde un mapa JSON.
  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      id: json['id'],
      nombre: json['nombre'],
      direccion: json['direccion'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      // Usamos la constante en lugar del número directamente.
      radioPermitido: json['radioPermitido'] ?? kRadioPermitidoPorDefecto,
      activa: json['activa'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      fechaModificacion: json['fechaModificacion'] != null
          ? DateTime.parse(json['fechaModificacion'])
          : null,
    );
  }

  /// Convierte la instancia actual a un mapa para guardarlo como JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'radioPermitido': radioPermitido,
      'activa': activa,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaModificacion': fechaModificacion?.toIso8601String(),
    };
  }

  /// Crea una copia de la Sede actual con los valores que le pases.
  /// Mantiene la funcionalidad original sin cambios.
  Sede copyWith({
    String? id,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    int? radioPermitido,
    bool? activa,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Sede(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      radioPermitido: radioPermitido ?? this.radioPermitido,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      // Se mantiene la lógica original, no se afecta la funcionalidad.
      fechaModificacion: fechaModificacion ?? DateTime.now(),
    );
  }

  /// Crea una instancia de Sede "vacía" para estados iniciales.
  static Sede empty() {
    return Sede(
      id: '',
      // También se evita el "string mágico" aquí.
      nombre: 'Sede no encontrada',
      direccion: '',
      latitud: 0.0,
      longitud: 0.0,
      radioPermitido: 0,
      activa: false,
      fechaCreacion: DateTime.now(),
      fechaModificacion: null,
    );
  }
}