import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class UserController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // --- NUEVO: Manejo del estado de carga ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- NUEVO: Método privado para cambiar el estado de carga y notificar a los listeners ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- MÉTODOS PARA GESTIÓN DE ADMINISTRADORES ---

  /// Obtiene una lista de todos los usuarios con tipo 'ADMIN'.
  /// FIX: Se eliminaron las llamadas a notifyListeners que causaban el error.
  /// El FutureBuilder gestionará su propio estado de carga.
  Future<List<Usuario>> getAdministradores() async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'ADMIN')
          .orderBy('nombreUsuario')
          .get();
      
      final administradores = snapshot.docs.map((doc) {
        return Usuario.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
      
      return administradores;
    } catch (e) {
      print('Error al obtener administradores: $e');
      throw Exception('Error al cargar los administradores.');
    }
  }

  /// Crea un nuevo usuario administrador en Auth y Firestore.
  /// Mantiene notifyListeners porque es una acción de usuario, no de build.
  Future<void> createAdminUser({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: correo, password: password);
      final uid = userCredential.user!.uid;
      
      final usuarioData = {
        'nombreUsuario': nombreUsuario, 'correo': correo, 'tipoUsuario': 'ADMIN',
        'empleadoId': null, 'activo': true, 'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaUltimoAcceso': null,
      };
      
      await _firestore.collection('usuarios').doc(uid).set(usuarioData);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use': throw Exception('El correo electrónico ya está en uso.');
        case 'weak-password': throw Exception('La contraseña es demasiado débil.');
        case 'invalid-email': throw Exception('El correo electrónico no es válido.');
        default: throw Exception('Error al crear usuario: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al crear usuario.');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Actualiza el nombre de un usuario administrador.
  Future<void> updateAdminUser({required String userId, required String nombreUsuario}) async {
    _setLoading(true);
    try {
      await _firestore.collection('usuarios').doc(userId).update({'nombreUsuario': nombreUsuario});
    } catch (e) {
      throw Exception('Error al actualizar los datos.');
    } finally {
      _setLoading(false);
    }
  }

  /// Cambia la contraseña del usuario actualmente autenticado.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    // MODIFICADO: Inicia el estado de carga
    _setLoading(true);

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay un usuario autenticado para realizar esta acción.');
      }

      // 1. Reautenticar al usuario para confirmar que conoce la contraseña actual.
      // Esta es una medida de seguridad requerida por Firebase.
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Si la reautenticación es exitosa, cambiar la contraseña.
      await user.updatePassword(newPassword);
      
    } on FirebaseAuthException catch (e) {
      // Traducir errores de Firebase a mensajes amigables.
      if (e.code == 'wrong-password') {
        throw Exception('La contraseña actual es incorrecta.');
      } else if (e.code == 'weak-password') {
        throw Exception('La nueva contraseña es demasiado débil.');
      } else {
        throw Exception('Ocurrió un error. Inténtalo de nuevo.');
      }
    } catch (e) {
      // Capturar cualquier otro error.
      throw Exception('Un error inesperado ha ocurrido.');
    } finally {
      // MODIFICADO: Finaliza el estado de carga, sin importar si hubo éxito o error.
      _setLoading(false);
    }
  }
  
  /// Cambia el estado 'activo' de un usuario.
  Future<void> toggleUserStatus(Usuario user) async {
    _setLoading(true);
    try {
      await _firestore.collection('usuarios').doc(user.id).update({'activo': !user.activo});
    } catch (e) {
      throw Exception('Error al actualizar el usuario.');
    } finally {
      _setLoading(false);
    }
  }

  // --- MÉTODOS PARA GESTIÓN DE EMPLEADOS (FIX APLICADO TAMBIÉN) ---

  /// Obtiene la lista de empleados sin usuario asignado.
  Future<List<Map<String, dynamic>>> getEmpleadosSinUsuario() async {
    try {
      final snapshot = await _firestore.collection('empleados').where('tieneUsuario', isEqualTo: false).get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error al cargar los empleados.');
    }
  }
  
  /// Asigna un usuario a un empleado existente.
  Future<void> assignUserToEmpleado({required String empleadoId, required String dni}) async {
    _setLoading(true);
    try {
      final empleadoDoc = await _firestore.collection('empleados').doc(empleadoId).get();
      if (!empleadoDoc.exists) throw Exception('El empleado no existe.');
      
      final empleadoData = empleadoDoc.data()!;
      if (empleadoData['dni'] != dni) throw Exception('El DNI no coincide.');

      final correo = '$dni@geoface.com';
      final userCredential = await _auth.createUserWithEmailAndPassword(email: correo, password: dni);
      
      final usuarioData = {
        'nombreUsuario': empleadoData['nombre'], 'correo': correo, 'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleadoId, 'activo': true, 'fechaCreacion': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set(usuarioData);
      await _firestore.collection('empleados').doc(empleadoId).update({'tieneUsuario': true});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') throw Exception('Ya existe un usuario con este DNI.');
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al asignar usuario.');
    } finally {
      _setLoading(false);
    }
  }
}