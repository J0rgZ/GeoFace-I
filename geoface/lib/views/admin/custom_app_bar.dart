// -----------------------------------------------------------------------------
// @Encabezado:   Barra de Aplicación Personalizada
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define un widget personalizado de AppBar que
//               proporciona una barra de aplicación reutilizable con
//               personalización de colores, títulos, subtítulos, acciones
//               y control del estilo del sistema operativo para mantener
//               consistencia visual en toda la aplicación.
//
// @NombreArchivo: custom_app_bar.dart
// @Ubicacion:    lib/views/admin/custom_app_bar.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // El contenido principal
        child,
        
        // El overlay de carga
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}