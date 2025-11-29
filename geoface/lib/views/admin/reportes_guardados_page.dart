// -----------------------------------------------------------------------------
// @Encabezado:   Página de Reportes Guardados
// @Autor:        Sistema GeoFace
// @Descripción:  Vista para visualizar y gestionar reportes guardados
//               localmente con vista previa y metadatos.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/reportes_guardados_controller.dart';
import '../../models/reporte_guardado.dart';

class ReportesGuardadosPage extends StatefulWidget {
  const ReportesGuardadosPage({super.key});

  @override
  State<ReportesGuardadosPage> createState() => _ReportesGuardadosPageState();
}

class _ReportesGuardadosPageState extends State<ReportesGuardadosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<ReportesGuardadosController>(context, listen: false);
      controller.cargarReportes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Guardados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final controller = Provider.of<ReportesGuardadosController>(context, listen: false);
              controller.cargarReportes();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<ReportesGuardadosController>(
        builder: (context, controller, child) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => controller.cargarReportes(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (controller.reportes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reportes guardados',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los reportes exportados se guardarán aquí',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${controller.reportes.length} reporte${controller.reportes.length != 1 ? 's' : ''} guardado${controller.reportes.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.reportes.length,
                  itemBuilder: (context, index) {
                    final reporte = controller.reportes[index];
                    return _ReporteCard(
                      reporte: reporte,
                      onCompartir: () => _compartirReporte(reporte),
                      onEliminar: () => _eliminarReporte(controller, reporte),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _compartirReporte(ReporteGuardado reporte) async {
    try {
      final archivo = File(reporte.rutaArchivo);
      if (!await archivo.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo del reporte no existe'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final xFile = XFile(archivo.path);
      await Share.shareXFiles(
        [xFile],
        subject: 'Reporte de Asistencia - ${DateFormat('dd/MM/yyyy').format(reporte.fechaGeneracion)}',
        text: 'Reporte de asistencia: ${reporte.sedeNombre ?? "Todas las sedes"}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarReporte(
    ReportesGuardadosController controller,
    ReporteGuardado reporte,
  ) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reporte'),
        content: Text('¿Está seguro que desea eliminar el reporte "${reporte.nombreArchivo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion == true && mounted) {
      final exito = await controller.eliminarReporte(reporte.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exito ? 'Reporte eliminado' : 'Error al eliminar el reporte'),
            backgroundColor: exito ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _ReporteCard extends StatelessWidget {
  final ReporteGuardado reporte;
  final VoidCallback onCompartir;
  final VoidCallback onEliminar;

  const _ReporteCard({
    required this.reporte,
    required this.onCompartir,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.picture_as_pdf,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          reporte.nombreArchivo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (reporte.sedeNombre != null)
              Text(
                reporte.sedeNombre!,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 4),
            Text(
              'Generado: ${DateFormat('dd/MM/yyyy HH:mm', 'es').format(reporte.fechaGeneracion)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onCompartir,
              tooltip: 'Compartir',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onEliminar,
              tooltip: 'Eliminar',
              color: colorScheme.error,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('Usuario', reporte.usuarioNombre),
                _InfoRow('Período', '${DateFormat('dd/MM/yyyy', 'es').format(reporte.fechaInicio)} - ${DateFormat('dd/MM/yyyy', 'es').format(reporte.fechaFin)}'),
                _InfoRow('Asistencias', reporte.totalAsistencias.toString()),
                _InfoRow('Ausencias', reporte.totalAusencias.toString()),
                _InfoRow('Tardanzas', reporte.totalTardanzas.toString()),
                _InfoRow('% Asistencia', '${reporte.porcentajeAsistencia.toStringAsFixed(1)}%'),
                _InfoRow('Empleados', reporte.totalEmpleados.toString()),
                _InfoRow('Tamaño', reporte.tamanioFormateado),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}


