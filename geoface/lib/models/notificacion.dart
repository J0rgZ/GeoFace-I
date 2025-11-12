// -----------------------------------------------------------------------------
// @Encabezado:   Gestión de Notificaciones
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Define el modelo `Notificacion` para representar una
//               notificación en el sistema. Las notificaciones se usan para
//               informar a los administradores sobre eventos relacionados con
//               la asistencia de empleados (entradas, salidas, ausencias, etc.).
//               El modelo es inmutable y maneja la serialización y
//               deserialización para su uso con Firestore.
//
// @NombreModelo: Notificacion
// @Ubicacion:    lib/models/notificacion.dart
// @FechaInicio:  25/06/2025
// @FechaFin:     25/06/2025
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de notificaciones disponibles en el sistema
enum TipoNotificacion {
  entrada,
  salida,
  ausencia,
  tardanza,
  resumenDia,
  resumenSede,
}

/// Representa una notificación en el sistema
class Notificacion {
  // Nombres de los campos tal como existen en la colección de Firestore
  static const String campoId = 'id';
  static const String campoTipo = 'tipo';
  static const String campoTitulo = 'titulo';
  static const String campoMensaje = 'mensaje';
  static const String campoEmpleadoId = 'empleadoId';
  static const String campoEmpleadoNombre = 'empleadoNombre';
  static const String campoSedeId = 'sedeId';
  static const String campoSedeNombre = 'sedeNombre';
  static const String campoFecha = 'fecha';
  static const String campoLeida = 'leida';
  static const String campoData = 'data';

  final String id;
  final TipoNotificacion tipo;
  final String titulo;
  final String mensaje;
  final String? empleadoId;
  final String? empleadoNombre;
  final String? sedeId;
  final String? sedeNombre;
  final DateTime fecha;
  final bool leida;
  final Map<String, dynamic>? data;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.empleadoId,
    this.empleadoNombre,
    this.sedeId,
    this.sedeNombre,
    required this.fecha,
    this.leida = false,
    this.data,
  });

  /// Construye una instancia de [Notificacion] a partir de un mapa JSON
  factory Notificacion.fromJson(Map<String, dynamic> json) {
    DateTime? analizarFecha(dynamic fecha) {
      if (fecha is Timestamp) return fecha.toDate();
      if (fecha is String) return DateTime.tryParse(fecha);
      return null;
    }

    TipoNotificacion parseTipo(String tipo) {
      switch (tipo) {
        case 'entrada':
          return TipoNotificacion.entrada;
        case 'salida':
          return TipoNotificacion.salida;
        case 'ausencia':
          return TipoNotificacion.ausencia;
        case 'tardanza':
          return TipoNotificacion.tardanza;
        case 'resumenDia':
          return TipoNotificacion.resumenDia;
        case 'resumenSede':
          return TipoNotificacion.resumenSede;
        default:
          return TipoNotificacion.entrada;
      }
    }

    final fecha = analizarFecha(json[campoFecha]);

    if (fecha == null) {
      throw FormatException(
          "El campo 'fecha' es inválido en el documento con ID: ${json[campoId]}");
    }

    return Notificacion(
      id: json[campoId] ?? '',
      tipo: parseTipo(json[campoTipo] ?? 'entrada'),
      titulo: json[campoTitulo] ?? '',
      mensaje: json[campoMensaje] ?? '',
      empleadoId: json[campoEmpleadoId],
      empleadoNombre: json[campoEmpleadoNombre],
      sedeId: json[campoSedeId],
      sedeNombre: json[campoSedeNombre],
      fecha: fecha,
      leida: json[campoLeida] ?? false,
      data: json[campoData] != null
          ? Map<String, dynamic>.from(json[campoData])
          : null,
    );
  }

  /// Convierte la instancia de [Notificacion] a un mapa JSON
  Map<String, dynamic> toJson() {
    String tipoToString(TipoNotificacion tipo) {
      switch (tipo) {
        case TipoNotificacion.entrada:
          return 'entrada';
        case TipoNotificacion.salida:
          return 'salida';
        case TipoNotificacion.ausencia:
          return 'ausencia';
        case TipoNotificacion.tardanza:
          return 'tardanza';
        case TipoNotificacion.resumenDia:
          return 'resumenDia';
        case TipoNotificacion.resumenSede:
          return 'resumenSede';
      }
    }

    return {
      campoId: id,
      campoTipo: tipoToString(tipo),
      campoTitulo: titulo,
      campoMensaje: mensaje,
      campoEmpleadoId: empleadoId,
      campoEmpleadoNombre: empleadoNombre,
      campoSedeId: sedeId,
      campoSedeNombre: sedeNombre,
      campoFecha: Timestamp.fromDate(fecha),
      campoLeida: leida,
      campoData: data,
    };
  }

  /// Crea una copia de esta instancia con los campos proporcionados
  Notificacion copyWith({
    String? id,
    TipoNotificacion? tipo,
    String? titulo,
    String? mensaje,
    String? empleadoId,
    String? empleadoNombre,
    String? sedeId,
    String? sedeNombre,
    DateTime? fecha,
    bool? leida,
    Map<String, dynamic>? data,
  }) {
    return Notificacion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      empleadoId: empleadoId ?? this.empleadoId,
      empleadoNombre: empleadoNombre ?? this.empleadoNombre,
      sedeId: sedeId ?? this.sedeId,
      sedeNombre: sedeNombre ?? this.sedeNombre,
      fecha: fecha ?? this.fecha,
      leida: leida ?? this.leida,
      data: data ?? this.data,
    );
  }
}

