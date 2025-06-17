// lib/services/empleado_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/empleado.dart';
import '../app_config.dart'; // Asegúrate de tener este import si usas AppConfig

class EmpleadoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Obtener todos los empleados
  Future<List<Empleado>> getEmpleados() async {
    try {
      final querySnapshot = await _firestore.collection(AppConfig.empleadosCollection).get();
      
      // La clave está aquí: pasamos el 'id' del documento al factory
      return querySnapshot.docs.map((doc) {
        return Empleado.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener empleados: $e');
      throw Exception('No se pudieron cargar los empleados');
    }
  }
  
  /// Obtener empleado por ID
  Future<Empleado?> getEmpleadoById(String id) async {
    try {
      final docSnapshot = await _firestore.collection(AppConfig.empleadosCollection).doc(id).get();
      
      if (docSnapshot.exists) {
        return Empleado.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data()!,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener empleado: $e');
      return null;
    }
  }
  
  /// Crear nuevo empleado
  Future<void> createEmpleado(Empleado empleado, {File? fotoFile}) async {
    try {
      final data = empleado.toJson();
      
      if (fotoFile != null) {
        final ref = _storage.ref().child('empleados_fotos/${empleado.id}');
        final uploadTask = await ref.putFile(fotoFile);
        data['fotoUrl'] = await uploadTask.ref.getDownloadURL();
      }
      
      await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).set(data);
    } catch (e) {
      debugPrint('Error al crear empleado: $e');
      throw Exception('No se pudo crear el empleado');
    }
  }
  
  /// Actualizar empleado
  Future<void> updateEmpleado(Empleado empleado, {File? fotoFile}) async {
    try {
      final data = empleado.toJson();

      if (fotoFile != null) {
        final ref = _storage.ref().child('empleados_fotos/${empleado.id}');
        final uploadTask = await ref.putFile(fotoFile);
        data['fotoUrl'] = await uploadTask.ref.getDownloadURL();
      }
      
      await _firestore.collection(AppConfig.empleadosCollection).doc(empleado.id).update(data);
    } catch (e) {
      debugPrint('Error al actualizar empleado: $e');
      throw Exception('No se pudo actualizar el empleado');
    }
  }
}