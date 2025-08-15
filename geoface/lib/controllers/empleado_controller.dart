import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart'; // Importa el servicio centralizado de Firebase.
import '../models/empleado.dart';

/// Controlador para gestionar la lógica de negocio relacionada con los empleados.
///
/// Centraliza las operaciones CRUD (Crear, Leer, Actualizar, Eliminar),
/// la validación de datos y la gestión de usuarios de Firebase Auth asociados
/// a los empleados. Utiliza `ChangeNotifier` para notificar a la UI sobre los cambios de estado.
class EmpleadoController extends ChangeNotifier {
  // --- INYECCIÓN DE SERVICIOS Y DEPENDENCIAS ---
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid(); // Para generar IDs únicos.
  
  // --- ESTADO INTERNO ---
  /// Lista local de empleados. Actúa como caché para evitar lecturas innecesarias a la BD.
  List<Empleado> _empleados = [];
  /// Indicador de carga para operaciones asíncronas.
  bool _loading = false;
  /// Mensaje de error si una operación falla.
  String? _errorMessage;

  // --- GETTERS PÚBLICOS ---
  /// Proporciona acceso de solo lectura a la lista de empleados.
  List<Empleado> get empleados => _empleados;
  /// Proporciona acceso de solo lectura al estado de carga.
  bool get loading => _loading;
  /// Proporciona acceso de solo lectura al mensaje de error.
  String? get errorMessage => _errorMessage;

  /// Método privado para centralizar la actualización del estado y la notificación a los listeners.
  /// Esto reduce la repetición de código en los otros métodos.
  void _setState({bool loading = false, String? error}) {
    _loading = loading;
    _errorMessage = error;
    notifyListeners(); // Notifica a los widgets que escuchan este controlador.
  }

  // ------------------------------------------------------------------
  // --- OBTENCIÓN DE DATOS ---
  // ------------------------------------------------------------------

  /// Carga la lista de todos los empleados desde Firebase y la almacena en el estado local `_empleados`.
  /// Este método es ideal para ser llamado una vez (ej. en `initState`) para poblar el estado del controlador.
  Future<void> getEmpleados() async {
    _setState(loading: true);
    try {
      _empleados = await _firebaseService.getEmpleados();
    } catch (e) {
      _errorMessage = 'Error al cargar empleados: ${e.toString()}';
    } finally {
      _setState(loading: false); // Se asegura de que el loading siempre se desactive.
    }
  }

  /// Obtiene y retorna la lista de empleados.
  /// A diferencia de `getEmpleados`, este método está diseñado para ser usado directamente
  /// en widgets como `FutureBuilder`, ya que retorna la lista o lanza una excepción.
  Future<List<Empleado>> fetchEmpleados() async {
    _setState(loading: true);
    try {
      _empleados = await _firebaseService.getEmpleados();
      _setState(loading: false);
      return _empleados; // Retorna la lista en caso de éxito.
    } catch (e) {
      final errorMsg = e.toString().replaceFirst("Exception: ", "");
      _setState(loading: false, error: errorMsg);
      throw Exception(errorMsg); // Lanza una excepción para que el FutureBuilder la maneje.
    }
  }

  /// Obtiene un único empleado por su ID.
  Future<Empleado?> getEmpleadoById(String id) async {
    try {
      return await _firebaseService.getEmpleadoById(id);
    } catch (e) {
      _errorMessage = 'Error al cargar empleado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  /// Obtiene una lista de empleados filtrados por el ID de su sede asignada.
  Future<List<Empleado>> getEmpleadosPorSede(String sedeId) async {
    _setState(loading: true);
    try {
      // Obtiene todos los empleados y luego filtra localmente.
      // Nota: Si la lista de empleados es muy grande, sería más eficiente
      // hacer un query a Firestore con un `where('sedeId', isEqualTo: sedeId)`.
      final todosEmpleados = await _firebaseService.getEmpleados();
      final empleadosSede = todosEmpleados.where((emp) => emp.sedeId == sedeId).toList();
      _setState(loading: false);
      return empleadosSede;
    } catch (e) {
      _setState(loading: false, error: 'Error al cargar empleados por sede: ${e.toString()}');
      return [];
    }
  }

  // ------------------------------------------------------------------
  // --- VALIDACIÓN ---
  // ------------------------------------------------------------------

  /// Valida si el DNI y el correo ya existen en la base de datos.
  ///
  /// @param dni El DNI a validar.
  /// @param correo El correo a validar.
  /// @param empleadoIdActual (Opcional) El ID del empleado que se está editando, para excluirlo de la validación.
  /// @returns Un Mapa donde la clave es el campo ('dni' o 'correo') y el valor es el mensaje de error.
  /// Si no hay errores, el mapa estará vacío.
  Future<Map<String, String?>> validarDatosUnicos({
    required String dni,
    required String correo,
    String? empleadoIdActual,
  }) async {
    Map<String, String?> errores = {};
    // Si la lista local de empleados está vacía, la carga primero.
    if (_empleados.isEmpty) {
      await getEmpleados();
    }
    
    // Verifica si algún otro empleado (diferente al que se está editando) ya tiene ese DNI.
    if (_empleados.any((e) => e.dni == dni && e.id != empleadoIdActual)) {
      errores['dni'] = 'Ya existe un empleado con este DNI';
    }
    
    // Verifica si algún otro empleado ya tiene ese correo.
    if (_empleados.any((e) => e.correo == correo && e.id != empleadoIdActual)) {
      errores['correo'] = 'Ya existe un empleado con este correo';
    }
    
    return errores;
  }

  // ------------------------------------------------------------------
  // --- OPERACIONES CRUD DE EMPLEADOS ---
  // ------------------------------------------------------------------

  /// Añade un nuevo empleado a la base de datos.
  ///
  /// Realiza una validación de datos únicos antes de crear el registro.
  /// @returns `true` si se creó con éxito, `false` si hubo un error.
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
      // Primero valida que el DNI y el correo no estén ya en uso.
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
      await getEmpleados(); // Refresca la lista local.
      _setState(loading: false); // Se pone aquí para que el estado de error se limpie
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }
  
  /// Actualiza los datos de un empleado existente.
  ///
  /// @returns `true` si la actualización fue exitosa, `false` si no.
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
      
      // Valida datos únicos, excluyendo al propio empleado de la comprobación.
      final errores = await validarDatosUnicos(dni: dni, correo: correo, empleadoIdActual: id);
      if (errores.isNotEmpty) {
        throw Exception(errores.values.where((e) => e != null).join('. '));
      }
      
      // Usa el método `copyWith` para crear una nueva instancia con los datos actualizados.
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
      await getEmpleados(); // Refresca la lista local.
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  /// Elimina un empleado de la base de datos por su ID.
  Future<bool> deleteEmpleado(String id) async {
    _setState(loading: true);
    try {
      await _firebaseService.deleteEmpleado(id);
      await getEmpleados(); // Refresca la lista local.
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: 'Error al eliminar empleado: ${e.toString()}');
      return false;
    }
  }

  /// Cambia el estado de un empleado entre 'activo' e 'inactivo'.
  Future<bool> toggleEmpleadoActivo(Empleado empleado) async {
    _setState(loading: true);
    try {
      final empleadoActualizado = empleado.copyWith(
        activo: !empleado.activo, // Invierte el valor booleano.
        fechaModificacion: DateTime.now(),
      );
      await _firebaseService.updateEmpleado(empleadoActualizado);
      
      await getEmpleados(); // Refresca la lista para que la UI muestre el cambio.
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: 'Error al cambiar estado del empleado: ${e.toString()}');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // --- GESTIÓN DE USUARIOS DE EMPLEADOS (FIREBASE AUTH) ---
  // ------------------------------------------------------------------

  /// Crea una cuenta de usuario en Firebase Auth para un empleado y la vincula.
  ///
  /// Utiliza una convención para el email (`dni@geoface.com`) y la contraseña inicial (DNI).
  /// También crea un documento en la colección 'usuarios' para gestionar roles y datos adicionales.
  Future<bool> assignUserToEmpleado({required Empleado empleado}) async {
    _setState(loading: true);
    try {
      final correo = '${empleado.dni}@geoface.com';
      final password = empleado.dni;
      
      // 1. Crea el usuario en Firebase Authentication.
      final userCredential = await _auth.createUserWithEmailAndPassword(email: correo, password: password);
      
      // 2. Crea el documento correspondiente en la colección 'usuarios' de Firestore.
      final usuarioData = {
        'nombreUsuario': empleado.nombre,
        'correo': correo,
        'tipoUsuario': 'EMPLEADO', // Asigna el rol.
        'empleadoId': empleado.id,  // Vincula al documento del empleado.
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set(usuarioData);

      // 3. Actualiza el flag 'tieneUsuario' en el documento del empleado.
      final empleadoActualizado = empleado.copyWith(tieneUsuario: true);
      await _firebaseService.updateEmpleado(empleadoActualizado);

      _setState(loading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos de Firebase Auth.
      final errorMsg = (e.code == 'email-already-in-use') ? 'Ya existe un usuario con este DNI.' : 'Error de autenticación: ${e.message}';
      _setState(loading: false, error: errorMsg);
      return false;
    } catch (e) {
      _setState(loading: false, error: 'Error inesperado: ${e.toString()}');
      return false;
    }
  }

  /// Inicia el flujo de restablecimiento de contraseña para un empleado.
  /// Envía un correo electrónico al usuario para que pueda crear una nueva contraseña.
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