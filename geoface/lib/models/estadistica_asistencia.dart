import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un resumen estadístico de la asistencia para una sede y fecha específicas.
///
/// La estadística puede ser a nivel de toda la sede o para un empleado individual
/// si el campo [empleadoId] está presente.
/// Esta clase es inmutable. Para modificaciones, utilice [copyWith].
class EstadisticaAsistencia {
  /// Nombres de los campos tal como existen en la colección de Firestore.
  /// Su uso previene errores de tipeo y centraliza la definición de los campos.
  static const String fieldSedeId = 'sedeId';
  static const String fieldSedeNombre = 'sedeNombre';
  static const String fieldEmpleadoId = 'empleadoId';
  static const String fieldFecha = 'fecha';
  static const String fieldTotalEmpleados = 'totalEmpleados';
  static const String fieldTotalAsistencias = 'totalAsistencias';
  static const String fieldTotalAusencias = 'totalAusencias';
  static const String fieldTotalTardanzas = 'totalTardanzas';
  static const String fieldPorcentajeAsistencia = 'porcentajeAsistencia';

  final String sedeId;
  final String sedeNombre;

  /// ID del empleado si la estadística es individual. Nulo si es para toda la sede.
  final String? empleadoId;

  final DateTime fecha;
  final int totalEmpleados;
  final int totalAsistencias;
  final int totalAusencias;
  final int totalTardanzas;
  final double porcentajeAsistencia;

  /// Constructor principal para una instancia de [EstadisticaAsistencia].
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

  /// Construye una instancia de [EstadisticaAsistencia] a partir de un mapa JSON.
  ///
  /// Lanza [FormatException] si los campos críticos `sedeId` o `fecha` son
  /// nulos o tienen un formato inválido.
  factory EstadisticaAsistencia.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para parsear objetos de fecha de forma segura.
    DateTime? parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date); // Para retrocompatibilidad.
      return null;
    }

    final fecha = parseDate(json[fieldFecha]);
    final sedeId = json[fieldSedeId] as String?;

    // Principio "Fail Fast": Se valida que los datos esenciales existan.
    if (sedeId == null || sedeId.isEmpty) {
      throw FormatException("El campo 'sedeId' es nulo o vacío en los datos de la estadística.");
    }
    if (fecha == null) {
      throw FormatException("El campo 'fecha' es nulo o inválido para la estadística de la sede con ID: $sedeId.");
    }

    return EstadisticaAsistencia(
      sedeId: sedeId,
      sedeNombre: json[fieldSedeNombre] as String? ?? 'Sede Desconocida',
      empleadoId: json[fieldEmpleadoId] as String?,
      fecha: fecha,
      totalEmpleados: json[fieldTotalEmpleados] as int? ?? 0,
      totalAsistencias: json[fieldTotalAsistencias] as int? ?? 0,
      totalAusencias: json[fieldTotalAusencias] as int? ?? 0,
      totalTardanzas: json[fieldTotalTardanzas] as int? ?? 0,
      porcentajeAsistencia: (json[fieldPorcentajeAsistencia] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte la instancia a un mapa JSON para ser guardado en Firestore.
  Map<String, dynamic> toJson() {
    return {
      fieldSedeId: sedeId,
      fieldSedeNombre: sedeNombre,
      fieldEmpleadoId: empleadoId,
      // Se almacena como Timestamp para optimizar las consultas por rango de fechas.
      fieldFecha: Timestamp.fromDate(fecha),
      fieldTotalEmpleados: totalEmpleados,
      fieldTotalAsistencias: totalAsistencias,
      fieldTotalAusencias: totalAusencias,
      fieldTotalTardanzas: totalTardanzas,
      fieldPorcentajeAsistencia: porcentajeAsistencia,
    };
  }
  
  /// Crea una copia de esta instancia, reemplazando los campos proporcionados.
  EstadisticaAsistencia copyWith({
    String? sedeId,
    String? sedeNombre,
    String? empleadoId,
    DateTime? fecha,
    int? totalEmpleados,
    int? totalAsistencias,
    int? totalAusencias,
    int? totalTardanzas,
    double? porcentajeAsistencia,
  }) {
    return EstadisticaAsistencia(
      sedeId: sedeId ?? this.sedeId,
      sedeNombre: sedeNombre ?? this.sedeNombre,
      empleadoId: empleadoId ?? this.empleadoId,
      fecha: fecha ?? this.fecha,
      totalEmpleados: totalEmpleados ?? this.totalEmpleados,
      totalAsistencias: totalAsistencias ?? this.totalAsistencias,
      totalAusencias: totalAusencias ?? this.totalAusencias,
      totalTardanzas: totalTardanzas ?? this.totalTardanzas,
      porcentajeAsistencia: porcentajeAsistencia ?? this.porcentajeAsistencia,
    );
  }
}