// -----------------------------------------------------------------------------
// @Encabezado:   Modelo de Auditoría
// @Autor:        Sistema GeoFace
// @Descripción:  Modelo para registrar todas las acciones de administradores
//               y eventos importantes del sistema en la base de datos.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoAccion {
  login,
  logout,
  crearEmpleado,
  editarEmpleado,
  eliminarEmpleado,
  crearSede,
  editarSede,
  eliminarSede,
  crearAdministrador,
  editarAdministrador,
  eliminarAdministrador,
  generarReporte,
  exportarReporte,
  cambiarContrasena,
  actualizarConfiguracion,
}

enum TipoEntidad {
  empleado,
  sede,
  administrador,
  reporte,
  configuracion,
  sesion,
}

class Auditoria {
  final String id;
  final String usuarioId;
  final String usuarioNombre;
  final TipoAccion tipoAccion;
  final TipoEntidad tipoEntidad;
  final String? entidadId;
  final String? entidadNombre;
  final String descripcion;
  final Map<String, dynamic>? datosAdicionales;
  final String? dispositivoId;
  final String? dispositivoMarca;
  final String? dispositivoModelo;
  final DateTime fechaHora;
  final String? ipAddress;

  Auditoria({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.tipoAccion,
    required this.tipoEntidad,
    this.entidadId,
    this.entidadNombre,
    required this.descripcion,
    this.datosAdicionales,
    this.dispositivoId,
    this.dispositivoMarca,
    this.dispositivoModelo,
    required this.fechaHora,
    this.ipAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'tipoAccion': tipoAccion.name,
      'tipoEntidad': tipoEntidad.name,
      'entidadId': entidadId,
      'entidadNombre': entidadNombre,
      'descripcion': descripcion,
      'datosAdicionales': datosAdicionales,
      'dispositivoId': dispositivoId,
      'dispositivoMarca': dispositivoMarca,
      'dispositivoModelo': dispositivoModelo,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'ipAddress': ipAddress,
    };
  }

  factory Auditoria.fromJson(Map<String, dynamic> json) {
    return Auditoria(
      id: json['id'] as String,
      usuarioId: json['usuarioId'] as String,
      usuarioNombre: json['usuarioNombre'] as String,
      tipoAccion: TipoAccion.values.firstWhere(
        (e) => e.name == json['tipoAccion'],
        orElse: () => TipoAccion.actualizarConfiguracion,
      ),
      tipoEntidad: TipoEntidad.values.firstWhere(
        (e) => e.name == json['tipoEntidad'],
        orElse: () => TipoEntidad.configuracion,
      ),
      entidadId: json['entidadId'] as String?,
      entidadNombre: json['entidadNombre'] as String?,
      descripcion: json['descripcion'] as String,
      datosAdicionales: json['datosAdicionales'] as Map<String, dynamic>?,
      dispositivoId: json['dispositivoId'] as String?,
      dispositivoMarca: json['dispositivoMarca'] as String?,
      dispositivoModelo: json['dispositivoModelo'] as String?,
      fechaHora: (json['fechaHora'] as Timestamp).toDate(),
      ipAddress: json['ipAddress'] as String?,
    );
  }

  String get tipoAccionTexto {
    switch (tipoAccion) {
      case TipoAccion.login:
        return 'Inicio de Sesión';
      case TipoAccion.logout:
        return 'Cierre de Sesión';
      case TipoAccion.crearEmpleado:
        return 'Crear Empleado';
      case TipoAccion.editarEmpleado:
        return 'Editar Empleado';
      case TipoAccion.eliminarEmpleado:
        return 'Eliminar Empleado';
      case TipoAccion.crearSede:
        return 'Crear Sede';
      case TipoAccion.editarSede:
        return 'Editar Sede';
      case TipoAccion.eliminarSede:
        return 'Eliminar Sede';
      case TipoAccion.crearAdministrador:
        return 'Crear Administrador';
      case TipoAccion.editarAdministrador:
        return 'Editar Administrador';
      case TipoAccion.eliminarAdministrador:
        return 'Eliminar Administrador';
      case TipoAccion.generarReporte:
        return 'Generar Reporte';
      case TipoAccion.exportarReporte:
        return 'Exportar Reporte';
      case TipoAccion.cambiarContrasena:
        return 'Cambiar Contraseña';
      case TipoAccion.actualizarConfiguracion:
        return 'Actualizar Configuración';
    }
  }
}


