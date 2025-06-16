import 'package:cloud_firestore/cloud_firestore.dart';

class EstadisticaAsistencia {
  final String sedeId;
  final String sedeNombre; // Añadido para mostrar en la UI y reportes
  final String? empleadoId;
  final DateTime fecha;
  final int totalEmpleados;
  final int totalAsistencias;
  final int totalAusencias;
  final int totalTardanzas;
  final double porcentajeAsistencia;

  EstadisticaAsistencia({
    required this.sedeId,
    required this.sedeNombre,
    this.empleadoId,
    required this.fecha,
    required this.totalEmpleados,
    required this.totalAsistencias,
    required this.totalAusencias,
    required this.totalTardanzas,
    required this.porcentajeAsistencia,
  });

  /// Constructor factory para crear una instancia desde un mapa (JSON/Firestore).
  /// Es robusto contra valores nulos y maneja diferentes tipos de datos.
  factory EstadisticaAsistencia.fromJson(Map<String, dynamic> json) {
    // Lógica robusta para parsear la fecha, ya sea un Timestamp de Firestore o un String.
    DateTime parsedDate;
    if (json['fecha'] is Timestamp) {
      parsedDate = (json['fecha'] as Timestamp).toDate();
    } else if (json['fecha'] is String) {
      // Usamos tryParse para evitar errores si el formato del string es incorrecto.
      parsedDate = DateTime.tryParse(json['fecha']) ?? DateTime.now();
    } else {
      // Valor por defecto si el campo no existe o es de un tipo inesperado.
      parsedDate = DateTime.now();
    }

    return EstadisticaAsistencia(
      // Usamos el operador '??' para dar un valor por defecto si el campo es nulo.
      sedeId: json['sedeId'] as String? ?? '',
      sedeNombre: json['sedeNombre'] as String? ?? 'N/A', // Manejo del nuevo campo
      empleadoId: json['empleadoId'] as String?, // Este puede ser nulo, así que está bien.
      fecha: parsedDate,
      totalEmpleados: json['totalEmpleados'] as int? ?? 0,
      totalAsistencias: json['totalAsistencias'] as int? ?? 0,
      totalAusencias: json['totalAusencias'] as int? ?? 0,
      totalTardanzas: json['totalTardanzas'] as int? ?? 0,
      // Lógica para manejar tanto int como double desde el JSON.
      porcentajeAsistencia: (json['porcentajeAsistencia'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte la instancia a un mapa, ideal para escribir en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'sedeId': sedeId,
      'sedeNombre': sedeNombre,
      'empleadoId': empleadoId,
      // Se guarda como Timestamp para facilitar las consultas en Firestore.
      'fecha': Timestamp.fromDate(fecha),
      'totalEmpleados': totalEmpleados,
      'totalAsistencias': totalAsistencias,
      'totalAusencias': totalAusencias,
      'totalTardanzas': totalTardanzas,
      'porcentajeAsistencia': porcentajeAsistencia,
    };
  }
}