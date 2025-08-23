// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Autenticación
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo gestiona el estado de autenticación global de la
//               aplicación. Se encarga del inicio y cierre de sesión, escucha
//               los cambios de estado de Firebase Auth en tiempo real, y carga
//               los datos del usuario (como roles y estado de activación) desde
//               Firestore para determinar los permisos dentro de la app.
//
// @NombreControlador: AuthController
// @Ubicacion:    lib/controllers/auth_controller.dart
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

// Define los posibles estados de autenticación para un manejo claro en la UI.
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estado interno del controlador.
  AuthStatus _status = AuthStatus.initial;
  Usuario? _currentUser;
  String? _errorMessage;
  
  // Getters públicos para que la UI reaccione a los cambios de estado.
  AuthStatus get status => _status;
  Usuario? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isEmpleado => _currentUser?.isEmpleado ?? false;
  bool get loading => _status == AuthStatus.loading;

  AuthController() {
    // El constructor inicia la escucha a los cambios de estado de Firebase.
    // Este es el núcleo reactivo del controlador.
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Este método es el oyente principal que reacciona a inicios de sesión,
  // cierres de sesión o cambios en el token del usuario.
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } else {
      // Si Firebase confirma un usuario, buscamos sus datos en nuestra base de datos.
      await _fetchUserData(firebaseUser.uid);
    }
    notifyListeners();
  }
  
  // Busca los datos del usuario en la colección 'usuarios' de Firestore.
  // Aquí es donde se aplican las reglas de negocio, como verificar si la cuenta está activa.
  Future<void> _fetchUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('usuarios').doc(uid).get();
      if (userDoc.exists) {
        final usuario = Usuario.fromJson({'id': userDoc.id, ...userDoc.data()!});
        
        // Regla de negocio: si el usuario no está activo, se cierra su sesión.
        if (usuario.activo) {
          _currentUser = usuario;
          _status = AuthStatus.authenticated;
        } else {
          await _auth.signOut(); // Forza el cierre de sesión.
          _status = AuthStatus.unauthenticated;
          _errorMessage = 'Tu cuenta ha sido desactivada. Contacta al administrador.';
        }
      } else {
        // Si el usuario existe en Auth pero no en Firestore, es un estado inconsistente.
        await _auth.signOut();
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'No se encontraron datos de usuario asociados a esta cuenta.';
      }
    } catch(e) {
        await _auth.signOut();
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Error al cargar los datos del usuario.';
    }
  }

  // Permite a la UI establecer un mensaje de error, por ejemplo, para validaciones de formulario.
  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Inicia sesión con correo y contraseña.
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    setErrorMessage(null); // Limpia errores previos.
    notifyListeners();

    try {
      // Se estandariza el formato del correo para asegurar la consistencia.
      String finalEmail = username.trim();
      if (!finalEmail.endsWith('@admin.com')) {
        finalEmail += '@admin.com';
      }
      
      await _auth.signInWithEmailAndPassword(email: finalEmail, password: password);
      
      // Si el login es exitoso, el listener _onAuthStateChanged se activará automáticamente
      // y se encargará de actualizar el estado de la aplicación.
      return true;

    } on FirebaseAuthException catch (e) {
      _formatErrorMessage(e); // Traduce el error de Firebase a un mensaje amigable.
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ocurrió un error inesperado.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Cierra la sesión del usuario actual.
  Future<void> logout() async {
    await _auth.signOut();
    // El listener _onAuthStateChanged se encargará de actualizar el estado a `unauthenticated`.
  }

  // Permite al usuario autenticado cambiar su contraseña.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay una sesión activa para realizar esta acción.');
      }

      // Por seguridad, Firebase requiere que el usuario se reautentique antes de cambiar la contraseña.
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      
      _status = AuthStatus.authenticated; // Vuelve al estado autenticado.
      notifyListeners();

    } on FirebaseAuthException catch (e) {
      _formatErrorMessage(e);
      _status = AuthStatus.authenticated;
      notifyListeners();
      rethrow; // Relanza la excepción para que la UI pueda manejarla (ej. mostrar un SnackBar).
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _status = AuthStatus.authenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Método privado para traducir los códigos de error de Firebase a mensajes entendibles.
  void _formatErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        _errorMessage = 'Correo o contraseña incorrectos.';
        break;
      case 'invalid-email':
        _errorMessage = 'El formato del correo no es válido.';
        break;
      case 'user-disabled':
        _errorMessage = 'Esta cuenta ha sido deshabilitada.';
        break;
      case 'too-many-requests':
        _errorMessage = 'Demasiados intentos. Inténtalo más tarde.';
        break;
      case 'network-request-failed':
        _errorMessage = 'Error de red. Verifica tu conexión a internet.';
        break;
      default:
        _errorMessage = 'Ocurrió un error de autenticación.';
    }
  }
}