// -----------------------------------------------------------------------------
// @Encabezado:   Gestión de Estadísticas de Asistencia
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Define el modelo `EstadisticaAsistencia` para almacenar
//               resúmenes estadísticos de asistencia por sede y fecha. Puede
//               ser a nivel de sede o por empleado individual. El modelo es

//               inmutable y maneja la serialización y deserialización de datos
//               desde y hacia un formato JSON para su uso con Firestore.
//
// @NombreModelo: EstadisticaAsistencia
// @Ubicacion:    lib/models/estadistica_asistencia.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un resumen estadístico de la asistencia para una sede y fecha específicas.
///
/// La estadística puede ser a nivel de toda la sede o para un empleado individual
/// si el campo [empleadoId] está presente.
/// Esta clase es inmutable. Para modificaciones, se debe utilizar el método [copyWith].
class EstadisticaAsistencia {
  /// Nombres de los campos tal como existen en la colección de Firestore.
  /// Su uso previene errores de tipeo y centraliza la definición de los campos.
  static const String campoSedeId = 'sedeId';
  static const String campoSedeNombre = 'sedeNombre';
  static const String campoEmpleadoId = 'empleadoId';
  static const String campoFecha = 'fecha';
  static const String campoTotalEmpleados = 'totalEmpleados';
  static const String campoTotalAsistencias = 'totalAsistencias';
  static const String campoTotalAusencias = 'totalAusencias';
  static const String campoTotalTardanzas = 'totalTardanzas';
  static const String campoPorcentajeAsistencia = 'porcentajeAsistencia';

  final String sedeId;
  final String sedeNombre;

  /// Identificador del empleado si la estadística es individual. Es nulo si es para toda la sede.
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
  /// Lanza una excepción de tipo [FormatException] si los campos críticos `sedeId` o `fecha` son
  /// nulos o tienen un formato inválido.
  factory EstadisticaAsistencia.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para interpretar objetos de fecha de forma segura.
    DateTime? analizarFecha(dynamic fecha) {
      if (fecha is Timestamp) return fecha.toDate();
      if (fecha is String) return DateTime.tryParse(fecha); // Para retrocompatibilidad.
      return null;
    }

    final fecha = analizarFecha(json[campoFecha]);
    final sedeId = json[campoSedeId] as String?;

    // Principio de "fallo rápido": se valida que los datos esenciales existan.
    if (sedeId == null || sedeId.isEmpty) {
      throw FormatException("El campo 'sedeId' es nulo o vacío en los datos de la estadística.");
    }
    if (fecha == null) {
      throw FormatException("El campo 'fecha' es nulo o inválido para la estadística de la sede con ID: $sedeId.");
    }

    return EstadisticaAsistencia(
      sedeId: sedeId,
      sedeNombre: json[campoSedeNombre] as String? ?? 'Sede Desconocida',
      empleadoId: json[campoEmpleadoId] as String?,
      fecha: fecha,
      totalEmpleados: json[campoTotalEmpleados] as int? ?? 0,
      totalAsistencias: json[campoTotalAsistencias] as int? ?? 0,
      totalAusencias: json[campoTotalAusencias] as int? ?? 0,
      totalTardanzas: json[campoTotalTardanzas] as int? ?? 0,
      porcentajeAsistencia: (json[campoPorcentajeAsistencia] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte la instancia a un mapa JSON para ser guardado en Firestore.
  Map<String, dynamic> toJson() {
    return {
      campoSedeId: sedeId,
      campoSedeNombre: sedeNombre,
      campoEmpleadoId: empleadoId,
      // Se almacena como Timestamp para optimizar las consultas por rango de fechas.
      campoFecha: Timestamp.fromDate(fecha),
      campoTotalEmpleados: totalEmpleados,
      campoTotalAsistencias: totalAsistencias,
      campoTotalAusencias: totalAusencias,
      campoTotalTardanzas: totalTardanzas,
      campoPorcentajeAsistencia: porcentajeAsistencia,
    };
  }
  
  /// Crea una copia de esta instancia, reemplazando los campos proporcionados con nuevos valores.
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