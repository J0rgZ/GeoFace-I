// views/admin/reportes_page.dart (VERSIÓN PREMIUM)
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
                  onGenerarReporte: (sedeId) {
                    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
                    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).add(const Duration(hours: 23, minutes: 59));
                    reporteController.generarReporteDetallado(
                      fechaInicio: startOfMonth,
                      fechaFin: endOfMonth,
                      sedes: sedeController.sedes,
                      sedeId: sedeId,
                    );
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
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainer,
        highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            Container(width: 150, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 12),
            Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteContent(ReporteController reporteController) {
    // Lógica de fechas
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final diasEnRango = endOfMonth.difference(startOfMonth).inDays;
    final todosLosDiasDelReporte = List.generate(diasEnRango + 1, (index) => startOfMonth.add(Duration(days: index))).reversed.toList();
    
    return SliverList.list(
      children: [
        _ResumenReporteCard(
          resumen: reporteController.reporte!.resumen,
          isExporting: reporteController.isExporting,
          onExport: () => reporteController.exportarReporteAPDF(),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text('Detalle Diario', style: Theme.of(context).textTheme.titleLarge),
        ),
        ...todosLosDiasDelReporte.map((dia) {
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
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Form(
      key: _formKey,
      child: Container(
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
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Resumen: ${resumen.sedeNombre}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  icon: isExporting
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: colorScheme.primary))
                      : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  label: Text(isExporting ? 'Exportando...' : 'Exportar'),
                  onPressed: isExporting ? null : onExport,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Usamos Wrap para ser flexible en pantallas pequeñas
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _ResumenStatItem(icon: Icons.check_circle_outline, color: colorScheme.primary, label: 'Asistencias', value: resumen.totalAsistencias.toString()),
              _ResumenStatItem(icon: Icons.cancel_outlined, color: colorScheme.error, label: 'Ausencias', value: resumen.totalAusencias.toString()),
              _ResumenStatItem(icon: Icons.watch_later_outlined, color: Colors.orange.shade700, label: 'Tardanzas', value: resumen.totalTardanzas.toString()),
              _ResumenStatItem(icon: Icons.pie_chart_outline, color: colorScheme.tertiary, label: '% Asistencia', value: '${resumen.porcentajeAsistencia.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumenStatItem extends StatelessWidget {
  final IconData icon; final Color color; final String label; final String value;
  const _ResumenStatItem({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min, // Importante para que Wrap funcione correctamente
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _DiaExpansionTile extends StatelessWidget {
  final DateTime dia;
  final List<Asistencia> asistencias;
  final List<Empleado> ausentes;
  final Empleado? Function(String) getEmpleadoById;

  const _DiaExpansionTile({required this.dia, required this.asistencias, required this.ausentes, required this.getEmpleadoById});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noHayRegistros = asistencias.isEmpty && ausentes.isEmpty;
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Para que el ExpansionTile se ajuste bien
      child: ExpansionTile(
        leading: Icon(Icons.calendar_today, color: colorScheme.primary),
        title: Text(DateFormat.yMMMMEEEEd('es').format(dia), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text('${asistencias.length} Asistencias, ${ausentes.length} Ausencias'),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          if (noHayRegistros)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No hay registros para este día.')))
          else ...[
            if (asistencias.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.all(8.0), child: Text('Asistencias', style: theme.textTheme.titleSmall)),
              ...asistencias.map((a) => _buildAsistenciaTile(context, a)),
            ],
            if (ausentes.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.all(8.0), child: Text('Ausencias', style: theme.textTheme.titleSmall)),
              ...ausentes.map((e) => _buildAusenciaTile(context, e)),
            ],
          ]
        ],
      ),
    );
  }
  
  Widget _buildAsistenciaTile(BuildContext context, Asistencia asistencia) {
    final empleado = getEmpleadoById(asistencia.empleadoId);
    final horaEntrada = asistencia.fechaHoraEntrada;
    final horaLimiteHoy = horaEntrada.copyWith(hour: _horaLimiteTardanza.hour, minute: _horaLimiteTardanza.minute);
    final esTardanza = horaEntrada.isAfter(horaLimiteHoy);
    final theme = Theme.of(context);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(Icons.person_outline, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(empleado?.nombreCompleto ?? 'Empleado Desconocido'),
      subtitle: Text('Entrada: ${DateFormat.jm('es').format(horaEntrada)}'),
      trailing: esTardanza 
          ? Chip(
              label: const Text('Tarde'),
              backgroundColor: Colors.orange.withAlpha(50),
              side: BorderSide.none,
              labelStyle: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
              visualDensity: VisualDensity.compact,
            ) 
          : null,
    );
  }
  
  Widget _buildAusenciaTile(BuildContext context, Empleado empleado) {
    final theme = Theme.of(context);
    return ListTile(
       leading: CircleAvatar(
         backgroundColor: theme.colorScheme.errorContainer,
         child: Icon(Icons.person_off_outlined, color: theme.colorScheme.onErrorContainer),
       ),
       title: Text(empleado.nombreCompleto),
       subtitle: Text('Ausente', style: TextStyle(color: theme.colorScheme.error)),
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