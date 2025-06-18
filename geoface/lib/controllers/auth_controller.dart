// FILE: lib/controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthController with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.initial;
  Usuario? _currentUser;
  String? _errorMessage;
  
  // Getters públicos para que la UI reaccione a los cambios
  AuthStatus get status => _status;
  Usuario? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isEmpleado => _currentUser?.isEmpleado ?? false;
  bool get loading => _status == AuthStatus.loading;

  AuthController() {
    // Escucha los cambios de estado de autenticación de Firebase en tiempo real.
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Escucha los cambios y actualiza el estado de la app.
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } else {
      await _fetchUserData(firebaseUser.uid);
    }
    notifyListeners();
  }
  
  /// Busca los datos del usuario en Firestore y actualiza el estado.
  Future<void> _fetchUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('usuarios').doc(uid).get();
      if (userDoc.exists) {
        final usuario = Usuario.fromJson({'id': userDoc.id, ...userDoc.data()!});
        if (usuario.activo) {
          _currentUser = usuario;
          _status = AuthStatus.authenticated;
        } else {
          await _auth.signOut();
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
          _errorMessage = 'Tu cuenta ha sido desactivada. Contacta al administrador.';
        }
      } else {
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

  // --- NUEVO MÉTODO AÑADIDO ---
  /// Permite a la UI establecer un mensaje de error personalizado.
  /// Útil para errores de validación en la UI antes de llamar a la lógica de negocio.
  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Inicia sesión con correo y contraseña.
  /// El formato del correo debe ser preparado por la UI antes de llamar a este método.
   Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    setErrorMessage(null);
    notifyListeners();

    try {
      String finalEmail = username.trim();
      if (!finalEmail.endsWith('@admin.com')) {
        finalEmail += '@admin.com';
      }
      // ==============================
      
      // Usa el correo formateado para iniciar sesión.
      await _auth.signInWithEmailAndPassword(email: finalEmail, password: password);
      
      // El listener _onAuthStateChanged se encargará del resto (verificar si está activo, etc.).
      return true;

    } on FirebaseAuthException catch (e) {
      _formatErrorMessage(e);
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

  /// Cierra la sesión del usuario actual.
  Future<void> logout() async {
    await _auth.signOut();
    // El listener _onAuthStateChanged se encargará de actualizar el estado.
  }

  /// Permite a cualquier usuario autenticado cambiar su contraseña.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay una sesión activa para realizar esta acción.');
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      
      _status = AuthStatus.authenticated;
      notifyListeners();

    } on FirebaseAuthException catch (e) {
      _formatErrorMessage(e);
      _status = AuthStatus.authenticated;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _status = AuthStatus.authenticated;
      notifyListeners();
      rethrow;
    }
  }

  /// Formatea los errores de FirebaseAuth a mensajes amigables.
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