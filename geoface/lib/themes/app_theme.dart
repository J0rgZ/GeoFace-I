// en tu archivo theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de tema profesional con una paleta sofisticada de Verde Bosque y Carbón.
/// Diseñado para una experiencia de usuario premium, con máxima legibilidad y coherencia.
class AppTheme {
  AppTheme._();

  // --- PALETA DE COLORES BASE ---
  static const Color _primarySeed = Color.fromARGB(255, 76, 3, 126); // Un verde azulado, elegante y menos saturado.
  static const Color _secondarySeed = Color.fromARGB(255, 72, 61, 83); // Pizarra/Carbón como secundario.
  static const Color _tertiarySeed = Color(0xFF546E7A); // Un tono más claro para acentos.
  static const Color _errorSeed = Color(0xFFE53935);   // Rojo controlado para errores.

  // --- TEMAS PRINCIPALES ---
  static final ThemeData lightTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primarySeed,
      secondary: _secondarySeed,
      tertiary: _tertiarySeed,
      error: _errorSeed,
      brightness: Brightness.light,
      background: const Color(0xFFF7F9FA), // Un blanco ligeramente más cálido.
      surface: Colors.white,
    ),
  );

  static final ThemeData darkTheme = _buildTheme(
    ColorScheme.fromSeed(
      seedColor: _primarySeed,
      secondary: _secondarySeed,
      tertiary: _tertiarySeed,
      error: _errorSeed,
      brightness: Brightness.dark,
      background: const Color(0xFF121212), // Negro profundo estándar de Material Design.
      surface: const Color(0xFF1E1E1E),     // Superficie ligeramente más clara.
    ),
  );

  /// Método constructor de temas para unificar el estilo.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTheme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
    
    return baseTheme.copyWith(
      // --- TIPOGRAFÍA ---
      // Inter es una fuente profesional, altamente legible en UI.
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),

      scaffoldBackgroundColor: colorScheme.background,

      // --- ESTILOS DE COMPONENTES ---

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 2.0,
        surfaceTintColor: colorScheme.surfaceTint.withOpacity(0.05),
        centerTitle: true,
      ),

      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),

      // Estilos para botones.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Estilo para los FAB.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Estilo para campos de texto.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      
      // Estilo para los diálogos, como el de "Cerrar Sesión".
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: baseTheme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      
      // Estilo global para el BottomSheet.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        modalElevation: 0,
      ),

      // Estilo para los Switches.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => 
          states.contains(WidgetState.selected) ? colorScheme.primary : colorScheme.outline
        ),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? colorScheme.primary.withOpacity(0.5) : colorScheme.surfaceVariant
        ),
      ),
    );
  }
}