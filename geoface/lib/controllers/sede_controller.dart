import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../models/sede.dart';

/// Gestiona el estado y la lógica de negocio para las Sedes.
///
/// Esta clase utiliza el patrón `ChangeNotifier` para notificar a los widgets
/// que la escuchan sobre cualquier cambio en el estado (como la carga de datos,
/// la finalización de una operación o la aparición de un error).
/// Funciona como un intermediario entre la UI y el servicio de datos (`FirebaseService`).
class SedeController extends ChangeNotifier {
  // Instancia del servicio que se comunica directamente con Firebase.
  // La lógica de la base de datos está encapsulada en esta clase.
  final FirebaseService _firebaseService = FirebaseService();
  
  // Utilidad para generar identificadores únicos universales (UUID v4).
  // Se usa para asignar un ID único a cada nueva sede.
  final Uuid _uuid = Uuid();
  
  // --- ESTADO INTERNO DE LA CLASE ---
  // Se utilizan propiedades privadas para encapsular el estado.

  /// Lista de sedes obtenidas desde Firebase.
  List<Sede> _sedes = [];

  /// Indicador de si hay una operación en curso (ej: cargando datos).
  bool _loading = false;

  /// Mensaje de error en caso de que falle alguna operación.
  String? _errorMessage;


  // --- GETTERS PÚBLICOS ---
  // Proporcionan acceso de solo lectura al estado interno desde la UI.
  // Esto previene modificaciones accidentales del estado desde fuera del controlador.

  /// Devuelve la lista actual de sedes.
  List<Sede> get sedes => _sedes;

  /// Devuelve `true` si hay una operación en curso.
  bool get loading => _loading;

  /// Devuelve el último mensaje de error, o `null` si no hay error.
  String? get errorMessage => _errorMessage;

  /// Obtiene todas las sedes desde Firebase y actualiza el estado.
  Future<void> getSedes() async {
    // 1. Inicia el estado de carga.
    _loading = true;
    _errorMessage = null; // Limpia cualquier error anterior.
    notifyListeners(); // Notifica a la UI que el estado ha cambiado (para mostrar un spinner, por ejemplo).
    
    try {
      // 2. Ejecuta la operación asíncrona para obtener los datos.
      _sedes = await _firebaseService.getSedes();
    } catch (e) {
      // 3. Si ocurre un error, se captura y se guarda el mensaje.
      _errorMessage = 'Error al cargar sedes: ${e.toString()}';
    } finally {
      // 4. Se ejecuta siempre, haya error o no.
      _loading = false; // Finaliza el estado de carga.
      notifyListeners(); // Notifica a la UI que la operación ha terminado.
    }
  }

  /// Agrega una nueva sede a la base de datos.
  ///
  /// Devuelve `true` si la operación fue exitosa, de lo contrario `false`.
  Future<bool> addSede({
    required String nombre, 
    required String direccion, 
    required double latitud, 
    required double longitud, 
    required int radioPermitido
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Crea una instancia del modelo Sede con los datos proporcionados.
      final sede = Sede(
        id: _uuid.v4(), // Genera un ID único para la nueva sede.
        nombre: nombre,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        radioPermitido: radioPermitido,
        activa: true, // Por defecto, una nueva sede se crea como activa.
        fechaCreacion: DateTime.now(),
      );
      
      // Llama al servicio para persistir la nueva sede.
      await _firebaseService.addSede(sede);
      
      // Refresca la lista local de sedes para reflejar el cambio.
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar sede: ${e.toString()}';
      _loading = false; // Asegura que el estado de carga se desactive en caso de error.
      notifyListeners();
      return false;
    }
  }

  /// Actualiza los datos de una sede existente.
  ///
  /// Devuelve `true` si la actualización fue exitosa, de lo contrario `false`.
  Future<bool> updateSede({
    required String id,
    required String nombre, 
    required String direccion, 
    required double latitud, 
    required double longitud, 
    required int radioPermitido,
    required bool activa
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Es una buena práctica obtener el objeto actual antes de modificarlo.
      final sedeActual = await _firebaseService.getSedeById(id);
      
      if (sedeActual == null) {
        // Si la sede no existe, no se puede actualizar.
        throw Exception('Sede no encontrada con el id: $id');
      }
      
      // Utiliza el método `copyWith` del modelo para crear una copia actualizada.
      // Esto es útil para trabajar con objetos inmutables.
      final sedeActualizada = sedeActual.copyWith(
        nombre: nombre,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        radioPermitido: radioPermitido,
        activa: activa,
        // La fecha de modificación se actualiza automáticamente por `copyWith`.
      );
      
      // Llama al servicio para guardar los cambios en la base de datos.
      await _firebaseService.updateSede(sedeActualizada);
      
      // Refresca la lista de sedes para que la UI muestre los nuevos datos.
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Elimina una sede de la base de datos usando su ID.
  ///
  /// Devuelve `true` si la eliminación fue exitosa, de lo contrario `false`.
  Future<bool> deleteSede(String id) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Llama al servicio para realizar la eliminación.
      await _firebaseService.deleteSede(id);
      
      // Refresca la lista de sedes para quitar el elemento eliminado de la UI.
      await getSedes();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar sede: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}