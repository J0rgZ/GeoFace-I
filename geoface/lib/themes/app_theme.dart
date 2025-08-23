// -----------------------------------------------------------------------------
// @Encabezado:   Tema de la Aplicación (Theme)
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo centraliza la configuración visual de toda la
//               aplicación, definiendo los temas claro (light) y oscuro (dark)
//               basados en los principios de diseño de Material 3. Se utiliza
//               ColorScheme.fromSeed para generar paletas de colores armónicas
//               y se personalizan los estilos de los widgets más comunes
//               (botones, tarjetas, campos de texto, etc.) para asegurar una
//               apariencia consistente y moderna.
//
// @NombreArchivo: app_theme.dart
// @Ubicacion:    lib/themes/app_theme.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Clase que contiene las configuraciones de los temas de la aplicación.
// El constructor privado `_()` previene que esta clase sea instanciada.
class AppTheme {
  AppTheme._();

  // Color "semilla" principal a partir del cual se generarán las paletas de colores.
  static const Color _primarySeed = Color.fromARGB(255, 61, 3, 100);
  // Color "semilla" para los estados de error.
  static const Color _errorSeed = Color(0xFFB00020);

  // Definición del tema claro.
  static final ThemeData lightTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primarySeed,
      error: _errorSeed,
      brightness: Brightness.light,
    ),
  );

  // Definición del tema oscuro.
  static final ThemeData darkTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primarySeed,
      error: _errorSeed,
      brightness: Brightness.dark,
    ),
  );

  // Método privado y centralizado que construye el tema base a partir de un esquema de color.
  // Esto evita la repetición de código y asegura que ambos temas compartan las mismas personalizaciones.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    // Se crea un tema base de Material 3 a partir del `ColorScheme`.
    final baseTheme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    
    // Se aplican personalizaciones sobre el tema base.
    return baseTheme.copyWith(
      // Se establece la tipografía `Inter` de Google Fonts para toda la app.
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: colorScheme.onSurface, // Color para el texto principal.
        displayColor: colorScheme.onSurface, // Color para los títulos.
      ),

      // Color de fondo para los `Scaffold` (pantallas principales).
      scaffoldBackgroundColor: colorScheme.surface,

      // Estilo global para las `AppBar`.
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface, // Color de íconos y texto del AppBar.
        elevation: 0,
        // Tinte sutil que aparece al hacer scroll debajo del AppBar (guía de M3).
        scrolledUnderElevation: 4.0,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: true,
      ),

      // Estilo global para las `Card`.
      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        elevation: 0, // Se prefieren bordes en lugar de sombras en M3.
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Borde sutil que sigue las guías de Material 3.
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
      ),

      // Estilo para los `FilledButton`.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(), // Forma de "píldora", muy común en M3.
        ),
      ),
      
      // Estilo para los `TextButton`.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Estilo para los `FloatingActionButton`.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Estilo global para los campos de texto (`TextField`).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        // Borde por defecto.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        // Borde cuando el campo tiene el foco.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        // Borde para errores de validación.
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
      ),
      
      // Estilo para los diálogos de alerta.
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // Radio de borde estándar de M3.
        titleTextStyle: baseTheme.textTheme.headlineSmall,
      ),
      
      // Estilo para las hojas inferiores (`BottomSheet`).
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        modalBackgroundColor: colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalElevation: 0,
      ),

      // Estilo para los interruptores (`Switch`).
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // Estilo para los `Chip` (usados para filtros, etiquetas, etc.).
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        labelStyle: baseTheme.textTheme.labelLarge,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}