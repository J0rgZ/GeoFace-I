// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Usuarios
// @Autor:        Brayar Lopez Catunta
// @Descripción:  Este archivo contiene la lógica de negocio para la gestión de
//               usuarios del sistema. Maneja la creación, lectura, actualización
//               y eliminación (CRUD) de usuarios de tipo 'ADMIN' y 'EMPLEADO',
//               interactuando con Firebase Authentication y Cloud Firestore.
//               También gestiona el estado de carga para las operaciones asíncronas.
//
// @NombreControlador: UserController
// @Ubicacion:    lib/controllers/user_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class UserController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Variable privada para controlar el estado de carga y evitar múltiples envíos.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Método centralizado para actualizar el estado de carga y notificar a la UI.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- MÉTODOS PARA GESTIÓN DE ADMINISTRADORES ---

  // Obtiene una lista de todos los usuarios con rol de 'ADMIN'.
  // No notifica a los listeners aquí, ya que se usa principalmente con FutureBuilder,
  // el cual gestiona su propio ciclo de vida y estados.
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
      // Relanzamos el error para que sea manejado en la UI.
      throw Exception('Error al cargar los administradores.');
    }
  }

  // Crea un nuevo usuario administrador en Firebase Auth y su documento correspondiente en Firestore.
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
      // Traducimos los errores comunes de Firebase a mensajes más claros para el usuario.
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
  
  // Actualiza el nombre de un usuario administrador en Firestore.
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

  // Cambia la contraseña del usuario que ha iniciado sesión.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay un usuario autenticado para realizar esta acción.');
      }

      // Por seguridad, Firebase exige reautenticar al usuario antes de cambiar la contraseña.
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Si la reautenticación es exitosa, se procede a cambiar la contraseña.
      await user.updatePassword(newPassword);
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('La contraseña actual es incorrecta.');
      } else if (e.code == 'weak-password') {
        throw Exception('La nueva contraseña es demasiado débil.');
      } else {
        throw Exception('Ocurrió un error. Inténtalo de nuevo.');
      }
    } catch (e) {
      throw Exception('Un error inesperado ha ocurrido.');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cambia el estado de un usuario entre 'activo' e 'inactivo'.
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

  // --- MÉTODOS PARA GESTIÓN DE EMPLEADOS ---

  // Obtiene la lista de empleados que aún no tienen una cuenta de usuario asignada.
  Future<List<Map<String, dynamic>>> getEmpleadosSinUsuario() async {
    try {
      final snapshot = await _firestore.collection('empleados').where('tieneUsuario', isEqualTo: false).get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error al cargar los empleados.');
    }
  }
  
  // Asigna una cuenta de usuario a un empleado, usando su DNI para el correo y contraseña inicial.
  Future<void> assignUserToEmpleado({required String empleadoId, required String dni}) async {
    _setLoading(true);
    try {
      final empleadoDoc = await _firestore.collection('empleados').doc(empleadoId).get();
      if (!empleadoDoc.exists) throw Exception('El empleado no existe.');
      
      final empleadoData = empleadoDoc.data()!;
      if (empleadoData['dni'] != dni) throw Exception('El DNI no coincide.');

      // Se genera un correo único y predecible para el empleado.
      final correo = '$dni@geoface.com';
      final userCredential = await _auth.createUserWithEmailAndPassword(email: correo, password: dni);
      
      final usuarioData = {
        'nombreUsuario': empleadoData['nombre'], 'correo': correo, 'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleadoId, 'activo': true, 'fechaCreacion': FieldValue.serverTimestamp(),
      };
      
      // Se crea el documento del usuario y se actualiza el estado del empleado en una transacción implícita.
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