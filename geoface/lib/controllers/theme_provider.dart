// -----------------------------------------------------------------------------
// @Encabezado:   Proveedor de Tema de la Aplicación
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define el `ThemeProvider`, un controlador que
//               gestiona el cambio entre el tema claro y oscuro de la aplicación.
//               Utiliza `SharedPreferences` para persistir la elección del
//               usuario entre sesiones y notifica a los widgets de la interfaz
//               cuando el tema cambia para que se reconstruyan con los nuevos
//               colores y estilos.
//
// @NombreControlador: ThemeProvider
// @Ubicacion:    lib/providers/theme_provider.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:geoface/themes/app_theme.dart'; // Asegúrate que la ruta sea correcta.
import 'package:shared_preferences/shared_preferences.dart';

// Controlador para manejar el estado del tema (claro/oscuro).
class ThemeProvider with ChangeNotifier {
  // Variable interna que almacena el estado actual del tema.
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // El constructor se encarga de cargar la preferencia guardada apenas se crea la instancia.
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Carga el estado del tema desde el almacenamiento local del dispositivo.
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Si no hay ninguna preferencia guardada, por defecto se usa el tema claro (false).
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Guarda el estado actual del tema en el almacenamiento local.
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // Método público para cambiar el tema.
  void toggleTheme() {
    // Invierte el valor booleano actual.
    _isDarkMode = !_isDarkMode;
    // Guarda la nueva preferencia para futuras sesiones.
    _saveThemeToPrefs();
    // Notifica a todos los widgets que están escuchando para que se actualicen.
    notifyListeners();
  }

  // Propiedad computada que devuelve el ThemeData correspondiente al estado actual.
  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
}