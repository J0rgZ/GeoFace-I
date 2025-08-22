import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un único registro de asistencia para un empleado.
///
/// Esta clase es inmutable. Para generar una versión modificada del objeto,
/// se debe utilizar el método [copyWith].
class Asistencia {
  /// Nombres de los campos tal como existen en la colección de Firestore.
  /// Su uso previene errores de tipeo y centraliza la definición de los campos.
  static const String fieldId = 'id';
  static const String fieldEmpleadoId = 'empleadoId';
  static const String fieldSedeId = 'sedeId';
  static const String fieldFechaHoraEntrada = 'fechaHoraEntrada';
  static const String fieldFechaHoraSalida = 'fechaHoraSalida';
  static const String fieldLatitudEntrada = 'latitudEntrada';
  static const String fieldLongitudEntrada = 'longitudEntrada';
  static const String fieldLatitudSalida = 'latitudSalida';
  static const String fieldLongitudSalida = 'longitudSalida';
  static const String fieldCapturaEntrada = 'capturaEntrada';
  static const String fieldCapturaSalida = 'capturaSalida';

  final String id;
  final String empleadoId;
  final String sedeId;
  final DateTime fechaHoraEntrada;

  /// La hora de salida del empleado. Es nulo si el turno de trabajo aún está activo.
  final DateTime? fechaHoraSalida;

  final double latitudEntrada;
  final double longitudEntrada;
  final double? latitudSalida;
  final double? longitudSalida;

  /// URL de la imagen de captura facial al momento de la entrada.
  final String? capturaEntrada;

  /// URL de la imagen de captura facial al momento de la salida.
  final String? capturaSalida;

  /// Constructor principal para una instancia de [Asistencia].
  Asistencia({
    required this.id,
    required this.empleadoId,
    required this.sedeId,
    required this.fechaHoraEntrada,
    this.fechaHoraSalida,
    required this.latitudEntrada,
    required this.longitudEntrada,
    this.latitudSalida,
    this.longitudSalida,
    this.capturaEntrada,
    this.capturaSalida,
  });

  /// Determina si el registro de asistencia está completo (incluye entrada y salida).
  bool get registroCompleto => fechaHoraSalida != null;

  /// Calcula la duración total del tiempo trabajado.
  /// Si el turno no ha finalizado, calcula la duración hasta el momento actual.
  Duration get tiempoTrabajado => fechaHoraSalida != null
      ? fechaHoraSalida!.difference(fechaHoraEntrada)
      : DateTime.now().difference(fechaHoraEntrada);


  factory Asistencia.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para parsear objetos de fecha de forma segura.
    DateTime? parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date); // Para retrocompatibilidad.
      return null;
    }

    final fechaEntrada = parseDate(json[fieldFechaHoraEntrada]);

    // Principio "Fail Fast": Se detiene la creación si los datos críticos son inválidos.
    if (fechaEntrada == null) {
      throw FormatException(
          "El campo 'fechaHoraEntrada' es inválido en el documento con ID: ${json[fieldId]}");
    }

    return Asistencia(
      id: json[fieldId] ?? '',
      empleadoId: json[fieldEmpleadoId] ?? '',
      sedeId: json[fieldSedeId] ?? '',
      fechaHoraEntrada: fechaEntrada,
      fechaHoraSalida: parseDate(json[fieldFechaHoraSalida]),
      // Casting seguro para datos numéricos. Previene fallos si el campo no existe.
      latitudEntrada: (json[fieldLatitudEntrada] as num?)?.toDouble() ?? 0.0,
      longitudEntrada: (json[fieldLongitudEntrada] as num?)?.toDouble() ?? 0.0,
      latitudSalida: (json[fieldLatitudSalida] as num?)?.toDouble(),
      longitudSalida: (json[fieldLongitudSalida] as num?)?.toDouble(),
      capturaEntrada: json[fieldCapturaEntrada],
      capturaSalida: json[fieldCapturaSalida],
    );
  }

  /// Factory para retrocompatibilidad. Delega a [Asistencia.fromJson].
  factory Asistencia.fromMap(Map<String, dynamic> map) {
    return Asistencia.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      fieldId: id,
      fieldEmpleadoId: empleadoId,
      fieldSedeId: sedeId,
      fieldLatitudEntrada: latitudEntrada,
      fieldLongitudEntrada: longitudEntrada,
      fieldLatitudSalida: latitudSalida,
      fieldLongitudSalida: longitudSalida,
      fieldCapturaEntrada: capturaEntrada,
      fieldCapturaSalida: capturaSalida,
    };
  }

  /// Crea una copia de esta instancia, reemplazando los campos proporcionados.
  Asistencia copyWith({
    String? id,
    String? empleadoId,
    String? sedeId,
    DateTime? fechaHoraEntrada,
    DateTime? fechaHoraSalida,
    double? latitudEntrada,
    double? longitudEntrada,
    double? latitudSalida,
    double? longitudSalida,
    String? capturaEntrada,
    String? capturaSalida,
  }) {
    return Asistencia(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      sedeId: sedeId ?? this.sedeId,
      fechaHoraEntrada: fechaHoraEntrada ?? this.fechaHoraEntrada,
      fechaHoraSalida: fechaHoraSalida ?? this.fechaHoraSalida,
      latitudEntrada: latitudEntrada ?? this.latitudEntrada,
      longitudEntrada: longitudEntrada ?? this.longitudEntrada,
      latitudSalida: latitudSalida ?? this.latitudSalida,
      longitudSalida: longitudSalida ?? this.longitudSalida,
      capturaEntrada: capturaEntrada ?? this.capturaEntrada,
      capturaSalida: capturaSalida ?? this.capturaSalida,
    );
  }
}