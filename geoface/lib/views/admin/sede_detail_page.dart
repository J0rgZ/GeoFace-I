// -----------------------------------------------------------------------------
// @Encabezado:   Página de Detalle de Sede
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página de detalle de una sede
//               específica. Proporciona visualización completa de la
//               información de la sede, incluyendo datos geográficos,
//               estado operativo y navegación a funciones relacionadas
//               como edición y gestión de empleados asignados.
//
// @NombreArchivo: sede_detail_page.dart
// @Ubicacion:    lib/views/admin/sede_detail_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class SedeDetailPage extends StatelessWidget {
  final String sedeId;

  const SedeDetailPage({super.key, required this.sedeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Sede')),
      body: Center(child: Text('ID de la Sede: $sedeId')),
    );
  }
}
