// -----------------------------------------------------------------------------
// @Encabezado:      Gestión de Usuarios del Sistema
// @Autor:      Jorge Luis Briceño Diaz
// @Descripción: Este archivo define el modelo de datos para la clase `Usuario`.
//              La clase `Usuario` representa a una entidad de usuario en el
//              sistema, gestionando sus roles, datos de acceso y su
//              interacción con la base de datos de Firestore. Este modelo
//              está diseñado para manejar la serialización y deserialización
//              de datos desde y hacia JSON, facilitando la comunicación con
//              la base de datos.
//
// @NombreModelo:   Usuario
// @Ubicacion:    lib/models/usuario.dart
// @FechaInicio:   15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------


import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombreUsuario;
  final String correo;
  final String tipoUsuario;
  final String? empleadoId;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaUltimoAcceso;
  final bool debeCambiarContrasena;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.correo,
    required this.tipoUsuario,
    this.empleadoId,
    required this.activo,
    required this.fechaCreacion,
    this.fechaUltimoAcceso,
    this.debeCambiarContrasena = false,
  });

  /// Comprueba si el usuario tiene el rol de 'ADMIN'.
  bool get isAdmin => tipoUsuario == 'ADMIN';

  /// Comprueba si el usuario tiene el rol de 'EMPLEADO'.
  bool get isEmpleado => tipoUsuario == 'EMPLEADO';

  /// Crea una instancia de [Usuario] a partir de un mapa de datos (JSON).
  ///
  /// Este factory method es clave para la deserialización de los datos
  /// provenientes de Firestore, manejando la conversión de tipos de forma segura.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para parsear fechas de forma segura desde Firestore.
    DateTime? parsearFecha(dynamic fecha) {
      if (fecha == null) return null;
      if (fecha is Timestamp) return fecha.toDate();
      if (fecha is String && fecha.isNotEmpty) return DateTime.tryParse(fecha);
      return null;
    }

    return Usuario(
      id: json['id'] ?? '',
      nombreUsuario: json['nombreUsuario'] ?? '',
      correo: json['correo'] ?? '',
      tipoUsuario: json['tipoUsuario'] ?? '',
      empleadoId: json['empleadoId'],
      activo: json['activo'] ?? false,
      fechaCreacion: parsearFecha(json['fechaCreacion']) ?? DateTime.now(),
      fechaUltimoAcceso: parsearFecha(json['fechaUltimoAcceso']),
      debeCambiarContrasena: json['debeCambiarContrasena'] ?? false,
    );
  }

  /// Convierte la instancia de [Usuario] en un mapa para ser almacenado.
  Map<String, dynamic> toJson() {
    return {
      'nombreUsuario': nombreUsuario,
      'correo': correo,
      'tipoUsuario': tipoUsuario,
      'empleadoId': empleadoId,
      'activo': activo,
      // Se recomienda usar FieldValue.serverTimestamp() al escribir en Firestore
      // por primera vez para garantizar la consistencia de la hora del servidor.
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaUltimoAcceso': fechaUltimoAcceso?.toIso8601String(),
      'debeCambiarContrasena': debeCambiarContrasena,
    };
  }
}