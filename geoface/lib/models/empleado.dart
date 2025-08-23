// -----------------------------------------------------------------------------
// @Encabezado:   Gestión de Empleados
// @Autor:        Brayar Lopez Catunta
// @Descripción:  Define el modelo de datos para la clase `Empleado`. Esta clase
//               representa a un trabajador de la empresa, conteniendo su
//               información personal, de contacto, cargo y estado. El modelo es
//               inmutable y maneja la serialización y deserialización de datos
//               desde y hacia un formato JSON para su uso con Firestore.
//
// @NombreModelo: Empleado
// @Ubicacion:    lib/models/empleado.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para el Empleado. La idea es que sea inmutable.
// Si necesitas cambiar algún dato de un empleado, no lo modifiques directamente,
// mejor crea una copia con los datos nuevos usando el método copyWith().
class Empleado {
  // Ojo: Centralizamos los nombres de los campos de Firestore aquí.
  // Así evitamos errores de tipeo al escribir "nombre", "apellidos", etc. a mano por todo el código.
  // Si se cambia un campo en la base de datos, solo lo modificamos en este lugar y listo.
  static const String campoId = 'id';
  static const String campoNombre = 'nombre';
  static const String campoApellidos = 'apellidos';
  static const String campoCorreo = 'correo';
  static const String campoCargo = 'cargo';
  static const String campoSedeId = 'sedeId';
  static const String campoDni = 'dni';
  static const String campoCelular = 'celular';
  static const String campoHayDatosBiometricos = 'hayDatosBiometricos';
  static const String campoActivo = 'activo';
  static const String campoFechaCreacion = 'fechaCreacion';
  static const String campoFechaModificacion = 'fechaModificacion';
  static const String campoTieneUsuario = 'tieneUsuario';

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

  // Una propiedad computada simple para no estar concatenando el nombre a cada rato.
  String get nombreCompleto => '$nombre $apellidos';

  // Construye un Empleado desde el mapa de datos (JSON) que nos llega de Firestore.
  factory Empleado.fromJson(Map<String, dynamic> json) {
    // Función pequeña para no repetir el código de análisis de fechas.
    // Si la fecha es inválida o nula, devuelve null para que lo podamos validar después.
    DateTime? analizarFecha(dynamic fecha) {
      if (fecha is Timestamp) return fecha.toDate();
      if (fecha is String) return DateTime.tryParse(fecha);
      return null;
    }

    final fechaCreacion = analizarFecha(json[campoFechaCreacion]);

    // --- Principio de "fallo rápido" ---
    // Si la fecha de creación viene nula o en un formato que no entendemos,
    // es mejor que la app falle aquí mismo a que creemos un Empleado con datos corruptos.
    // Por eso lanzamos una excepción y detenemos la creación del objeto.
    if (fechaCreacion == null) {
      throw FormatException(
        'Error en los datos. La fecha de creación es nula o tiene un formato inválido para el empleado con ID: ${json[campoId]}');
    }
    
    return Empleado(
      // Usamos las constantes para leer los campos. Es más seguro y fácil de mantener.
      id: json[campoId] ?? '',
      nombre: json[campoNombre] ?? '',
      apellidos: json[campoApellidos] ?? '',
      correo: json[campoCorreo] ?? '',
      cargo: json[campoCargo] ?? '',
      sedeId: json[campoSedeId] ?? '',
      dni: json[campoDni] ?? '',
      celular: json[campoCelular] ?? '',
      hayDatosBiometricos: json[campoHayDatosBiometricos] ?? false,
      // Por defecto, un empleado nuevo siempre está activo.
      activo: json[campoActivo] ?? true,
      fechaCreacion: fechaCreacion, // Ya validamos que no es nula.
      fechaModificacion: analizarFecha(json[campoFechaModificacion]),
      tieneUsuario: json[campoTieneUsuario] ?? false,
    );
  }

  // Dejo este factory 'fromMap' por si alguna parte del código antiguo lo sigue usando.
  // Así no rompemos nada. Simplemente llama al constructor principal.
  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado.fromJson(map);
  }

  // Convierte nuestro objeto Empleado a un mapa que Firestore entiende.
  // También usamos las constantes para asegurar que los nombres de los campos son correctos.
  Map<String, dynamic> toJson() {
    return {
      campoId: id,
      campoNombre: nombre,
      campoApellidos: apellidos,
      campoCorreo: correo,
      campoCargo: cargo,
      campoSedeId: sedeId,
      campoDni: dni,
      campoCelular: celular,
      campoHayDatosBiometricos: hayDatosBiometricos,
      campoActivo: activo,
      campoFechaCreacion: fechaCreacion,
      campoFechaModificacion: fechaModificacion,
      campoTieneUsuario: tieneUsuario,
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