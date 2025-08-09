import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa a un usuario del sistema, con roles y datos de acceso.
///
/// Un usuario puede ser de tipo 'ADMIN' o 'EMPLEADO', lo que determina
/// los permisos y la información asociada que tendrá en la aplicación.
class Usuario {
  /// El identificador único del documento de Firestore.
  final String id;

  /// El nombre con el que el usuario se identifica en el sistema.
  final String nombreUsuario;

  /// La dirección de correo electrónico, usada para el inicio de sesión.
  final String correo;

  /// Define el rol del usuario. Los valores esperados son 'ADMIN' o 'EMPLEADO'.
  final String tipoUsuario;

  /// El ID del empleado asociado, si el [tipoUsuario] es 'EMPLEADO'.
  /// Es nulo para los administradores.
  final String? empleadoId;

  /// Indica si la cuenta de usuario está habilitada para usar el sistema.
  final bool activo;

  /// La fecha y hora en que la cuenta de usuario fue creada.
  final DateTime fechaCreacion;

  /// La fecha y hora del último inicio de sesión. Puede ser nulo si nunca ha accedido.
  final DateTime? fechaUltimoAcceso;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.correo,
    required this.tipoUsuario,
    this.empleadoId,
    required this.activo,
    required this.fechaCreacion,
    this.fechaUltimoAcceso,
  });

  /// Comprueba si el usuario tiene el rol de 'ADMIN'.
  bool get isAdmin => tipoUsuario == 'ADMIN';

  /// Comprueba si el usuario tiene el rol de 'EMPLEADO'.
  bool get isEmpleado => tipoUsuario == 'EMPLEADO';

  /// Crea una instancia de [Usuario] a partir de un mapa JSON.
  ///
  /// Este método es robusto y maneja la conversión de [Timestamp] de Firestore
  /// o de un [String] en formato ISO 8601 a [DateTime].
  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para parsear fechas de forma segura.
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
    );
  }

  /// Convierte la instancia de [Usuario] en un mapa JSON.
  ///
  /// El 'id' generalmente no se incluye en el mapa, ya que es el identificador
  /// del documento en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'nombreUsuario': nombreUsuario,
      'correo': correo,
      'tipoUsuario': tipoUsuario,
      'empleadoId': empleadoId,
      'activo': activo,
      // Se recomienda usar FieldValue.serverTimestamp() al escribir en Firestore.
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaUltimoAcceso': fechaUltimoAcceso?.toIso8601String(),
    };
  }
}