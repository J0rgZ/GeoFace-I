// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Administradores
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo contiene la lógica de negocio para la gestión de
//               usuarios administradores del sistema. Se encarga de las
//               operaciones CRUD (Crear, Leer, Actualizar, Eliminar) para
//               administradores, interactuando con el servicio de administradores
//               y gestionando el estado de carga y errores para la UI.
//
// @NombreControlador: AdministradorController
// @Ubicacion:    lib/controllers/administrador_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/administrador_service.dart';

class AdministradorController with ChangeNotifier {
  final AdministradorService _adminService = AdministradorService();
  final bool _loading = false;

  // Getters
  bool get loading => _loading;
  
  
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- Método privado para gestionar el estado ---
  void _setState({bool loading = false, String? error}) {
    _isLoading = loading;
    _errorMessage = error;
    notifyListeners();
  }

  /// Obtiene una lista de administradores para ser usada en un FutureBuilder.
  /// No gestiona el estado de carga global, ya que el FutureBuilder lo hace por sí mismo.
  Future<List<Usuario>> getAdministradores() async {
    try {
      return await _adminService.getAdministradores();
    } catch (e) {
      // El FutureBuilder manejará este error en su snapshot.
      rethrow;
    }
  }

  /// Crea un nuevo usuario administrador.
  /// Devuelve true si tiene éxito, false si falla.
  Future<bool> createAdmin({
    required String nombreUsuario,
    required String correo,
    required String password,
  }) async {
    _setState(loading: true);
    try {
      await _adminService.createAdminUser(
        nombreUsuario: nombreUsuario,
        correo: correo,
        password: password,
      );
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }
  
  /// Actualiza el nombre de un usuario administrador.
  /// Devuelve true si tiene éxito, false si falla.
  Future<bool> updateAdmin({required String userId, required String nombreUsuario}) async {
    _setState(loading: true);
    try {
      await _adminService.updateAdminUser(userId: userId, nombreUsuario: nombreUsuario);
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }
  
  /// Cambia el estado 'activo' de un usuario.
  /// Devuelve true si tiene éxito, false si falla.
  Future<bool> toggleAdminStatus(Usuario user) async {
    _setState(loading: true);
    try {
      await _adminService.toggleUserStatus(userId: user.id, currentStatus: user.activo);
      _setState(loading: false);
      return true;
    } catch (e) {
      _setState(loading: false, error: e.toString().replaceFirst("Exception: ", ""));
      return false;
    }
  }
}