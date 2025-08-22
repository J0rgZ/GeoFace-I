// lib/models/empleado.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para el Empleado. La idea es que sea inmutable.
// Si necesitas cambiar algún dato de un empleado, no lo modifiques directamente,
// mejor crea una copia con los datos nuevos usando el método copyWith().
class Empleado {
  // Ojo: Centralizamos los nombres de los campos de Firestore aquí.
  // Así evitamos errores de tipeo al escribir "nombre", "apellidos", etc. a mano por todo el código.
  // Si se cambia un campo en la base de datos, solo lo modificamos en este lugar y listo.
  static const String fieldId = 'id';
  static const String fieldNombre = 'nombre';
  static const String fieldApellidos = 'apellidos';
  static const String fieldCorreo = 'correo';
  static const String fieldCargo = 'cargo';
  static const String fieldSedeId = 'sedeId';
  static const String fieldDni = 'dni';
  static const String fieldCelular = 'celular';
  static const String fieldHayDatosBiometricos = 'hayDatosBiometricos';
  static const String fieldActivo = 'activo';
  static const String fieldFechaCreacion = 'fechaCreacion';
  static const String fieldFechaModificacion = 'fechaModificacion';
  static const String fieldTieneUsuario = 'tieneUsuario';

  final String id;
  final String nombre;
  final String apellidos;
  final String correo;
  final String cargo;
  final String sedeId;
  final String dni;
  final String celular;
  final bool hayDatosBiometricos;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaModificacion;

  // Este campo es clave para saber si el empleado ya tiene una cuenta de usuario
  // creada en el sistema y puede o no hacer login.
  final bool tieneUsuario;

  Empleado({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.cargo,
    required this.sedeId,
    required this.dni,
    required this.celular,
    required this.fechaCreacion,
    this.hayDatosBiometricos = false,
    this.activo = true,
    this.fechaModificacion,
    this.tieneUsuario = false,
  });

  // Un getter simple para no estar concatenando el nombre a cada rato.
  String get nombreCompleto => '$nombre $apellidos';

  /// Construye un Empleado desde el JSON que nos llega de Firestore.
  factory Empleado.fromJson(Map<String, dynamic> json) {
    // Función pequeña para no repetir el código de parseo de fechas.
    // Si la fecha es inválida o nula, devuelve null para que lo podamos validar después.
    DateTime? parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date);
      return null;
    }

    final fechaCreacion = parseDate(json[fieldFechaCreacion]);

    // --- APLICANDO "FAIL FAST" ---
    // Si la fecha de creación viene nula o en un formato que no entendemos,
    // es mejor que la app falle aquí mismo a que creemos un Empleado con datos corruptos.
    // Por eso lanzamos una excepción y detenemos todo.
    if (fechaCreacion == null) {
      throw FormatException(
        'Error en los datos! La fecha de creación es nula o tiene un formato inválido para el empleado con ID: ${json[fieldId]}');
    }
    
    return Empleado(
      // Usamos las constantes para leer los campos. Más seguro.
      id: json[fieldId] ?? '',
      nombre: json[fieldNombre] ?? '',
      apellidos: json[fieldApellidos] ?? '',
      correo: json[fieldCorreo] ?? '',
      cargo: json[fieldCargo] ?? '',
      sedeId: json[fieldSedeId] ?? '',
      dni: json[fieldDni] ?? '',
      celular: json[fieldCelular] ?? '',
      hayDatosBiometricos: json[fieldHayDatosBiometricos] ?? false,
      // Por defecto, un empleado nuevo siempre está activo.
      activo: json[fieldActivo] ?? true,
      fechaCreacion: fechaCreacion, // Ya validamos que no es nula.
      fechaModificacion: parseDate(json[fieldFechaModificacion]),
      tieneUsuario: json[fieldTieneUsuario] ?? false,
    );
  }

  // Dejo este factory 'fromMap' por si alguna parte del código antiguo lo sigue usando.
  // Así no rompemos nada. Simplemente llama al factory principal.
  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado.fromJson(map);
  }

  // Convierte nuestro objeto Empleado a un mapa que Firestore entiende.
  // También usamos las constantes para asegurar que los nombres de los campos son correctos.
  Map<String, dynamic> toJson() {
    return {
      fieldId: id,
      fieldNombre: nombre,
      fieldApellidos: apellidos,
      fieldCorreo: correo,
      fieldCargo: cargo,
      fieldSedeId: sedeId,
      fieldDni: dni,
      fieldCelular: celular,
      fieldHayDatosBiometricos: hayDatosBiometricos,
      fieldActivo: activo,
      fieldFechaCreacion: fechaCreacion,
      fieldFechaModificacion: fechaModificacion,
      fieldTieneUsuario: tieneUsuario,
    };
  }

  // Crea una copia del empleado, permitiendo cambiar solo los campos que necesitemos.
  // Es la forma correcta de "modificar" un objeto inmutable como este.
  Empleado copyWith({
    String? id,
    String? nombre,
    String? apellidos,
    String? correo,
    String? cargo,
    String? sedeId,
    String? dni,
    String? celular,
    bool? hayDatosBiometricos,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    bool? tieneUsuario,
  }) {
    return Empleado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      correo: correo ?? this.correo,
      cargo: cargo ?? this.cargo,
      sedeId: sedeId ?? this.sedeId,
      dni: dni ?? this.dni,
      celular: celular ?? this.celular,
      hayDatosBiometricos: hayDatosBiometricos ?? this.hayDatosBiometricos,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      tieneUsuario: tieneUsuario ?? this.tieneUsuario,
    );
  }
}