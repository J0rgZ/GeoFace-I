// -----------------------------------------------------------------------------
// @Encabezado:   Servicio de Usuarios
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `UsuarioService`, que actúa como
//               una capa de servicio para todas las operaciones relacionadas con
//               usuarios en Firebase. Centraliza las operaciones de lectura con
//               Cloud Firestore para la colección de usuarios, desacoplando la
//               lógica de la base de datos de los controladores y la interfaz de
//               usuario. Este enfoque mejora la mantenibilidad y la organización
//               del código.
//
// @NombreArchivo: usuario_service.dart
// @Ubicacion:    lib/services/usuario_service.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';

/// Clase de servicio para gestionar todas las operaciones relacionadas con usuarios.
///
/// Centraliza las operaciones de Firestore para la colección de usuarios,
/// manteniendo el código organizado y desacoplado de la lógica de la interfaz.
class UsuarioService {
  // Instancia de Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene un documento de usuario de la colección 'usuarios' basado en su email.
  ///
  /// @param email El correo electrónico a buscar.
  /// @returns Un [Future] que completa con el objeto [Usuario] si se encuentra, de lo contrario, `null`.
  /// @throws Lanza una excepción si ocurre un error durante la consulta a Firestore.
  Future<Usuario?> getUsuarioByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        // Combina el ID del documento con sus datos para crear el objeto Usuario.
        return Usuario.fromJson({
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener usuario por email: $e');
      rethrow; // Relanza la excepción para que sea manejada por el llamador.
    }
  }
}

