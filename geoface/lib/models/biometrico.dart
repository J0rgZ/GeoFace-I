// -----------------------------------------------------------------------------
// @Encabezado:   Gestión de Datos Biométricos
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Define el modelo `Biometrico` para almacenar los datos
//               biométricos faciales de un empleado. Contiene la referencia al
//               empleado, el dato facial y las fechas de registro. El modelo es
//               inmutable y maneja la serialización y deserialización de datos
//               desde y hacia un formato JSON.
//
// @NombreModelo: Biometrico
// @Ubicacion:    lib/models/biometrico.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

// Representa los datos biométricos faciales de un empleado.
//
// Contiene el identificador, la referencia al empleado, el dato facial
// y las fechas de registro y actualización.
// La clase es inmutable; las modificaciones deben hacerse a través del método [copyWith].
class Biometrico {
  // Nombres de los campos tal como existen en la colección de Firestore.
  static const String campoId = 'id';
  static const String campoEmpleadoId = 'empleadoId';
  static const String campoDatoFacial = 'datoFacial';
  static const String campoFechaRegistro = 'fechaRegistro';
  static const String campoFechaActualizacion = 'fechaActualizacion';

  final String id;
  final String empleadoId;
  
  // Representa la referencia al dato facial.
  // En la práctica, puede ser una URL o una representación en base64.
  final String datoFacial;

  // La fecha y hora en que se realizó el registro biométrico.
  final DateTime fechaRegistro;

  // La fecha y hora de la última actualización. Es nulo si nunca se ha modificado.
  final DateTime? fechaActualizacion;

  // Constructor principal para una instancia de [Biometrico].
  Biometrico({
    required this.id,
    required this.empleadoId,
    required this.datoFacial,
    required this.fechaRegistro,
    this.fechaActualizacion,
  });

  // Construye una instancia de [Biometrico] a partir de un mapa JSON.
  //
  // Lanza una excepción [FormatException] si alguno de los campos requeridos es nulo o inválido.
  factory Biometrico.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para interpretar fechas desde Timestamp o String.
    DateTime? analizarFecha(dynamic fecha) {
      if (fecha is Timestamp) return fecha.toDate();
      if (fecha is String) return DateTime.tryParse(fecha);
      return null;
    }

    final id = json[campoId] as String?;
    final empleadoId = json[campoEmpleadoId] as String?;
    final datoFacial = json[campoDatoFacial] as String?;
    final fechaRegistro = analizarFecha(json[campoFechaRegistro]);

    // Principio de "fallo rápido": se valida que los datos esenciales existan y no estén vacíos.
    if (id == null || id.isEmpty) {
      throw FormatException("El campo 'id' es nulo o vacío en los datos biométricos.");
    }
    if (empleadoId == null || empleadoId.isEmpty) {
      throw FormatException("El campo 'empleadoId' es nulo o vacío para el biométrico con ID: $id.");
    }
    if (datoFacial == null || datoFacial.isEmpty) {
      throw FormatException("El campo 'datoFacial' es nulo o vacío para el biométrico con ID: $id.");
    }
    if (fechaRegistro == null) {
      throw FormatException("El campo 'fechaRegistro' es nulo o inválido para el biométrico con ID: $id.");
    }

    return Biometrico(
      id: id,
      empleadoId: empleadoId,
      datoFacial: datoFacial,
      fechaRegistro: fechaRegistro,
      fechaActualizacion: analizarFecha(json[campoFechaActualizacion]),
    );
  }

  // Convierte la instancia a un mapa JSON para ser guardado en Firestore.
  Map<String, dynamic> toJson() {
    return {
      campoId: id,
      campoEmpleadoId: empleadoId,
      campoDatoFacial: datoFacial,
      campoFechaRegistro: Timestamp.fromDate(fechaRegistro),
      campoFechaActualizacion: fechaActualizacion != null
          ? Timestamp.fromDate(fechaActualizacion!)
          : null,
    };
  }
  
  // Crea una copia de esta instancia, reemplazando los campos proporcionados con nuevos valores.
  Biometrico copyWith({
    String? id,
    String? empleadoId,
    String? datoFacial,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
  }) {
    return Biometrico(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      datoFacial: datoFacial ?? this.datoFacial,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}