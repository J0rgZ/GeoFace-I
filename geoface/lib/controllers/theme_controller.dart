// -----------------------------------------------------------------------------
// @Encabezado:   Controlador de Tema de la Aplicación
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define el `ThemeController`, una clase que gestiona
//               el estado del tema visual (claro/oscuro) de la aplicación.
//               Utiliza `SharedPreferences` para guardar la preferencia del
//               usuario y notifica a la interfaz de usuario sobre cualquier
//               cambio para que se reconstruya con el tema correcto.
//
// @NombreControlador: ThemeController
// @Ubicacion:    lib/controllers/theme_controller.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';

class ThemeController extends ChangeNotifier {
  // Clave única para guardar y recuperar la preferencia del tema en SharedPreferences.
  static const String _themeKey = 'app_theme';

  // Variables privadas para manejar el estado interno del controlador.
  bool _isDarkMode = false;
  ThemeData _currentTheme = AppTheme.lightTheme;

  // Getters públicos para acceder al estado desde la UI de forma segura.
  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme => _currentTheme;

  // El constructor se ejecuta al crear la instancia y carga inmediatamente el tema guardado.
  ThemeController() {
    _loadThemePreference();
  }

  // Carga la preferencia del tema desde el almacenamiento local del dispositivo.
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Si no encuentra un valor guardado, por defecto se usa el tema claro (false).
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }

  // Guarda la preferencia actual del tema en el almacenamiento local.
  Future<void> _saveThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  // Alterna entre el tema claro y oscuro.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    _saveThemePreference();
    notifyListeners();
  }

  // Permite establecer un tema específico (claro u oscuro) directamente.
  void setTheme(bool darkMode) {
    // Solo actualiza y notifica si el nuevo tema es diferente al actual, para evitar reconstrucciones innecesarias.
    if (_isDarkMode != darkMode) {
      _isDarkMode = darkMode;
      _currentTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
      _saveThemePreference();
      notifyListeners();
    }
  }
}