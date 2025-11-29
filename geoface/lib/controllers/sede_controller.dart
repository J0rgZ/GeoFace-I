// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Sedes
// @Autor:        Brayar Lopez Catunta
// @Descripción:  Este archivo contiene la lógica de negocio para la gestión de
//               las sedes de la empresa. Se encarga de las operaciones CRUD
//               (Crear, Leer, Actualizar, Eliminar) interactuando con el
//               `SedeService` y gestiona el estado de la UI (carga y errores)
//               relacionado con estas operaciones.
//
// @NombreControlador: SedeController
// @Ubicacion:    lib/controllers/sede_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/06/2025
// /2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/sede_service.dart';
import '../services/auditoria_service.dart';
import '../services/device_info_service.dart';
import '../models/sede.dart';
import '../models/auditoria.dart';

class SedeController extends ChangeNotifier {
  
  final SedeService _sedeService = SedeService();
  final AuditoriaService _auditoriaService = AuditoriaService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final Uuid _uuid = Uuid();
  

  // Estado interno del controlador.
  List<Sede> _sedes = [];
  bool _loading = false;
  String? _errorMessage;

  // Getters públicos para que la UI acceda al estado de forma segura.
  List<Sede> get sedes => _sedes;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  // Obtiene todas las sedes desde Firebase y actualiza el estado local.
  Future<void> getSedes() async {
    // 1. Inicia el estado de carga y limpia errores previos.
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 2. Llama al servicio para obtener los datos.
      _sedes = await _sedeService.getSedes();
    } catch (e) {
      // 3. Si algo sale mal, se captura el error.
      _errorMessage = 'Error al cargar sedes: ${e.toString()}';
    } finally {
      // 4. Se ejecuta siempre al final, para asegurar que el estado de carga se desactive.
      _loading = false;
      notifyListeners();
    }
  }

  // Agrega una nueva sede a la base de datos.
  // Devuelve `true` si la operación fue exitosa, de lo contrario `false`.
  Future<bool> addSede({
    required String nombre, 
    required String direccion, 
    required double latitud, 
    required double longitud, 
    required int radioPermitido,
    String? usuarioId,
    String? usuarioNombre,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Se crea el objeto Sede con los datos del formulario.
      final sede = Sede(
        id: _uuid.v4(), // Se genera un ID único para el nuevo documento.
        nombre: nombre,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        radioPermitido: radioPermitido,
        activa: true, // Por defecto, una nueva sede siempre está activa.
        fechaCreacion: DateTime.now(),
      );
      
      await _sedeService.addSede(sede);
      
      // Registrar auditoría si se proporciona información del usuario
      if (usuarioId != null && usuarioNombre != null) {
        await _registrarAuditoriaSede(
          usuarioId,
          usuarioNombre,
          TipoAccion.crearSede,
          sede.id,
          sede.nombre,
          'Sede creada: ${sede.nombre}',
        );
      }
      
      // Se refresca la lista local para que la UI muestre la nueva sede inmediatamente.
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar sede: ${e.toString()}';
      _loading = false; // Importante desactivar la carga en caso de error.
      notifyListeners();
      return false;
    }
  }

  // Actualiza los datos de una sede existente.
  Future<bool> updateSede({
    required String id,
    required String nombre, 
    required String direccion, 
    required double latitud, 
    required double longitud, 
    required int radioPermitido,
    required bool activa,
    String? usuarioId,
    String? usuarioNombre,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Primero, obtenemos la sede actual para usar `copyWith`.
      final sedeActual = await _sedeService.getSedeById(id);
      
      if (sedeActual == null) {
        throw Exception('Sede no encontrada con el id: $id');
      }
      
      // Usamos `copyWith` para crear una nueva instancia con los datos actualizados.
      // Esto también actualiza la fecha de modificación automáticamente.
      final sedeActualizada = sedeActual.copyWith(
        nombre: nombre,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        radioPermitido: radioPermitido,
        activa: activa,
      );
      
      await _sedeService.updateSede(sedeActualizada);
      
      // Registrar auditoría si se proporciona información del usuario
      if (usuarioId != null && usuarioNombre != null) {
        await _registrarAuditoriaSede(
          usuarioId,
          usuarioNombre,
          TipoAccion.editarSede,
          sedeActualizada.id,
          sedeActualizada.nombre,
          'Sede editada: ${sedeActualizada.nombre}',
        );
      }
      
      // Refrescamos la lista para reflejar los cambios en la UI.
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Elimina una sede de la base de datos usando su ID.
  Future<bool> deleteSede(String id, {String? usuarioId, String? usuarioNombre}) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Obtener información de la sede antes de eliminarla
      final sede = await _sedeService.getSedeById(id);
      final nombreSede = sede?.nombre ?? 'Sede desconocida';
      
      await _sedeService.deleteSede(id);
      
      // Registrar auditoría si se proporciona información del usuario
      if (usuarioId != null && usuarioNombre != null) {
        await _registrarAuditoriaSede(
          usuarioId,
          usuarioNombre,
          TipoAccion.eliminarSede,
          id,
          nombreSede,
          'Sede eliminada: $nombreSede',
        );
      }
      
      // Refrescamos la lista para que el elemento eliminado desaparezca de la UI.
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Método auxiliar para registrar auditoría de sedes
  Future<void> _registrarAuditoriaSede(
    String usuarioId,
    String usuarioNombre,
    TipoAccion tipoAccion,
    String sedeId,
    String sedeNombre,
    String descripcion,
  ) async {
    try {
      final dispositivoInfo = await _deviceInfoService.obtenerInformacionDispositivo();
      
      await _auditoriaService.registrarAuditoria(
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        tipoAccion: tipoAccion,
        tipoEntidad: TipoEntidad.sede,
        entidadId: sedeId,
        entidadNombre: sedeNombre,
        descripcion: descripcion,
        dispositivoId: dispositivoInfo.id,
        dispositivoMarca: dispositivoInfo.marca,
        dispositivoModelo: dispositivoInfo.modelo,
      );
    } catch (e) {
      // No fallar si no se puede registrar auditoría
    }
  }
}