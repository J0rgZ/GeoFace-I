// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Empleados
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `EmpleadoService`, que actúa como
//               una capa de servicio para todas las operaciones relacionadas con
//               empleados en Firebase. Centraliza las operaciones CRUD con Cloud
//               Firestore para la colección de empleados, desacoplando la lógica
//               de la base de datos de los controladores y la interfaz de usuario.
//               Este enfoque mejora la mantenibilidad y la organización del código.
//
// @NombreArchivo: empleado_service.dart
// @Ubicacion:    lib/services/empleado_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../app_config.dart';
import '../models/empleado.dart';

/// Clase de servicio para gestionar todas las operaciones relacionadas con empleados.
///
/// Centraliza las operaciones de Firestore para la colección de empleados,
/// manteniendo el código organizado y desacoplado de la lógica de la interfaz.
class EmpleadoService {
  // Instancia de Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene una lista con todos los empleados de la colección.
  Future<List<Empleado>> getEmpleados() async {
    final snapshot = await _firestore.collection(AppConfig.empleadosCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Empleado.fromJson(data);
    }).toList();
  }

  /// Obtiene un empleado específico por su ID de documento.
  Future<Empleado?> getEmpleadoById(String id) async {
    final doc = await _firestore.collection(AppConfig.empleadosCollection).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Empleado.fromJson(data);
    }
    return null;
  }

  /// Busca y obtiene un empleado por su número de DNI.
  ///
  /// Limita la búsqueda a 1 para mayor eficiencia, ya que el DNI debe ser único.
  Future<Empleado?> getEmpleadoByDNI(String dni) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.empleadosCollection)
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return Empleado.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error al buscar empleado por DNI: ${e.toString()}');
      throw Exception('No se pudo obtener el empleado por DNI');
    }
  }

  /// Añade un nuevo documento de empleado a la colección.
  Future<void> addEmpleado(Empleado empleado) async {
    final docRef = _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id);
    await docRef.set(empleado.toJson());
  }

  /// Actualiza los datos de un empleado existente en la colección.
  Future<void> updateEmpleado(Empleado empleado) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).update(empleado.toJson());
  }

  /// Elimina un documento de empleado de la colección por su ID.
  Future<void> deleteEmpleado(String id) async {
    await _firestore.collection(AppConfig.empleadosCollection).doc(id).delete();
  }
}

