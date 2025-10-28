// -----------------------------------------------------------------------------
// @Encabezado:   Utilidades de Validación
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la clase `Validators`, que contiene métodos
//               estáticos para validar diferentes tipos de datos de entrada en
//               formularios. Incluye validaciones para campos requeridos,
//               formato de correo electrónico y contraseñas. Proporciona
//               mensajes de error en español para una mejor experiencia de usuario.
//
// @NombreArchivo: validators.dart
// @Ubicacion:    lib/utils/validators.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Ingrese un correo electrónico válido';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }
}