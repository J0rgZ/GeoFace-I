// en tu archivo theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un sistema de tema avanzado y elegante basado en Material 3.
/// 
/// Utiliza un único color semilla para generar una paleta de colores completa y armónica,
/// garantizando coherencia visual, accesibilidad y una estética moderna.
/// Este tema está diseñado para ser robusto, escalable y fácil de mantener.
class AppTheme {
  AppTheme._();

  // --- COLOR SEMILLA ---
  // La única fuente de verdad para toda la paleta de colores.
  // Material 3 generará los tonos primarios, secundarios y terciarios a partir de aquí.
  static const Color _primarySeed = Color.fromARGB(255, 61, 3, 100);
  
  // El color de error generalmente se mantiene estático para ser universalmente reconocible.
  static const Color _errorSeed = Color(0xFFB00020);

  // --- TEMAS PRINCIPALES ---
  static final ThemeData lightTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primarySeed,
      error: _errorSeed,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData darkTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primarySeed,
      error: _errorSeed,
      brightness: Brightness.dark,
    ),
  );

  /// Método constructor de temas unificado y robusto.
  /// Aplica estilos consistentes a todos los componentes principales de la app.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTheme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    
    return baseTheme.copyWith(
      // --- TIPOGRAFÍA ---
      // Usamos Google Fonts para una apariencia limpia y profesional.
      // Se aplica el color 'onSurface' por defecto para garantizar la legibilidad.
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),

      scaffoldBackgroundColor: colorScheme.surface,

      // --- ESTILOS DE COMPONENTES ESPECÍFICOS ---

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        // El tinte que se aplica cuando hay contenido debajo haciendo scroll.
        scrolledUnderElevation: 4.0,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: true,
      ),

      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          // Usamos outlineVariant para bordes sutiles y decorativos, como recomienda M3.
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
      ),

      // Estilos para botones, promoviendo una estética M3 moderna.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // La forma de "píldora" o estadio es muy común y moderna en M3.
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // El FAB es un punto de acción clave. Usamos colores de "container" para destacarlo.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Campos de texto con un diseño limpio y claro.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        // Borde por defecto, sutil pero visible.
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        // Borde cuando el campo está enfocado, usando el color primario.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        // Borde para errores.
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
      
      // Diálogos con el radio de borde estándar de M3.
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: baseTheme.textTheme.headlineSmall,
      ),
      
      // BottomSheet con un estilo suave y elevado.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        modalBackgroundColor: colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalElevation: 0,
      ),

      // Switches que usan los roles de color de forma nativa.
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

      // Estilo para Chips (filtros, etiquetas, etc.)
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        labelStyle: baseTheme.textTheme.labelLarge,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}