// -----------------------------------------------------------------------------
// @Encabezado:   Modelo de Reporte Guardado
// @Autor:        Sistema GeoFace
// @Descripción:  Modelo para almacenar reportes generados localmente con
//               metadatos para vista previa y gestión.
// -----------------------------------------------------------------------------

class ReporteGuardado {
  final int? id; // ID local en SQLite
  final String nombreArchivo;
  final String rutaArchivo;
  final String usuarioId;
  final String usuarioNombre;
  final DateTime fechaGeneracion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? sedeId;
  final String? sedeNombre;
  final int totalAsistencias;
  final int totalAusencias;
  final int totalTardanzas;
  final double porcentajeAsistencia;
  final int totalEmpleados;
  final int tamanioArchivo; // en bytes

  ReporteGuardado({
    this.id,
    required this.nombreArchivo,
    required this.rutaArchivo,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.fechaGeneracion,
    required this.fechaInicio,
    required this.fechaFin,
    this.sedeId,
    this.sedeNombre,
    required this.totalAsistencias,
    required this.totalAusencias,
    required this.totalTardanzas,
    required this.porcentajeAsistencia,
    required this.totalEmpleados,
    required this.tamanioArchivo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreArchivo': nombreArchivo,
      'rutaArchivo': rutaArchivo,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'sedeId': sedeId,
      'sedeNombre': sedeNombre,
      'totalAsistencias': totalAsistencias,
      'totalAusencias': totalAusencias,
      'totalTardanzas': totalTardanzas,
      'porcentajeAsistencia': porcentajeAsistencia,
      'totalEmpleados': totalEmpleados,
      'tamanioArchivo': tamanioArchivo,
    };
  }

  factory ReporteGuardado.fromMap(Map<String, dynamic> map) {
    return ReporteGuardado(
      id: map['id'] as int?,
      nombreArchivo: map['nombreArchivo'] as String,
      rutaArchivo: map['rutaArchivo'] as String,
      usuarioId: map['usuarioId'] as String,
      usuarioNombre: map['usuarioNombre'] as String,
      fechaGeneracion: DateTime.parse(map['fechaGeneracion'] as String),
      fechaInicio: DateTime.parse(map['fechaInicio'] as String),
      fechaFin: DateTime.parse(map['fechaFin'] as String),
      sedeId: map['sedeId'] as String?,
      sedeNombre: map['sedeNombre'] as String?,
      totalAsistencias: map['totalAsistencias'] as int,
      totalAusencias: map['totalAusencias'] as int,
      totalTardanzas: map['totalTardanzas'] as int,
      porcentajeAsistencia: map['porcentajeAsistencia'] as double,
      totalEmpleados: map['totalEmpleados'] as int,
      tamanioArchivo: map['tamanioArchivo'] as int,
    );
  }

  String get tamanioFormateado {
    if (tamanioArchivo < 1024) {
      return '$tamanioArchivo B';
    } else if (tamanioArchivo < 1024 * 1024) {
      return '${(tamanioArchivo / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(tamanioArchivo / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}


