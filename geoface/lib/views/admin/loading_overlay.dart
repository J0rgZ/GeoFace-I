// -----------------------------------------------------------------------------
// @Encabezado:   Overlay de Carga Personalizado
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define un widget de overlay de carga que se
//               superpone sobre el contenido principal durante operaciones
//               asíncronas. Incluye indicador de progreso circular, mensaje
//               personalizable y fondo semitransparente para proporcionar
//               feedback visual al usuario durante procesos de carga.
//
// @NombreArchivo: loading_overlay.dart
// @Ubicacion:    lib/views/admin/loading_overlay.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBackPressed,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.0,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: foregroundColor ?? theme.primaryTextTheme.titleLarge?.color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: foregroundColor?.withValues(alpha: 0.8) ?? 
                       theme.primaryTextTheme.titleLarge?.color?.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      elevation: elevation,
      systemOverlayStyle: systemOverlayStyle,
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}