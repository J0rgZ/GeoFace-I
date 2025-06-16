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
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
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
    return Consumer2<ReporteController, SedeController>(
      builder: (context, reporteController, sedeController, child) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildFiltros(context, sedeController.sedes, reporteController),
                const SizedBox(height: 24),
                
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

  // ¡CORREGIDO! Este método ahora recibe el ReporteController completo
  Widget _buildReporteContent(BuildContext context, ReporteController reporteController) {
    // =========================================================================
    // ¡LÓGICA CORREGIDA! Generamos la lista de días a partir del rango seleccionado.
    // =========================================================================
    if (_selectedDateRange == null) return const SizedBox.shrink(); // Seguridad

    final diasEnRango = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays;
    final todosLosDiasDelReporte = List.generate(
      diasEnRango + 1,
      (index) => _selectedDateRange!.start.add(Duration(days: index))
    ).reversed.toList(); // .reversed para mostrar los más recientes primero
    // =========================================================================

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Resultados del Reporte', style: Theme.of(context).textTheme.headlineSmall, overflow: TextOverflow.ellipsis)),
            reporteController.isExporting
            ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            )
            : TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar'),
              onPressed: () => reporteController.exportarReporteAPDF(),
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildResumenCard(reporteController.reporte!.resumen),
        const SizedBox(height: 24),
        Text('Detalle Diario de Asistencias', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Usamos la nueva lista completa de días
          itemCount: todosLosDiasDelReporte.length,
          itemBuilder: (context, index) {
            final dia = todosLosDiasDelReporte[index];
            // Buscamos los datos para este día en el reporte generado
            final asistenciasDelDia = reporteController.reporte!.asistenciasPorDia[dia] ?? [];
            final ausenciasDelDia = reporteController.reporte!.ausenciasPorDia[dia] ?? [];
            return _buildDiaCard(context, dia, asistenciasDelDia, ausenciasDelDia);
          },
        ),
      ],
    );
  }

  // El resto de la página no necesita cambios
  // ... (pega aquí el resto de tus métodos: _buildFiltros, _buildResumenCard, etc.)
  Widget _buildFiltros(BuildContext context, List<Sede> sedes, ReporteController reporteController) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtros del Reporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            DropdownButtonFormField<String?>(
              value: _selectedSedeId,
              hint: const Text('Seleccionar Sede'),
              decoration: const InputDecoration(
                labelText: 'Sede',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
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
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.edit, color: Colors.blue),
              onTap: () => _selectMonth(context),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assessment),
                label: const Text('Generar Reporte'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (_selectedDateRange != null) {
                    reporteController.generarReporteDetallado(
                      fechaInicio: _selectedDateRange!.start,
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
  
  Widget _buildResumenCard(dynamic resumen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: isDarkMode ? Colors.blueGrey[800] : Colors.blue[50],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDarkMode ? Colors.blueGrey[600]! : Colors.blue[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen para: ${resumen.sedeNombre}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              children: [
                _buildStatItem('Asistencias', resumen.totalAsistencias.toString(), Icons.check_circle_outline, Colors.green),
                _buildStatItem('Ausencias', resumen.totalAusencias.toString(), Icons.cancel_outlined, Colors.red),
                _buildStatItem('Tardanzas', resumen.totalTardanzas.toString(), Icons.watch_later_outlined, Colors.orange),
                _buildStatItem('% Asistencia', '${resumen.porcentajeAsistencia.toStringAsFixed(1)}%', Icons.pie_chart_outline, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiaCard(BuildContext context, DateTime dia, List<Asistencia> asistencias, List<Empleado> ausentes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(DateFormat.yMMMMEEEEd('es').format(dia), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${asistencias.length} Asistencias, ${ausentes.length} Ausencias'),
        leading: const Icon(Icons.calendar_today),
        children: [
          ...asistencias.map((a) => _buildAsistenciaTile(context, a)).toList(),
          if (ausentes.isNotEmpty) const Divider(),
          ...ausentes.map((e) => _buildAusenciaTile(e)).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  ListTile _buildAsistenciaTile(BuildContext context, Asistencia asistencia) {
    final horaEntrada = DateFormat.jm('es').format(asistencia.fechaHoraEntrada);
    final horaSalida = asistencia.fechaHoraSalida != null ? DateFormat.jm('es').format(asistencia.fechaHoraSalida!) : 'Pendiente';
    final reporteController = Provider.of<ReporteController>(context, listen: false);
    final empleado = reporteController.getEmpleadoById(asistencia.empleadoId);

    return ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
      title: Text(empleado?.nombreCompleto ?? 'Empleado no encontrado'),
      subtitle: Text('Entrada: $horaEntrada | Salida: $horaSalida'),
    );
  }
  
  ListTile _buildAusenciaTile(Empleado empleado) {
    return ListTile(
       leading: CircleAvatar(backgroundColor: Colors.red[100], child: Icon(Icons.person_off, color: Colors.red[700])),
       title: Text(empleado.nombreCompleto),
       subtitle: Text('Ausente', style: TextStyle(color: Colors.red[700])),
    );
  }

  Widget _buildInitialMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Listo para generar un reporte', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Selecciona una sede (opcional) y un mes, luego presiona "Generar Reporte" para ver los resultados.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Ocurrió un error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}