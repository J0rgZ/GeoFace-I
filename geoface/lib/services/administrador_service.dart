// FILE: lib/services/administrador_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

class AdministradorService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene una lista de todos los usuarios con tipo 'ADMIN'.
  /// Esta consulta requiere un índice compuesto en Firestore.
  Future<List<Usuario>> getAdministradores() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'ADMIN')
          .orderBy('nombreUsuario') // Ordena alfabéticamente
          .get();
      
      return snapshot.docs.map((doc) {
        return Usuario.fromJson({'id': doc.id, ...doc.data()});
      }).toList();

    } catch (e) {
      debugPrint('Error en AdministradorService.getAdministradores: $e');
      // Lanza una excepción para que el controlador la maneje.
      throw Exception('Error al cargar la lista de administradores.');
    }
  }

  /// Crea un nuevo usuario administrador en Firebase Auth y luego en Firestore.
  Future<void> createAdminUser({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    // La transacción se maneja aquí, en la capa de servicio.
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: correo, password: password);
      final uid = userCredential.user!.uid;
      
      final usuarioData = {
        'nombreUsuario': nombreUsuario,
        'correo': correo,
        'tipoUsuario': 'ADMIN',
        'empleadoId': null,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaUltimoAcceso': null,
      };
      
      await _firestore.collection('usuarios').doc(uid).set(usuarioData);

    } on FirebaseAuthException catch (e) {
      // Re-lanzamos excepciones específicas para que el controlador las interprete.
      switch (e.code) {
        case 'email-already-in-use': throw Exception('El correo electrónico ya está en uso.');
        case 'weak-password': throw Exception('La contraseña es demasiado débil.');
        case 'invalid-email': throw Exception('El correo electrónico no es válido.');
        default: throw Exception('Error de Firebase Auth: ${e.message}');
      }
    } catch (e) {
      debugPrint('Error inesperado en AdministradorService.createAdminUser: $e');
      throw Exception('Ocurrió un error inesperado al crear el administrador.');
    }
  }
  
  /// Actualiza el nombre de un usuario administrador en Firestore.
  Future<void> updateAdminUser({required String userId, required String nombreUsuario}) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({'nombreUsuario': nombreUsuario});
    } catch (e) {
      throw Exception('Error al actualizar los datos del administrador.');
    }
  }

  /// Cambia el estado 'activo' de un usuario en Firestore.
  Future<void> toggleUserStatus({required String userId, required bool currentStatus}) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({'activo': !currentStatus});
    } catch (e) {
      throw Exception('Error al cambiar el estado del administrador.');
    }
  }
}