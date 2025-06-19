import 'package:cloud_firestore/cloud_firestore.dart';

class Asistencia {
  final String id;
  final String empleadoId;
  final String sedeId;
  final DateTime fechaHoraEntrada;
  final DateTime? fechaHoraSalida;
  final double latitudEntrada;
  final double longitudEntrada;
  final double? latitudSalida;
  final double? longitudSalida;
  final String? capturaEntrada;
  final String? capturaSalida;

  Asistencia({
    required this.id,
    required this.empleadoId,
    required this.sedeId,
    required this.fechaHoraEntrada,
    this.fechaHoraSalida,
    required this.latitudEntrada,
    required this.longitudEntrada,
    this.latitudSalida,
    this.longitudSalida,
    required this.capturaEntrada,
    this.capturaSalida,
  });

  // --- Getters (sin cambios) ---
  bool get registroCompleto => fechaHoraSalida != null;

  Duration get tiempoTrabajado => fechaHoraSalida != null
      ? fechaHoraSalida!.difference(fechaHoraEntrada)
      : DateTime.now().difference(fechaHoraEntrada);

  // --- MÉTODOS DE CONVERSIÓN CORREGIDOS ---

  /// **(CORREGIDO)** Factory para crear una instancia desde un mapa de Firestore.
  /// Ahora maneja correctamente los Timestamps y los nulos.
  factory Asistencia.fromMap(Map<String, dynamic> map) {
    // Helper para convertir Timestamps o Strings a DateTime de forma segura
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date); // Para compatibilidad con datos antiguos
      return null;
    }

    final fechaEntrada = parseDate(map['fechaHoraEntrada']);
    if (fechaEntrada == null) {
      // Si la fecha de entrada es inválida o nula, no se puede crear el objeto.
      throw FormatException("Fecha de entrada inválida o nula para el documento: ${map['id']}");
    }

    return Asistencia(
      id: map['id'] ?? '',
      empleadoId: map['empleadoId'] ?? '',
      sedeId: map['sedeId'] ?? '',
      fechaHoraEntrada: fechaEntrada,
      fechaHoraSalida: parseDate(map['fechaHoraSalida']),
      // Casting seguro para números
      latitudEntrada: (map['latitudEntrada'] as num?)?.toDouble() ?? 0.0,
      longitudEntrada: (map['longitudEntrada'] as num?)?.toDouble() ?? 0.0,
      latitudSalida: (map['latitudSalida'] as num?)?.toDouble(),
      longitudSalida: (map['longitudSalida'] as num?)?.toDouble(),
      capturaEntrada: map['capturaEntrada'] ?? '',
      capturaSalida: map['capturaSalida'],
    );
  }

  /// **(CORREGIDO)** Mantiene la compatibilidad con el código que usa `fromJson`.
  /// Simplemente llama a `fromMap` que tiene la lógica correcta.
  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia.fromMap(json);
  }

  /// **(MEJORADO)** Convierte la instancia a un mapa para guardar en Firestore.
  /// Se excluyen las fechas, ya que es mejor práctica usar `FieldValue.serverTimestamp()`
  /// en el servicio (`FirebaseService`) para garantizar la hora correcta del servidor.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empleadoId': empleadoId,
      'sedeId': sedeId,
      'latitudEntrada': latitudEntrada,
      'longitudEntrada': longitudEntrada,
      'latitudSalida': latitudSalida,
      'longitudSalida': longitudSalida,
      'capturaEntrada': capturaEntrada,
      'capturaSalida': capturaSalida,
      // NOTA: fechaHoraEntrada y fechaHoraSalida se deben añadir en FirebaseService
      // usando FieldValue.serverTimestamp() para máxima precisión.
    };
  }

  // --- Método copyWith (sin cambios) ---
  Asistencia copyWith({
    String? id,
    String? empleadoId,
    String? sedeId,
    DateTime? fechaHoraEntrada,
    DateTime? fechaHoraSalida,
    double? latitudEntrada,
    double? longitudEntrada,
    double? latitudSalida,
    double? longitudSalida,
    String? capturaEntrada,
    String? capturaSalida,
  }) {
    return Asistencia(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      sedeId: sedeId ?? this.sedeId,
      fechaHoraEntrada: fechaHoraEntrada ?? this.fechaHoraEntrada,
      fechaHoraSalida: fechaHoraSalida ?? this.fechaHoraSalida,
      latitudEntrada: latitudEntrada ?? this.latitudEntrada,
      longitudEntrada: longitudEntrada ?? this.longitudEntrada,
      latitudSalida: latitudSalida ?? this.latitudSalida,
      longitudSalida: longitudSalida ?? this.longitudSalida,
      capturaEntrada: capturaEntrada ?? this.capturaEntrada,
      capturaSalida: capturaSalida ?? this.capturaSalida,  
    );
  }
}