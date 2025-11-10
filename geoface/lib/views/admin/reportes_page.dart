// -----------------------------------------------------------------------------
// @Encabezado:   Página de Generación de Reportes de Asistencia
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página de generación y visualización
//               de reportes detallados de asistencia para administradores.
//               Incluye filtros por sede y mes, generación de reportes con
//               estadísticas de asistencias, ausencias y tardanzas, exportación
//               a PDF, y visualización expandible del detalle diario con
//               información completa de cada empleado.
//
// @NombreArchivo: reportes_page.dart
// @Ubicacion:    lib/views/admin/reportes_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // Para el efecto de carga
import '../../controllers/reporte_controller.dart';
import '../../controllers/sede_controller.dart';
import '../../models/asistencia.dart';
import '../../models/empleado.dart';
import '../../models/sede.dart';

// Constante para la hora límite de tardanza, facilita su modificación.
final _horaLimiteTardanza = DateTime(0).copyWith(hour: 9, minute: 1);

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  DateTime _selectedMonth = DateTime.now();
  bool _mostrarDiasSinDatos = false; // Filtro para mostrar/ocultar días sin datos

  @override
  void initState() {
    super.initState();
    // Carga las sedes al iniciar la página, solo si no están ya cargadas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sedeController = Provider.of<SedeController>(context, listen: false);
      if (sedeController.sedes.isEmpty) {
        sedeController.getSedes();
      }
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Consumer2<ReporteController, SedeController>(
        builder: (context, reporteController, sedeController, child) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _FiltrosCard(
                  selectedMonth: _selectedMonth,
                  sedes: sedeController.sedes,
                  onSelectMonth: () => _selectMonth(context),
                  onGenerarReporte: (sedeId) async {
                    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
                    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).add(const Duration(hours: 23, minutes: 59));
                    
                    // Validación visual antes de generar
                    final confirmacion = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.assessment_outlined, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Generar Reporte'),
                          ],
                        ),
                        content: Text(
                          '¿Desea generar el reporte de asistencia para\n${DateFormat.yMMMM('es').format(_selectedMonth)}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Generar'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmacion == true && mounted) {
                      await reporteController.generarReporteDetallado(
                        fechaInicio: startOfMonth,
                        fechaFin: endOfMonth,
                        sedes: sedeController.sedes,
                        sedeId: sedeId,
                      );
                      
                      // Mostrar mensaje de error si existe
                      if (reporteController.errorMessage != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(reporteController.errorMessage!),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Cerrar',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                sliver: _buildReporteBody(reporteController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReporteBody(ReporteController reporteController) {
    if (reporteController.loading) {
      return _buildLoadingSkeleton();
    }
    if (reporteController.errorMessage != null) {
      return SliverToBoxAdapter(child: _ErrorState(message: reporteController.errorMessage!));
    }
    if (reporteController.reporteGenerado && reporteController.reporte != null) {
      return _buildReporteContent(reporteController);
    }
    return const SliverToBoxAdapter(child: _InitialState());
  }

  Widget _buildLoadingSkeleton() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.surfaceContainer,
            highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 150,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Generando reporte...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporteContent(ReporteController reporteController) {
    // Validación de seguridad: verificar que el reporte existe
    if (reporteController.reporte == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    // Lógica de fechas
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final diasEnRango = endOfMonth.difference(startOfMonth).inDays;
    
    // Optimización: Pre-calcular días una sola vez
    final todosLosDiasDelReporte = List.generate(
      diasEnRango + 1, 
      (index) => startOfMonth.add(Duration(days: index)),
      growable: false,
    ).reversed.toList();
    
    // Filtrar días sin datos si el filtro está activado
    // Optimización: Usar Set para búsqueda O(1) en lugar de O(n) para cada día
    final diasConDatos = <DateTime>{
      ...reporteController.reporte!.asistenciasPorDia.keys,
      ...reporteController.reporte!.ausenciasPorDia.keys,
    };
    
    final diasParaMostrar = _mostrarDiasSinDatos
        ? todosLosDiasDelReporte
        : todosLosDiasDelReporte.where((dia) => diasConDatos.contains(dia)).toList();
    
    return SliverList.list(
      children: [
        _ResumenReporteCard(
          resumen: reporteController.reporte!.resumen,
          isExporting: reporteController.isExporting,
          onExport: () => _exportarReporteConConfirmacion(reporteController),
        ),
        const SizedBox(height: 24),
        // Barra de filtros y título
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detalle Diario',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${diasParaMostrar.length} días',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FilterChip(
                      label: Text(
                        _mostrarDiasSinDatos ? 'Todos los días' : 'Solo con datos',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: _mostrarDiasSinDatos,
                      onSelected: (value) {
                        setState(() {
                          _mostrarDiasSinDatos = value;
                        });
                      },
                      avatar: Icon(
                        _mostrarDiasSinDatos ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (diasParaMostrar.isEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay datos para mostrar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No se encontraron registros de asistencia para el período seleccionado.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...diasParaMostrar.map((dia) {
            final asistenciasDelDia = reporteController.reporte!.asistenciasPorDia[dia] ?? [];
            final ausenciasDelDia = reporteController.reporte!.ausenciasPorDia[dia] ?? [];
            return _DiaExpansionTile(
              dia: dia,
              asistencias: asistenciasDelDia,
              ausentes: ausenciasDelDia,
              getEmpleadoById: reporteController.getEmpleadoById,
            );
          }),
      ],
    );
  }

  Future<void> _exportarReporteConConfirmacion(ReporteController reporteController) async {
    // Validación: Verificar que hay un reporte generado
    if (reporteController.reporte == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay un reporte generado para exportar.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Diálogo de confirmación
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 48),
        title: const Text('Exportar Reporte a PDF'),
        content: const Text(
          '¿Desea exportar el reporte actual a PDF?\n\nPodrá compartirlo o guardarlo desde la vista previa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmacion == true && mounted) {
      final exito = await reporteController.exportarReporteAPDF();
      
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Reporte exportado exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reporteController.errorMessage ?? 'Error al exportar el reporte',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Cerrar',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }
}

// --- WIDGETS DE UI REUTILIZABLES Y MEJORADOS ---

class _FiltrosCard extends StatefulWidget {
  final DateTime selectedMonth;
  final List<Sede> sedes;
  final VoidCallback onSelectMonth;
  final Function(String? sedeId) onGenerarReporte;

  const _FiltrosCard({required this.selectedMonth, required this.sedes, required this.onSelectMonth, required this.onGenerarReporte});

  @override
  State<_FiltrosCard> createState() => _FiltrosCardState();
}

class _FiltrosCardState extends State<_FiltrosCard> {
  String? _selectedSedeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String?>(
              value: _selectedSedeId,
              hint: const Text('Todas las Sedes'),
              decoration: const InputDecoration(labelText: 'Filtrar por Sede (Opcional)', prefixIcon: Icon(Icons.location_city_outlined)),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Todas las Sedes')),
                ...widget.sedes.map((sede) => DropdownMenuItem(value: sede.id, child: Text(sede.nombre, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (value) => setState(() => _selectedSedeId = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: widget.onSelectMonth,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Mes del Reporte', prefixIcon: Icon(Icons.calendar_month_outlined)),
                child: Text(
                  DateFormat.yMMMM('es').format(widget.selectedMonth),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('Generar Reporte'),
                onPressed: () => widget.onGenerarReporte(_selectedSedeId),
              ),
            ),
          ],
        ),
      );
  }
}

class _ResumenReporteCard extends StatelessWidget {
  final dynamic resumen;
  final bool isExporting;
  final VoidCallback onExport;

  const _ResumenReporteCard({required this.resumen, required this.isExporting, required this.onExport});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del Reporte',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resumen.sedeNombre,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: isExporting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 20),
                label: Text(isExporting ? 'Exportando...' : 'Exportar PDF'),
                onPressed: isExporting ? null : onExport,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // Usamos Wrap para ser flexible en pantallas pequeñas
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ResumenStatItem(
                icon: Icons.check_circle_outline,
                color: Colors.green,
                label: 'Asistencias',
                value: resumen.totalAsistencias.toString(),
              ),
              _ResumenStatItem(
                icon: Icons.cancel_outlined,
                color: colorScheme.error,
                label: 'Ausencias',
                value: resumen.totalAusencias.toString(),
              ),
              _ResumenStatItem(
                icon: Icons.watch_later_outlined,
                color: Colors.orange.shade700,
                label: 'Tardanzas',
                value: resumen.totalTardanzas.toString(),
              ),
              _ResumenStatItem(
                icon: Icons.pie_chart_outline,
                color: colorScheme.primary,
                label: '% Asistencia',
                value: '${resumen.porcentajeAsistencia.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenStatItem extends StatelessWidget {
  final IconData icon; 
  final Color color; 
  final String label; 
  final String value;
  
  const _ResumenStatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiaExpansionTile extends StatelessWidget {
  final DateTime dia;
  final List<Asistencia> asistencias;
  final List<Empleado> ausentes;
  final Empleado? Function(String) getEmpleadoById;

  const _DiaExpansionTile({
    required this.dia,
    required this.asistencias,
    required this.ausentes,
    required this.getEmpleadoById,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noHayRegistros = asistencias.isEmpty && ausentes.isEmpty;
    final colorScheme = theme.colorScheme;
    final esHoy = dia.year == DateTime.now().year && 
                  dia.month == DateTime.now().month && 
                  dia.day == DateTime.now().day;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: esHoy ? colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          DateFormat.yMMMMEEEEd('es').format(dia),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            if (asistencias.isNotEmpty) ...[
              Icon(Icons.check_circle, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text('${asistencias.length} Asistencias'),
              if (ausentes.isNotEmpty) const SizedBox(width: 12),
            ],
            if (ausentes.isNotEmpty) ...[
              Icon(Icons.cancel, size: 14, color: colorScheme.error),
              const SizedBox(width: 4),
              Text('${ausentes.length} Ausencias'),
            ],
            if (noHayRegistros)
              Text(
                'Sin registros',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          if (noHayRegistros)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No hay registros para este día',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (asistencias.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Asistencias (${asistencias.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              ...asistencias.map((a) => _buildAsistenciaTile(context, a)),
            ],
            if (ausentes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ausencias (${ausentes.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              ...ausentes.map((e) => _buildAusenciaTile(context, e)),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildAsistenciaTile(BuildContext context, Asistencia asistencia) {
    final empleado = getEmpleadoById(asistencia.empleadoId);
    final horaEntrada = asistencia.fechaHoraEntrada;
    // OPTIMIZADO: Comparación directa sin crear nuevo DateTime
    final horaLimite = _horaLimiteTardanza.hour;
    final minutoLimite = _horaLimiteTardanza.minute;
    final esTardanza = horaEntrada.hour > horaLimite || 
                       (horaEntrada.hour == horaLimite && horaEntrada.minute > minutoLimite);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tieneSalida = asistencia.fechaHoraSalida != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esTardanza 
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: esTardanza 
              ? Colors.orange.shade50
              : Colors.green.shade50,
          child: Icon(
            Icons.person,
            color: esTardanza 
                ? Colors.orange.shade700
                : Colors.green.shade700,
            size: 20,
          ),
        ),
        title: Text(
          empleado?.nombreCompleto ?? 'Empleado Desconocido',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.login, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text('Entrada: ${DateFormat.jm('es').format(horaEntrada)}'),
              ],
            ),
            if (tieneSalida) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.logout, size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 4),
                  Text('Salida: ${DateFormat.jm('es').format(asistencia.fechaHoraSalida!)}'),
                ],
              ),
            ],
          ],
        ),
        trailing: esTardanza 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.watch_later, size: 14, color: Colors.orange.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'Tarde',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ) 
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green.shade700,
                ),
              ),
      ),
    );
  }
  
  Widget _buildAusenciaTile(BuildContext context, Empleado empleado) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.errorContainer,
          child: Icon(
            Icons.person_off,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
        ),
        title: Text(
          empleado.nombreCompleto,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.cancel, size: 14, color: colorScheme.error),
            const SizedBox(width: 4),
            Text(
              'Ausente',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.close,
            size: 18,
            color: colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, size: 64, color: theme.colorScheme.primary.withAlpha(200)),
          const SizedBox(height: 24),
          Text('Listo para generar un reporte', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Selecciona tus filtros y presiona "Generar Reporte" para visualizar los datos de asistencia.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer, size: 56),
          const SizedBox(height: 16),
          Text('Ocurrió un Error', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onErrorContainer)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onErrorContainer)),
        ],
      ),
    );
  }
}