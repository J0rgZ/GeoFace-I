// models/sede.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una Sede o sucursal de la empresa.
///
/// Esta clase es inmutable. Para generar una versión modificada del objeto,
/// se debe utilizar el método [copyWith].
class Sede {
  /// Nombres de los campos tal como existen en la colección de Firestore.
  static const String fieldId = 'id';
  static const String fieldNombre = 'nombre';
  static const String fieldDireccion = 'direccion';
  static const String fieldLatitud = 'latitud';
  static const String fieldLongitud = 'longitud';
  static const String fieldRadioPermitido = 'radioPermitido';
  static const String fieldActiva = 'activa';
  static const String fieldFechaCreacion = 'fechaCreacion';
  static const String fieldFechaModificacion = 'fechaModificacion';

  /// Valor por defecto para el radio permitido si no se especifica.
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

  /// Constructor principal para una instancia de [Sede].
  Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    this.radioPermitido = kRadioPermitidoPorDefecto,
    required this.activa,
    required this.fechaCreacion,
    this.fechaModificacion,
  });

  /// Construye una instancia de [Sede] a partir de un mapa JSON.
  ///
  /// Lanza [FormatException] si los campos críticos (`id`, `nombre`, `fechaCreacion`, etc.)
  /// son nulos, vacíos o tienen un formato inválido.
  factory Sede.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para parsear fechas de forma segura.
    DateTime? parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date); // Retrocompatibilidad
      return null;
    }

    final id = json[fieldId] as String?;
    final nombre = json[fieldNombre] as String?;
    final fechaCreacion = parseDate(json[fieldFechaCreacion]);

    // Principio "Fail Fast": Validación de datos críticos.
    if (id == null || id.isEmpty) {
      throw FormatException("El campo 'id' es nulo o vacío en los datos de la sede.");
    }
    if (nombre == null || nombre.isEmpty) {
      throw FormatException("El campo 'nombre' es nulo o vacío para la sede con ID: $id.");
    }
    if (fechaCreacion == null) {
      throw FormatException("El campo 'fechaCreacion' es nulo o inválido para la sede con ID: $id.");
    }

    return Sede(
      id: id,
      nombre: nombre,
      direccion: json[fieldDireccion] as String? ?? 'Dirección no especificada',
      // Casting seguro para los datos numéricos.
      latitud: (json[fieldLatitud] as num?)?.toDouble() ?? 0.0,
      longitud: (json[fieldLongitud] as num?)?.toDouble() ?? 0.0,
      radioPermitido: json[fieldRadioPermitido] as int? ?? kRadioPermitidoPorDefecto,
      activa: json[fieldActiva] as bool? ?? false,
      fechaCreacion: fechaCreacion,
      fechaModificacion: parseDate(json[fieldFechaModificacion]),
    );
  }

  /// Convierte la instancia a un mapa JSON para ser guardado en Firestore.
  ///
  /// Las fechas se convierten a `Timestamp` para un manejo óptimo en Firestore.
  Map<String, dynamic> toJson() {
    return {
      fieldId: id,
      fieldNombre: nombre,
      fieldDireccion: direccion,
      fieldLatitud: latitud,
      fieldLongitud: longitud,
      fieldRadioPermitido: radioPermitido,
      fieldActiva: activa,
      fieldFechaCreacion: Timestamp.fromDate(fechaCreacion),
      fieldFechaModificacion: fechaModificacion != null
          ? Timestamp.fromDate(fechaModificacion!)
          : null,
    };
  }

  /// Crea una copia de esta instancia, reemplazando los campos proporcionados.
  Sede copyWith({
    String? id,
    String? nombre,
    String? direccion,
    double? latitud,
    double? longitud,
    int? radioPermitido,
    bool? activa,
    DateTime? fechaCreacion,
    // Se corrige para permitir que el valor sea nulo
    DateTime? fechaModificacion,
    bool setFechaModificacionToNull = false,
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
      // Lógica mejorada para permitir actualizar a nulo
      fechaModificacion: setFechaModificacionToNull 
          ? null 
          : fechaModificacion ?? this.fechaModificacion,
    );
  }
}