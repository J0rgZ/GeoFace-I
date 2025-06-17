import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart'; // Tu servicio centralizado
import '../models/empleado.dart';

class EmpleadoController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  
  List<Empleado> _empleados = [];
  bool _loading = false;
  String? _errorMessage;

  List<Empleado> get empleados => _empleados;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  void _setState({bool loading = false, String? error}) {
    _loading = loading;
    _errorMessage = error;
    notifyListeners();
  }

  // --- OBTENCIÓN DE DATOS ---

  /// MÉTODO ANTIGUO: Mantenido para compatibilidad con otras vistas.
  Future<void> getEmpleados() async {
    _setState(loading: true);
    try {
      _empleados = await _firebaseService.getEmpleados();
    } catch (e) {
      _errorMessage = 'Error al cargar empleados: ${e.toString()}';
    } finally {
      _setState(loading: false);
    }
  }

  /// NUEVO MÉTODO: Para ser usado por FutureBuilder en nuevas vistas.
  Future<List<Empleado>> fetchEmpleados() async {
    _setState(loading: true);
    try {
      _empleados = await _firebaseService.getEmpleados();
      _setState(loading: false);
      return _empleados;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst("Exception: ", "");
      _setState(loading: false, error: errorMsg);
      throw Exception(errorMsg);
    }
  }

  Future<Empleado?> getEmpleadoById(String id) async {
    try {
      return await _firebaseService.getEmpleadoById(id);
    } catch (e) {
      _errorMessage = 'Error al cargar empleado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  Future<List<Empleado>> getEmpleadosPorSede(String sedeId) async {
    _setState(loading: true);
    try {
      final todosEmpleados = await _firebaseService.getEmpleados();
      final empleadosSede = todosEmpleados.where((emp) => emp.sedeId == sedeId).toList();
      _setState(loading: false);
      return empleadosSede;
    } catch (e) {
      _setState(loading: false, error: 'Error al cargar empleados por sede: ${e.toString()}');
      return [];
    }
  }

  // --- VALIDACIÓN ---

  Future<Map<String, String?>> validarDatosUnicos({
    required String dni,
    required String correo,
    String? empleadoIdActual,
  }) async {
    Map<String, String?> errores = {};
    if (_empleados.isEmpty) {
      await getEmpleados();
    }
    
    if (_empleados.any((e) => e.dni == dni && e.id != empleadoIdActual)) {
      errores['dni'] = 'Ya existe un empleado con este DNI';
    }
    
    if (_empleados.any((e) => e.correo == correo && e.id != empleadoIdActual)) {
      errores['correo'] = 'Ya existe un empleado con este correo';
    }
    
    return errores;
  }

  // --- CRUD DE EMPLEADOS ---

  Future<bool> addEmpleado({
    required String nombre,
    required String apellidos,
    required String dni,
    required String celular,
    required String correo,
    required String cargo,
    required String sedeId,
  }) async {
    _setState(loading: true);
    try {
      final errores = await validarDatosUnicos(dni: dni, correo: correo);
      if (errores.isNotEmpty) {
        throw Exception(errores.values.where((e) => e != null).join('. '));
      }
      
      final empleado = Empleado(
        id: _uuid.v4(),
        nombre: nombre,
        apellidos: apellidos,
        dni: dni,
        celular: celular,
        correo: correo,
        cargo: cargo,
        sedeId: sedeId,
        fechaCreacion: DateTime.now(),
      );
      
      await _firebaseService.addEmpleado(empleado);
      await getEmpleados();
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }
  
  Future<bool> updateEmpleado({
    required String id,
    required String nombre,
    required String apellidos,
    required String dni,
    required String celular,
    required String correo,
    required String cargo,
    required String sedeId,
    required bool activo,
  }) async {
    _setState(loading: true);
    try {
      final empleadoActual = await _firebaseService.getEmpleadoById(id);
      if (empleadoActual == null) throw Exception("No se encontró el empleado a actualizar.");
      
      final errores = await validarDatosUnicos(dni: dni, correo: correo, empleadoIdActual: id);
      if (errores.isNotEmpty) {
        throw Exception(errores.values.where((e) => e != null).join('. '));
      }
      
      final empleadoActualizado = empleadoActual.copyWith(
        nombre: nombre,
        apellidos: apellidos,
        dni: dni,
        celular: celular,
        correo: correo,
        cargo: cargo,
        sedeId: sedeId,
        activo: activo,
        fechaModificacion: DateTime.now(),
      );
      
      await _firebaseService.updateEmpleado(empleadoActualizado);
      await getEmpleados();
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<bool> deleteEmpleado(String id) async {
    _setState(loading: true);
    try {
      await _firebaseService.deleteEmpleado(id);
      await getEmpleados();
      return true;
    } catch (e) {
      _setState(loading: false, error: 'Error al eliminar empleado: ${e.toString()}');
      return false;
    }
  }

  // --- MÉTODO RESTAURADO ---
  /// Cambia el estado de 'activo' a 'inactivo' y viceversa para un empleado.
  Future<bool> toggleEmpleadoActivo(Empleado empleado) async {
    _setState(loading: true);
    try {
      // Crea una copia del empleado con el estado 'activo' invertido.
      final empleadoActualizado = empleado.copyWith(
        activo: !empleado.activo,
        fechaModificacion: DateTime.now(),
      );
      // Llama al servicio para actualizar el documento en Firestore.
      await _firebaseService.updateEmpleado(empleadoActualizado);
      
      // Actualiza la lista local para que la UI refleje el cambio inmediatamente.
      await getEmpleados();
      
      return true;
    } catch (e) {
      _setState(loading: false, error: 'Error al cambiar estado del empleado: ${e.toString()}');
      return false;
    }
  }

  // --- GESTIÓN DE USUARIOS DE EMPLEADOS ---

  Future<bool> assignUserToEmpleado({required Empleado empleado}) async {
    _setState(loading: true);
    try {
      final correo = '${empleado.dni}@geoface.com';
      final password = empleado.dni;
      
      final userCredential = await _auth.createUserWithEmailAndPassword(email: correo, password: password);
      
      final usuarioData = {
        'nombreUsuario': empleado.nombre,
        'correo': correo,
        'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleado.id,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set(usuarioData);

      final empleadoActualizado = empleado.copyWith(tieneUsuario: true);
      await _firebaseService.updateEmpleado(empleadoActualizado);

      _setState(loading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      final errorMsg = (e.code == 'email-already-in-use') ? 'Ya existe un usuario con este DNI.' : 'Error de autenticación: ${e.message}';
      _setState(loading: false, error: errorMsg);
      return false;
    } catch (e) {
      _setState(loading: false, error: 'Error inesperado: ${e.toString()}');
      return false;
    }
  }

  Future<bool> resetEmpleadoPassword({required Empleado empleado}) async {
    _setState(loading: true);
    try {
      final correo = '${empleado.dni}@geoface.com';
      await _firebaseService.sendPasswordResetEmail(correo);
      _setState(loading: false);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst("Exception: ", "");
      _setState(loading: false, error: errorMsg);
      return false;
    }
  }
}