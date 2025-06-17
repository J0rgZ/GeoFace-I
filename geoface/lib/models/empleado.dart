// lib/models/empleado.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Empleado {
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
  final bool tieneUsuario; // CAMPO CLAVE

  Empleado({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.cargo,
    required this.sedeId,
    required this.dni,
    required this.celular,
    this.hayDatosBiometricos = false,
    this.activo = true,
    required this.fechaCreacion,
    this.fechaModificacion,
    this.tieneUsuario = false, // VALOR POR DEFECTO
  });

  String get nombreCompleto => '$nombre $apellidos';

  /// Factory principal para crear una instancia desde un Map/JSON.
  /// Es robusto y maneja Timestamps de Firestore o Strings de fechas.
  factory Empleado.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para parsear fechas de forma segura
    DateTime _parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now(); // Fallback por si el dato es nulo o inválido
    }

    return Empleado(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      correo: json['correo'] ?? '',
      cargo: json['cargo'] ?? '',
      sedeId: json['sedeId'] ?? '',
      dni: json['dni'] ?? '',
      celular: json['celular'] ?? '',
      hayDatosBiometricos: json['hayDatosBiometricos'] ?? false,
      activo: json['activo'] ?? false,
      fechaCreacion: _parseDate(json['fechaCreacion']),
      fechaModificacion: json['fechaModificacion'] != null ? _parseDate(json['fechaModificacion']) : null,
      tieneUsuario: json['tieneUsuario'] ?? false,
    );
  }
  
  // Mantenemos fromMap como un alias para compatibilidad con tu código.
  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado.fromJson(map);
  }

  /// Método para convertir el objeto a un Map para guardar en Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'correo': correo,
      'cargo': cargo,
      'sedeId': sedeId,
      'dni': dni,
      'celular': celular,
      'hayDatosBiometricos': hayDatosBiometricos,
      'activo': activo,
      // Al guardar, usamos el formato nativo de Firestore
      'fechaCreacion': fechaCreacion,
      'fechaModificacion': fechaModificacion,
      'tieneUsuario': tieneUsuario,
    };
  }

  /// Método para crear una copia del objeto con algunos campos modificados.
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