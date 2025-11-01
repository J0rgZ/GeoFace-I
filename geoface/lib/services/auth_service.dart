// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Autenticación
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `AuthService`, una capa de servicio
//               dedicada exclusivamente a la lógica de autenticación. Encapsula
//               las interacciones con Firebase Authentication para el inicio y
//               cierre de sesión, y con Firestore para obtener los datos
//               detallados del usuario (como roles y permisos) una vez que la
//               autenticación es exitosa. Este enfoque separa las
//               responsabilidades y mantiene el código de los controladores más limpio.
//
// @NombreArchivo: auth_service.dart
// @Ubicacion:    lib/services/auth_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

// Clase de servicio que maneja toda la lógica de autenticación.
class AuthService {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream que notifica en tiempo real sobre los cambios de estado de autenticación (login/logout).
  // Es la forma reactiva y recomendada para manejar el estado de sesión en la app.
  Stream<firebase.User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  // Obtiene el usuario de Firebase Auth de forma síncrona.
  // Es útil para comprobaciones rápidas, pero `authStateChanges` es mejor para reaccionar a los cambios.
  firebase.User? get currentUser => _firebaseAuth.currentUser;
  
  // Inicia sesión de un usuario con correo y contraseña.
  Future<Usuario?> signIn(String email, String password) async {
    try {
      // 1. Autentica al usuario contra Firebase Authentication.
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // 2. Si la autenticación es exitosa, se actualiza la fecha del último acceso en Firestore.
        final userRef = _firestore.collection('usuarios').doc(credential.user!.uid);
        await userRef.update({
          'fechaUltimoAcceso': DateTime.now().toIso8601String(),
        });
        
        // 3. Se obtienen los datos completos del usuario desde Firestore para tener el perfil con roles.
        final userDoc = await userRef.get();
        if (userDoc.exists) {
          return Usuario.fromJson({
            'id': userDoc.id,
            ...userDoc.data()!,
          });
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al iniciar sesión: $e');
      // Relanza la excepción para que el controlador o la UI puedan manejarla y mostrar un mensaje de error.
      rethrow;
    }
  }
  
  // Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
  
  // Obtiene el perfil de usuario completo desde Firestore para el usuario actualmente autenticado.
  Future<Usuario?> getCurrentUserData() async {
    if (currentUser == null) return null;
    
    try {
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        return Usuario.fromJson({
          'id': userDoc.id,
          ...userDoc.data()!,
        });
      }
      
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
      return null;
    }
  }
  
  // Método de conveniencia para verificar rápidamente si el usuario actual tiene rol de administrador.
  Future<bool> isCurrentUserAdmin() async {
    final userData = await getCurrentUserData();
    return userData?.isAdmin ?? false;
  }

  /// Envía un correo electrónico para restablecer la contraseña.
  /// También marca que el usuario debe cambiar su contraseña después del reset.
  Future<void> sendPasswordResetEmail(String correo) async {
    await _firebaseAuth.sendPasswordResetEmail(email: correo);
    
    // Marcar que el usuario debe cambiar su contraseña después del reset
    try {
      final user = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: correo)
          .limit(1)
          .get();
      
      if (user.docs.isNotEmpty) {
        await _firestore.collection('usuarios').doc(user.docs.first.id).update({
          'debeCambiarContrasena': true,
        });
      }
    } catch (e) {
      debugPrint('Error al actualizar debeCambiarContrasena: $e');
    }
  }
}