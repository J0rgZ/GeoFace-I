// -----------------------------------------------------------------------------
// @Encabezado:   Gestión de Registros de Asistencia
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Define el modelo `Asistencia` para representar un registro
//               de entrada y salida de un empleado. Incluye información sobre
//               la hora, geolocalización y capturas faciales. El modelo es
//               inmutable y maneja la serialización y deserialización para
//               su uso con Firestore.
//
// @NombreModelo: Asistencia
// @Ubicacion:    lib/models/asistencia.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

// Representa un único registro de asistencia para un empleado.
//
// Esta clase es inmutable. Para generar una versión modificada del objeto,
// se debe utilizar el método [copyWith].
class Asistencia {
  // Nombres de los campos tal como existen en la colección de Firestore.
  // Su uso previene errores de tipeo y centraliza la definición de los campos.
  static const String campoId = 'id';
  static const String campoEmpleadoId = 'empleadoId';
  static const String campoSedeId = 'sedeId';
  static const String campoFechaHoraEntrada = 'fechaHoraEntrada';
  static const String campoFechaHoraSalida = 'fechaHoraSalida';
  static const String campoLatitudEntrada = 'latitudEntrada';
  static const String campoLongitudEntrada = 'longitudEntrada';
  static const String campoLatitudSalida = 'latitudSalida';
  static const String campoLongitudSalida = 'longitudSalida';
  static const String campoCapturaEntrada = 'capturaEntrada';
  static const String campoCapturaSalida = 'capturaSalida';

  final String id;
  final String empleadoId;
  final String sedeId;
  final DateTime fechaHoraEntrada;

  // La hora de salida del empleado. Es nulo si el turno de trabajo aún está activo.
  final DateTime? fechaHoraSalida;

  final double latitudEntrada;
  final double longitudEntrada;
  final double? latitudSalida;
  final double? longitudSalida;

  // URL de la imagen de captura facial al momento de la entrada.
  final String? capturaEntrada;

  // URL de la imagen de captura facial al momento de la salida.
  final String? capturaSalida;

  // Constructor principal para una instancia de [Asistencia].
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

  // Determina si el registro de asistencia está completo (incluye entrada y salida).
  bool get registroCompleto => fechaHoraSalida != null;

  // Calcula la duración total del tiempo trabajado.
  // Si el turno no ha finalizado, calcula la duración hasta el momento actual.
  Duration get tiempoTrabajado => fechaHoraSalida != null
      ? fechaHoraSalida!.difference(fechaHoraEntrada)
      : DateTime.now().difference(fechaHoraEntrada);

  // Construye una instancia de [Asistencia] a partir de un mapa JSON.
  factory Asistencia.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para interpretar objetos de fecha de forma segura.
    DateTime? analizarFecha(dynamic fecha) {
      if (fecha is Timestamp) return fecha.toDate();
      if (fecha is String) return DateTime.tryParse(fecha); // Para retrocompatibilidad.
      return null;
    }

    final fechaEntrada = analizarFecha(json[campoFechaHoraEntrada]);

    // Principio de "fallo rápido": se detiene la creación si los datos críticos son inválidos.
    if (fechaEntrada == null) {
      throw FormatException(
          "El campo 'fechaHoraEntrada' es inválido en el documento con ID: ${json[campoId]}");
    }

    return Asistencia(
      id: json[campoId] ?? '',
      empleadoId: json[campoEmpleadoId] ?? '',
      sedeId: json[campoSedeId] ?? '',
      fechaHoraEntrada: fechaEntrada,
      fechaHoraSalida: analizarFecha(json[campoFechaHoraSalida]),
      // Conversión segura para datos numéricos. Previene fallos si el campo no existe.
      latitudEntrada: (json[campoLatitudEntrada] as num?)?.toDouble() ?? 0.0,
      longitudEntrada: (json[campoLongitudEntrada] as num?)?.toDouble() ?? 0.0,
      latitudSalida: (json[campoLatitudSalida] as num?)?.toDouble(),
      longitudSalida: (json[campoLongitudSalida] as num?)?.toDouble(),
      capturaEntrada: json[campoCapturaEntrada],
      capturaSalida: json[campoCapturaSalida],
    );
  }
  
  // Convierte la instancia de [Asistencia] a un mapa JSON para ser guardado.
  Map<String, dynamic> toJson() {
    return {
      campoId: id,
      campoEmpleadoId: empleadoId,
      campoSedeId: sedeId,
      campoLatitudEntrada: latitudEntrada,
      campoLongitudEntrada: longitudEntrada,
      campoLatitudSalida: latitudSalida,
      campoLongitudSalida: longitudSalida,
      campoCapturaEntrada: capturaEntrada,
      campoCapturaSalida: capturaSalida,
    };
  }

  // Crea una copia de esta instancia, reemplazando los campos proporcionados con nuevos valores.
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