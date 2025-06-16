// views/admin/reportes_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
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
  DateTimeRange? _selectedDateRange;
  String? _selectedSedeId;

  @override
  void initState() {
    super.initState();
    // Inicializa con el mes actual por defecto
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    // Carga las sedes al iniciar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SedeController>(context, listen: false).getSedes();
    });
  }

  // CÓDIGO CORREGIDO
  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showMonthPicker(
    context: context,
    initialDate: _selectedDateRange?.start ?? DateTime.now(),
    firstDate: DateTime(2022),
    lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        final startOfMonth = DateTime(picked.year, picked.month, 1);
        final endOfMonth = DateTime(picked.year, picked.month + 1, 0);
        _selectedDateRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el tema para un diseño consistente
    final theme = Theme.of(context);
    
    return Consumer2<ReporteController, SedeController>(
      builder: (context, reporteController, sedeController, child) {
        return Scaffold(
          // Un fondo sutil para toda la página
          backgroundColor: theme.colorScheme.surface.withOpacity(0.98),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFiltros(context, sedeController.sedes, reporteController),
                const SizedBox(height: 24),
                
                // Muestra el contenido según el estado del controlador
                if (reporteController.loading)
                  const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                else if (reporteController.errorMessage != null)
                  _buildErrorWidget(reporteController.errorMessage!)
                else if (reporteController.reporteGenerado && reporteController.reporte != null)
                  _buildReporteContent(context, reporteController)
                else
                  _buildInitialMessage(),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Widgets de Construcción (Mejorados) ---

  Widget _buildFiltros(BuildContext context, List<Sede> sedes, ReporteController reporteController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros del Reporte', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            DropdownButtonFormField<String?>(
              value: _selectedSedeId,
              hint: const Text('Seleccionar Sede'),
              decoration: const InputDecoration(
                labelText: 'Sede',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas las Sedes'),
                ),
                ...sedes.map((sede) => DropdownMenuItem(
                      value: sede.id,
                      child: Text(sede.nombre, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedSedeId = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Mes del Reporte'),
              subtitle: Text(
                _selectedDateRange != null
                    ? DateFormat.yMMMM('es').format(_selectedDateRange!.start)
                    : 'No seleccionado',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _selectMonth(context),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              // Usamos FilledButton para la acción principal
              child: FilledButton.icon(
                icon: const Icon(Icons.assessment_outlined),
                label: const Text('Generar Reporte'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium,
                ),
                onPressed: () {
                  if (_selectedDateRange != null) {
                    reporteController.generarReporteDetallado(
                      fechaInicio: _selectedDateRange!.start,
                      // El rango de fechaFin debe incluir el día completo
                      fechaFin: _selectedDateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
                      sedes: sedes,
                      sedeId: _selectedSedeId,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteContent(BuildContext context, ReporteController reporteController) {
    final theme = Theme.of(context);

    // Lógica para obtener todos los días del rango (ya estaba correcta)
    if (_selectedDateRange == null) return const SizedBox.shrink();
    final diasEnRango = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays;
    final todosLosDiasDelReporte = List.generate(
      diasEnRango + 1,
      (index) => _selectedDateRange!.start.add(Duration(days: index))
    ).reversed.toList(); // .reversed para mostrar los más recientes primero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text('Resultados del Reporte', style: theme.textTheme.headlineSmall)),
            reporteController.isExporting
            ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            )
            // Usamos OutlinedButton para acciones secundarias
            : OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar'),
              onPressed: () => reporteController.exportarReporteAPDF(),
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildResumenCard(reporteController.reporte!.resumen),
        const SizedBox(height: 24),
        Text('Detalle Diario', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: todosLosDiasDelReporte.length,
          itemBuilder: (context, index) {
            final dia = todosLosDiasDelReporte[index];
            final asistenciasDelDia = reporteController.reporte!.asistenciasPorDia[dia] ?? [];
            final ausenciasDelDia = reporteController.reporte!.ausenciasPorDia[dia] ?? [];
            return _buildDiaCard(context, dia, asistenciasDelDia, ausenciasDelDia);
          },
        ),
      ],
    );
  }
  
  Widget _buildResumenCard(dynamic resumen) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen para: ${resumen.sedeNombre}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.0, // Más espacio vertical
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              children: [
                _ResumenStatItem(icon: Icons.check_circle_outline, color: Colors.green, label: 'Asistencias', value: resumen.totalAsistencias.toString()),
                _ResumenStatItem(icon: Icons.cancel_outlined, color: Colors.red, label: 'Ausencias', value: resumen.totalAusencias.toString()),
                _ResumenStatItem(icon: Icons.watch_later_outlined, color: Colors.orange, label: 'Tardanzas', value: resumen.totalTardanzas.toString()),
                _ResumenStatItem(icon: Icons.pie_chart_outline, color: Colors.blue, label: '% Asistencia', value: '${resumen.porcentajeAsistencia.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaCard(BuildContext context, DateTime dia, List<Asistencia> asistencias, List<Empleado> ausentes) {
    final theme = Theme.of(context);
    final noHayRegistros = asistencias.isEmpty && ausentes.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(), // Evita el borde doble al expandir
        collapsedShape: const Border(),
        leading: Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary),
        title: Text(DateFormat.yMMMMEEEEd('es').format(dia), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${asistencias.length} Asistencias, ${ausentes.length} Ausencias'),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          if (noHayRegistros)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Text('No se registraron asistencias ni ausencias en este día.', textAlign: TextAlign.center),
            )
          else ...[
            ...asistencias.map((a) => _buildAsistenciaTile(context, a)).toList(),
            if (ausentes.isNotEmpty) const Divider(indent: 16, endIndent: 16),
            ...ausentes.map((e) => _buildAusenciaTile(e)).toList(),
          ]
        ],
      ),
    );
  }

  ListTile _buildAsistenciaTile(BuildContext context, Asistencia asistencia) {
    final horaEntrada = asistencia.fechaHoraEntrada;
    final horaSalida = asistencia.fechaHoraSalida;
    final reporteController = Provider.of<ReporteController>(context, listen: false);
    final empleado = reporteController.getEmpleadoById(asistencia.empleadoId);

    // Comprobamos si es tardanza
    final horaLimiteHoy = horaEntrada.copyWith(hour: _horaLimiteTardanza.hour, minute: _horaLimiteTardanza.minute);
    final esTardanza = horaEntrada.isAfter(horaLimiteHoy);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: Icon(Icons.person_outline, color: Colors.green[800]),
      ),
      title: Text(empleado?.nombreCompleto ?? 'Empleado no encontrado'),
      subtitle: Text('Entrada: ${DateFormat.jm('es').format(horaEntrada)} | Salida: ${horaSalida != null ? DateFormat.jm('es').format(horaSalida) : 'Pendiente'}'),
      trailing: esTardanza 
          ? Chip(
              label: const Text('Tardanza'),
              backgroundColor: Colors.orange[100],
              labelStyle: TextStyle(color: Colors.orange[800], fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ) 
          : null,
    );
  }
  
  ListTile _buildAusenciaTile(Empleado empleado) {
    return ListTile(
       leading: CircleAvatar(
         backgroundColor: Colors.red.withOpacity(0.1),
         child: Icon(Icons.person_off_outlined, color: Colors.red[800]),
       ),
       title: Text(empleado.nombreCompleto),
       subtitle: Text('Ausente', style: TextStyle(color: Colors.red[700])),
    );
  }

  Widget _buildInitialMessage() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Listo para generar un reporte', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Selecciona una sede (opcional) y un mes, luego presiona "Generar Reporte" para ver los resultados.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 60),
            const SizedBox(height: 16),
            Text('Ocurrió un error', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onErrorContainer)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onErrorContainer)),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizable para mostrar una estadística en el resumen.
class _ResumenStatItem extends StatelessWidget {
  const _ResumenStatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.8))),
            ],
          ),
        ),
      ],
    );
  }
}