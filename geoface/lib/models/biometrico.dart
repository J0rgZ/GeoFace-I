import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa los datos biométricos faciales de un empleado.
///
/// Contiene el identificador, la referencia al empleado, la ruta del dato facial
/// y las fechas de registro y actualización.
/// La clase es inmutable; las modificaciones deben hacerse a través de [copyWith].
class Biometrico {
  /// Nombres de los campos tal como existen en la colección de Firestore.
  static const String fieldId = 'id';
  static const String fieldEmpleadoId = 'empleadoId';
  static const String fieldDatoFacial = 'datoFacial';
  static const String fieldFechaRegistro = 'fechaRegistro';
  static const String fieldFechaActualizacion = 'fechaActualizacion';

  final String id;
  final String empleadoId;
  
  /// Representa la referencia al dato facial.
  /// En la práctica, puede ser una URL a Firebase Storage o una representación en base64.
  final String datoFacial;

  /// La fecha y hora en que se realizó el registro biométrico.
  /// Se almacena como [DateTime] para permitir consultas y comparaciones.
  final DateTime fechaRegistro;

  /// La fecha y hora de la última actualización. Es nulo si nunca se ha modificado.
  final DateTime? fechaActualizacion;

  /// Constructor principal para una instancia de [Biometrico].
  Biometrico({
    required this.id,
    required this.empleadoId,
    required this.datoFacial,
    required this.fechaRegistro,
    this.fechaActualizacion,
  });

  /// Construye una instancia de [Biometrico] a partir de un mapa JSON.
  ///
  /// Lanza [FormatException] si alguno de los campos requeridos (`id`,
  /// `empleadoId`, `datoFacial`, `fechaRegistro`) es nulo o inválido.
  factory Biometrico.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para parsear fechas desde Timestamp o String.
    DateTime? parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date); // Para retrocompatibilidad.
      return null;
    }

    final id = json[fieldId] as String?;
    final empleadoId = json[fieldEmpleadoId] as String?;
    final datoFacial = json[fieldDatoFacial] as String?;
    final fechaRegistro = parseDate(json[fieldFechaRegistro]);

    // Principio "Fail Fast": Se valida que los datos esenciales existan y no estén vacíos.
    if (id == null || id.isEmpty) {
      throw FormatException("El campo 'id' es nulo o vacío en los datos biométricos.");
    }
    if (empleadoId == null || empleadoId.isEmpty) {
      throw FormatException("El campo 'empleadoId' es nulo o vacío para el biométrico con ID: $id.");
    }
    if (datoFacial == null || datoFacial.isEmpty) {
      throw FormatException("El campo 'datoFacial' es nulo o vacío para el biométrico con ID: $id.");
    }
    if (fechaRegistro == null) {
      throw FormatException("El campo 'fechaRegistro' es nulo o inválido para el biométrico con ID: $id.");
    }

    return Biometrico(
      id: id,
      empleadoId: empleadoId,
      datoFacial: datoFacial,
      fechaRegistro: fechaRegistro,
      fechaActualizacion: parseDate(json[fieldFechaActualizacion]),
    );
  }

  /// Convierte la instancia a un mapa JSON para ser guardado en Firestore.
  ///
  /// Las fechas de tipo [DateTime] se convierten a [Timestamp] para compatibilidad
  /// y para permitir consultas eficientes por rango de fechas en Firestore.
  Map<String, dynamic> toJson() {
    return {
      fieldId: id,
      fieldEmpleadoId: empleadoId,
      fieldDatoFacial: datoFacial,
      fieldFechaRegistro: Timestamp.fromDate(fechaRegistro),
      fieldFechaActualizacion: fechaActualizacion != null
          ? Timestamp.fromDate(fechaActualizacion!)
          : null,
    };
  }
  
  /// Crea una copia de esta instancia, reemplazando los campos proporcionados.
  Biometrico copyWith({
    String? id,
    String? empleadoId,
    String? datoFacial,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return Biometrico(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      datoFacial: datoFacial ?? this.datoFacial,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}