import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clase central para la configuración del tema de la aplicación.
/// Sigue los principios de Material 3.
class AppTheme {
  AppTheme._();

  // --- PALETA DE COLORES (Tu paleta ya era buena, la mantenemos) ---
  static const Color _primaryColor = Color(0xFF6A1B9A);
  static const Color _lightSecondary = Color(0xFF00796B);
  static const Color _lightTertiary = Color(0xFF8E24AA);
  static const Color _darkPrimary = Color(0xFFCE93D8);
  static const Color _darkSecondary = Color(0xFF4DB6AC);
  static const Color _darkTertiary = Color(0xFFB39DDB);

  // --- TEMA CLARO ---
  static final ThemeData lightTheme = _buildTheme(_lightColorScheme);

  // --- TEMA OSCURO ---
  static final ThemeData darkTheme = _buildTheme(_darkColorScheme);

  // --- DEFINICIÓN DE ColorScheme (Tu implementación es excelente) ---
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    brightness: Brightness.light,
  ).copyWith(
    secondary: _lightSecondary,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFB2DFDB),
    onSecondaryContainer: const Color(0xFF004D40),
    tertiary: _lightTertiary,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFF3E5F5),
    onTertiaryContainer: const Color(0xFF4A148C),
    background: const Color(0xFFFCFCFF),
    surface: Colors.white,
    surfaceVariant: const Color(0xFFF1EEF6),
    onSurfaceVariant: const Color(0xFF49454F),
    outline: const Color(0xFFD0CDE1),
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    brightness: Brightness.dark,
  ).copyWith(
    primary: _darkPrimary,
    onPrimary: const Color(0xFF381E72),
    primaryContainer: const Color(0xFF4A148C),
    onPrimaryContainer: const Color(0xFFEADDFF),
    secondary: _darkSecondary,
    onSecondary: const Color(0xFF003731),
    secondaryContainer: const Color(0xFF005048),
    onSecondaryContainer: const Color(0xFF6FF7E8),
    tertiary: _darkTertiary,
    onTertiary: const Color(0xFF381E72),
    tertiaryContainer: const Color(0xFF4A148C),
    onTertiaryContainer: const Color(0xFFEADDFF),
    background: const Color(0xFF1C1B1F),
    surface: const Color(0xFF1C1B1F),
    surfaceVariant: const Color(0xFF49454F),
    onSurfaceVariant: const Color(0xFFCAC4D0),
    outline: const Color(0xFF938F99),
  );

  /// Método constructor de temas para evitar la duplicación de código.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTheme = ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    return baseTheme.copyWith(
      // --- TIPOGRAFÍA (Tu implementación es excelente) ---
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.bold),
        displayMedium: const TextStyle(fontWeight: FontWeight.bold),
        displaySmall: const TextStyle(fontWeight: FontWeight.bold),
        headlineMedium: const TextStyle(fontWeight: FontWeight.w500),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w500),
        titleLarge: const TextStyle(fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),

      scaffoldBackgroundColor: colorScheme.background,

      // --- ESTILOS DE COMPONENTES CORREGIDOS ---

      // FIX: AppBarTheme alineado con el diseño de AdminLayout.
      // Ahora usa el color de superficie y no centra el título por defecto.
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface, // Coincide con tu AppBar personalizado
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 4, // Buena práctica para M3
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: false, // Tu diseño es con título a la izquierda
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        elevation: 1.0, // Reducimos un poco la elevación para un look más limpio
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.3), // Borde más sutil
            width: 1,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),

      // FIX: FAB Theme ahora coincide con tu diseño circular
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 4,
        shape: const CircleBorder(), // Usa CircleBorder para un FAB perfectamente redondo
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.6), // Ligera transparencia
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
      ),

      // INFO: Este tema no se usa en AdminLayout porque tienes una barra personalizada.
      // Es seguro mantenerlo si usas BottomNavigationBar en otras partes de la app.
      // Si no, puedes eliminarlo para limpiar el código.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 2,
        type: BottomNavigationBarType.fixed,
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Bordes más redondos
        titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
    );
  }
}