// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Empleados
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo contiene la lógica de negocio para la gestión
//               completa de los empleados. Se encarga de las operaciones CRUD,
//               validaciones de datos únicos (DNI, correo), y la asignación
//               y gestión de cuentas de usuario en Firebase Authentication.
//
// @NombreControlador: EmpleadoController
// @Ubicacion:    lib/controllers/empleado_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/empleado_service.dart';
import '../services/auditoria_service.dart';
import '../services/device_info_service.dart';
import '../models/empleado.dart';
import '../models/auditoria.dart';


class EmpleadoController extends ChangeNotifier {
  final EmpleadoService _empleadoService = EmpleadoService();
  final AuditoriaService _auditoriaService = AuditoriaService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  
  // Obtener AuthController desde el contexto cuando sea necesario
  // Se accede mediante Provider en los métodos que lo necesiten
  
  // Estado interno del controlador.
  List<Empleado> _empleados = [];
  bool _loading = false;
  String? _errorMessage;

  // --- GETTERS PÚBLICOS ---
  // Proporcionan acceso de solo lectura al estado desde la UI.
  List<Empleado> get empleados => _empleados;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  // Método privado para centralizar la gestión del estado y reducir código repetido.
  void _setState({bool loading = false, String? error}) {
    _loading = loading;
    _errorMessage = error;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // --- OBTENCIÓN DE DATOS ---
  // ------------------------------------------------------------------

  // Carga la lista de todos los empleados y la guarda en el estado local.
  // Ideal para ser llamado una vez al iniciar una pantalla para tener los datos disponibles.
  Future<void> getEmpleados() async {
    _setState(loading: true);
    try {
      _empleados = await _empleadoService.getEmpleados();
    } catch (e) {
      _errorMessage = 'Error al cargar empleados: ${e.toString()}';
    } finally {
      _setState(loading: false);
    }
  }

  // Obtiene y retorna la lista de empleados.
  // Diseñado para ser usado con widgets como `FutureBuilder` que manejan el ciclo de vida del Future.
  Future<List<Empleado>> fetchEmpleados() async {
    _setState(loading: true);
    try {
      _empleados = await _empleadoService.getEmpleados();
      _setState(loading: false);
      return _empleados;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst("Exception: ", "");
      _setState(loading: false, error: errorMsg);
      // Relanza la excepción para que el FutureBuilder la capture en su snapshot.error.
      throw Exception(errorMsg);
    }
  }

  // Obtiene un único empleado por su ID.
  Future<Empleado?> getEmpleadoById(String id) async {
    try {
      return await _empleadoService.getEmpleadoById(id);
    } catch (e) {
      _errorMessage = 'Error al cargar empleado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
  
  // Obtiene una lista de empleados filtrados por el ID de su sede.
  Future<List<Empleado>> getEmpleadosPorSede(String sedeId) async {
    _setState(loading: true);
    try {
      // Nota: Si la cantidad de empleados es muy grande, sería más eficiente
      // hacer una consulta directa a Firestore con un `where`.
      final todosEmpleados = await _empleadoService.getEmpleados();
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
  // Verifica si el DNI o correo ya existen en la base de datos, excluyendo al empleado actual (en caso de edición).
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

  // ------------------------------------------------------------------
  // --- OPERACIONES CRUD DE EMPLEADOS ---
  // ------------------------------------------------------------------

  Future<bool> addEmpleado({
    required String nombre,
    required String apellidos,
    required String dni,
    required String celular,
    required String correo,
    required String cargo,
    required String sedeId,
    String? usuarioId,
    String? usuarioNombre,
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
      
      await _empleadoService.addEmpleado(empleado);
      await getEmpleados(); // Refresca la lista local.
      
      // Registrar auditoría si se proporciona información del usuario
      if (usuarioId != null && usuarioNombre != null) {
        await _registrarAuditoriaEmpleado(
          usuarioId,
          usuarioNombre,
          TipoAccion.crearEmpleado,
          empleado.id,
          empleado.nombreCompleto,
          'Empleado creado: ${empleado.nombreCompleto}',
        );
      }
      
      _setState(loading: false);
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
    String? usuarioId,
    String? usuarioNombre,
  }) async {
    _setState(loading: true);
    try {
      final empleadoActual = await _empleadoService.getEmpleadoById(id);
      if (empleadoActual == null) throw Exception("No se encontró el empleado a actualizar.");
      
      final errores = await validarDatosUnicos(dni: dni, correo: correo, empleadoIdActual: id);
      if (errores.isNotEmpty) {
        throw Exception(errores.values.where((e) => e != null).join('. '));
      }
      
      // Se usa `copyWith` para mantener los datos que no cambian (como fechaCreacion).
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
      
      await _empleadoService.updateEmpleado(empleadoActualizado);
      await getEmpleados();
      
      // Registrar auditoría si se proporciona información del usuario
      if (usuarioId != null && usuarioNombre != null) {
        await _registrarAuditoriaEmpleado(
          usuarioId,
          usuarioNombre,
          TipoAccion.editarEmpleado,
          empleadoActualizado.id,
          empleadoActualizado.nombreCompleto,
          'Empleado editado: ${empleadoActualizado.nombreCompleto}',
        );
      }
      
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }

  Future<bool> deleteEmpleado(String id, {String? usuarioId, String? usuarioNombre}) async {
    _setState(loading: true);
    try {
      // Obtener información del empleado antes de eliminarlo
      final empleado = await _empleadoService.getEmpleadoById(id);
      final nombreEmpleado = empleado?.nombreCompleto ?? 'Empleado desconocido';
      
      await _empleadoService.deleteEmpleado(id);
      await getEmpleados();
      
      // Registrar auditoría si se proporciona información del usuario
      if (usuarioId != null && usuarioNombre != null) {
        await _registrarAuditoriaEmpleado(
          usuarioId,
          usuarioNombre,
          TipoAccion.eliminarEmpleado,
          id,
          nombreEmpleado,
          'Empleado eliminado: $nombreEmpleado',
        );
      }
      
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: 'Error al eliminar empleado: ${e.toString()}');
      return false;
    }
  }
  
  // Método auxiliar para registrar auditoría de empleados
  Future<void> _registrarAuditoriaEmpleado(
    String usuarioId,
    String usuarioNombre,
    TipoAccion tipoAccion,
    String empleadoId,
    String empleadoNombre,
    String descripcion,
  ) async {
    try {
      final dispositivoInfo = await _deviceInfoService.obtenerInformacionDispositivo();
      
      await _auditoriaService.registrarAuditoria(
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        tipoAccion: tipoAccion,
        tipoEntidad: TipoEntidad.empleado,
        entidadId: empleadoId,
        entidadNombre: empleadoNombre,
        descripcion: descripcion,
        dispositivoId: dispositivoInfo.id,
        dispositivoMarca: dispositivoInfo.marca,
        dispositivoModelo: dispositivoInfo.modelo,
      );
    } catch (e) {
      // No fallar si no se puede registrar auditoría
    }
  }

  Future<bool> toggleEmpleadoActivo(Empleado empleado) async {
    _setState(loading: true);
    try {
      final empleadoActualizado = empleado.copyWith(
        activo: !empleado.activo, // Invierte el estado actual.
        fechaModificacion: DateTime.now(),
      );
      await _empleadoService.updateEmpleado(empleadoActualizado);
      
      await getEmpleados();
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: 'Error al cambiar estado del empleado: ${e.toString()}');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // --- GESTIÓN DE USUARIOS DE EMPLEADOS ---
  // ------------------------------------------------------------------

  Future<bool> assignUserToEmpleado({required Empleado empleado}) async {
    _setState(loading: true);
    try {
      final correo = '${empleado.dni}@geoface.com';
      final password = empleado.dni;
      
      // 1. Crea el usuario en Firebase Authentication.
      // IMPORTANTE: Firebase Auth automáticamente inicia sesión con el nuevo usuario.
      // Esto es un problema de seguridad si el admin está creando usuarios.
      final userCredential = await _auth.createUserWithEmailAndPassword(email: correo, password: password);
      final nuevoUsuarioId = userCredential.user!.uid;
      
      // 2. Crea el documento en la colección 'usuarios' de Firestore.
      final usuarioData = {
        'nombreUsuario': empleado.nombre,
        'correo': correo,
        'tipoUsuario': 'EMPLEADO',
        'empleadoId': empleado.id,
        'activo': true,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'debeCambiarContrasena': true, // Marca que debe cambiar contraseña al primer acceso
      };
      await _firestore.collection('usuarios').doc(nuevoUsuarioId).set(usuarioData);

      // 3. Actualiza el flag 'tieneUsuario' en el documento del empleado.
      final empleadoActualizado = empleado.copyWith(tieneUsuario: true);
      await _empleadoService.updateEmpleado(empleadoActualizado);

      // 4. SEGURIDAD CRÍTICA: Cerrar sesión del empleado recién creado.
      // Después de crear el usuario, Firebase Auth automáticamente inicia sesión como ese empleado.
      // Esto es un problema de seguridad porque el admin quedaría autenticado como empleado.
      // Al cerrar sesión, el admin deberá volver a iniciar sesión para continuar trabajando.
      await _auth.signOut();
      
      // NOTA: No es posible restaurar automáticamente la sesión del admin sin su contraseña.
      // El admin debe volver a iniciar sesión después de crear usuarios.

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

}