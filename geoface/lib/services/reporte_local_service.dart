// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Almacenamiento Local de Reportes
// @Autor:        Sistema GeoFace
// @Descripción:  Servicio para gestionar reportes guardados localmente usando
//               SQLite con path_provider para almacenamiento de archivos.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/reporte_guardado.dart';

class ReporteLocalService {
  static final ReporteLocalService _instance = ReporteLocalService._internal();
  factory ReporteLocalService() => _instance;
  ReporteLocalService._internal();

  Database? _database;
  Directory? _reportesDirectory;

  /// Inicializa la base de datos y el directorio de reportes
  Future<void> initialize() async {
    if (_database != null) return;

    // Obtener directorio de documentos de la app
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDir.path, 'geoface_reports.db');

    // Crear directorio para reportes PDF
    _reportesDirectory = Directory(path.join(appDir.path, 'reportes'));
    if (!await _reportesDirectory!.exists()) {
      await _reportesDirectory!.create(recursive: true);
    }

    // Abrir o crear base de datos
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reportes_guardados (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombreArchivo TEXT NOT NULL,
            rutaArchivo TEXT NOT NULL UNIQUE,
            usuarioId TEXT NOT NULL,
            usuarioNombre TEXT NOT NULL,
            fechaGeneracion TEXT NOT NULL,
            fechaInicio TEXT NOT NULL,
            fechaFin TEXT NOT NULL,
            sedeId TEXT,
            sedeNombre TEXT,
            totalAsistencias INTEGER NOT NULL,
            totalAusencias INTEGER NOT NULL,
            totalTardanzas INTEGER NOT NULL,
            porcentajeAsistencia REAL NOT NULL,
            totalEmpleados INTEGER NOT NULL,
            tamanioArchivo INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_fecha_generacion ON reportes_guardados(fechaGeneracion DESC)
        ''');
        await db.execute('''
          CREATE INDEX idx_usuario_id ON reportes_guardados(usuarioId)
        ''');
      },
    );
  }

  /// Obtiene el directorio donde se guardan los reportes
  Future<Directory> getReportesDirectory() async {
    await initialize();
    return _reportesDirectory!;
  }

  /// Guarda un reporte en el almacenamiento local
  Future<ReporteGuardado> guardarReporte({
    required String nombreArchivo,
    required List<int> bytesArchivo,
    required String usuarioId,
    required String usuarioNombre,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? sedeId,
    String? sedeNombre,
    required int totalAsistencias,
    required int totalAusencias,
    required int totalTardanzas,
    required double porcentajeAsistencia,
    required int totalEmpleados,
  }) async {
    await initialize();

    final reportesDir = await getReportesDirectory();
    final archivo = File(path.join(reportesDir.path, nombreArchivo));

    // Guardar archivo PDF
    await archivo.writeAsBytes(bytesArchivo);

    // Guardar metadatos en base de datos
    final reporteGuardado = ReporteGuardado(
      nombreArchivo: nombreArchivo,
      rutaArchivo: archivo.path,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      fechaGeneracion: DateTime.now(),
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      sedeId: sedeId,
      sedeNombre: sedeNombre,
      totalAsistencias: totalAsistencias,
      totalAusencias: totalAusencias,
      totalTardanzas: totalTardanzas,
      porcentajeAsistencia: porcentajeAsistencia,
      totalEmpleados: totalEmpleados,
      tamanioArchivo: bytesArchivo.length,
    );

    final id = await _database!.insert(
      'reportes_guardados',
      reporteGuardado.toMap(),
    );

    return reporteGuardado.copyWith(id: id);
  }

  /// Obtiene todos los reportes guardados
  Future<List<ReporteGuardado>> obtenerReportesGuardados({
    String? usuarioId,
    int? limite,
  }) async {
    await initialize();

    var query = 'SELECT * FROM reportes_guardados';
    final whereClauses = <String>[];

    if (usuarioId != null) {
      whereClauses.add('usuarioId = ?');
    }

    if (whereClauses.isNotEmpty) {
      query += ' WHERE ${whereClauses.join(' AND ')}';
    }

    query += ' ORDER BY fechaGeneracion DESC';

    if (limite != null) {
      query += ' LIMIT ?';
    }

    final List<dynamic> args = [];
    if (usuarioId != null) {
      args.add(usuarioId);
    }
    if (limite != null) {
      args.add(limite);
    }

    final maps = await _database!.rawQuery(query, args.isEmpty ? null : args);
    return maps.map((map) => ReporteGuardado.fromMap(map)).toList();
  }

  /// Obtiene un reporte por su ID
  Future<ReporteGuardado?> obtenerReportePorId(int id) async {
    await initialize();

    final maps = await _database!.query(
      'reportes_guardados',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ReporteGuardado.fromMap(maps.first);
  }

  /// Elimina un reporte guardado (archivo y registro)
  Future<bool> eliminarReporte(int id) async {
    await initialize();

    final reporte = await obtenerReportePorId(id);
    if (reporte == null) return false;

    // Eliminar archivo
    final archivo = File(reporte.rutaArchivo);
    if (await archivo.exists()) {
      await archivo.delete();
    }

    // Eliminar registro de base de datos
    final resultado = await _database!.delete(
      'reportes_guardados',
      where: 'id = ?',
      whereArgs: [id],
    );

    return resultado > 0;
  }

  /// Obtiene el tamaño total de todos los reportes guardados
  Future<int> obtenerTamanioTotal() async {
    await initialize();

    final maps = await _database!.query('reportes_guardados',
        columns: ['tamanioArchivo']);
    return maps.fold<int>(
        0, (sum, map) => sum + (map['tamanioArchivo'] as int));
  }

  /// Limpia reportes antiguos (más de X días)
  Future<int> limpiarReportesAntiguos(int dias) async {
    await initialize();

    final fechaLimite = DateTime.now().subtract(Duration(days: dias));
    final reportes = await obtenerReportesGuardados();

    int eliminados = 0;
    for (final reporte in reportes) {
      if (reporte.fechaGeneracion.isBefore(fechaLimite)) {
        if (await eliminarReporte(reporte.id!)) {
          eliminados++;
        }
      }
    }

    return eliminados;
  }

  /// Cierra la base de datos
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

// Extensión para copiar con nuevo ID
extension ReporteGuardadoExtension on ReporteGuardado {
  ReporteGuardado copyWith({int? id}) {
    return ReporteGuardado(
      id: id ?? this.id,
      nombreArchivo: nombreArchivo,
      rutaArchivo: rutaArchivo,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      fechaGeneracion: fechaGeneracion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      sedeId: sedeId,
      sedeNombre: sedeNombre,
      totalAsistencias: totalAsistencias,
      totalAusencias: totalAusencias,
      totalTardanzas: totalTardanzas,
      porcentajeAsistencia: porcentajeAsistencia,
      totalEmpleados: totalEmpleados,
      tamanioArchivo: tamanioArchivo,
    );
  }
}


