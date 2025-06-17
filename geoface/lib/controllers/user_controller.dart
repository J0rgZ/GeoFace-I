import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class UserController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- MÉTODOS PARA GESTIÓN DE ADMINISTRADORES ---

  /// Obtiene una lista de todos los usuarios con tipo 'ADMIN'.
  /// Requerido por AdministradoresPage.
  Future<List<Usuario>> getAdministradores() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'ADMIN')
          .get();
      
      final administradores = snapshot.docs.map((doc) {
        return Usuario.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
      
      return administradores;
    } catch (e) {
      print('Error al obtener administradores: $e');
      throw Exception('Error al cargar los administradores: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo usuario administrador en Auth y Firestore.
  /// Requerido por AddEditAdminPage.
  Future<void> createAdminUser({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );
      
      final uid = userCredential.user!.uid;
      
      // Crear el registro en Firestore
      final usuarioData = {
        'nombreUsuario': nombreUsuario,
        'correo': correo,
        'tipoUsuario': 'ADMIN',
        'empleadoId': null,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(), // Mejor usar timestamp del servidor
        'fechaUltimoAcceso': null,
      };
      
      await _firestore.collection('usuarios').doc(uid).set(usuarioData);
      
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('El correo electrónico ya está en uso.');
          case 'weak-password':
            throw Exception('La contraseña es demasiado débil (mínimo 6 caracteres).');
          case 'invalid-email':
            throw Exception('El correo electrónico no es válido.');
          default:
            throw Exception('Error al crear usuario: ${e.message}');
        }
      } else {
        throw Exception('Error al crear usuario: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Actualiza el nombre de un usuario administrador.
  /// Requerido por AddEditAdminPage al editar.
  Future<void> updateAdminUser({
    required String userId,
    required String nombreUsuario,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestore.collection('usuarios').doc(userId).update({
        'nombreUsuario': nombreUsuario,
      });

    } catch (e) {
      print('Error al actualizar administrador: $e');
      throw Exception('Error al actualizar los datos: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Cambia el estado 'activo' de un usuario (lo activa si está inactivo, y viceversa).
  /// Requerido por AdministradoresPage para el Switch.
  Future<void> toggleUserStatus(Usuario user) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final newStatus = !user.activo; // Calcula el estado opuesto
      
      await _firestore.collection('usuarios').doc(user.id).update({
        'activo': newStatus,
      });
      
    } catch (e) {
      print('Error al cambiar estado del usuario: $e');
      throw Exception('Error al actualizar el usuario: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTODOS PARA GESTIÓN DE EMPLEADOS ---

  /// Obtiene la lista de empleados sin usuario asignado.
  Future<List<Map<String, dynamic>>> getEmpleadosSinUsuario() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final empleadosSnapshot = await _firestore.collection('empleados').where('tieneUsuario', isEqualTo: false).get();
      
      final empleadosSinUsuario = empleadosSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
      
      return empleadosSinUsuario;
    } catch (e) {
      print('Error al obtener empleados sin usuario: $e');
      throw Exception('Error al cargar los empleados: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Asigna un usuario a un empleado existente, creándolo en Auth y Firestore.
  Future<void> assignUserToEmpleado({
    required String empleadoId,
    required String dni,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final empleadoDoc = await _firestore.collection('empleados').doc(empleadoId).get();
      if (!empleadoDoc.exists) throw Exception('El empleado no existe.');
      
      final empleadoData = empleadoDoc.data() as Map<String, dynamic>;
      final nombreEmpleado = empleadoData['nombre'] as String;
      
      if (empleadoData['dni'] != dni) throw Exception('El DNI no coincide con el del empleado.');
      
      final correo = '$dni@geoface.com';
      
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: dni, // Contraseña inicial igual al DNI
      );
      
      final uid = userCredential.user!.uid;
      
      // Crear el registro en Firestore
      final usuarioData = {
        'nombreUsuario': nombreEmpleado,
        'correo': correo,
        'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleadoId,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaUltimoAcceso': null,
      };
      
      await _firestore.collection('usuarios').doc(uid).set(usuarioData);
      
      // Actualizar el empleado para indicar que tiene usuario asignado
      await _firestore.collection('empleados').doc(empleadoId).update({
        'tieneUsuario': true,
      });
      
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('Ya existe un usuario con este DNI.');
          case 'weak-password':
            throw Exception('El DNI no cumple los requisitos como contraseña.');
          case 'invalid-email':
            throw Exception('No se pudo crear un correo válido con el DNI.');
          default:
            throw Exception('Error al crear usuario: ${e.message}');
        }
      } else {
        throw Exception('Error al asignar usuario: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Obtiene todos los usuarios (útil para vistas generales, si es necesario).
  Future<List<Usuario>> getAllUsers() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final usersSnapshot = await _firestore.collection('usuarios').get();
      
      final users = usersSnapshot.docs.map((doc) {
        return Usuario.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
      
      return users;
    } catch (e) {
      print('Error al obtener usuarios: $e');
      throw Exception('Error al cargar los usuarios: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}