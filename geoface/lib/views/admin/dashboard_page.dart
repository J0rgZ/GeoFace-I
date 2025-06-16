// views/admin/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/sede_controller.dart';
import '../../controllers/empleado_controller.dart';
import '../../controllers/asistencia_controller.dart';
import '../../models/sede.dart';
import '../../models/empleado.dart';
import '../../models/asistencia.dart';
import '../../utils/date_utils.dart' as date_utils;

class DashboardPage extends StatefulWidget {
  final void Function(int)? onNavigateToTab;

  const DashboardPage({super.key, this.onNavigateToTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final sedeController = Provider.of<SedeController>(context, listen: false);
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);
    
    await Future.wait([
      sedeController.getSedes(),
      empleadoController.getEmpleados(),
      asistenciaController.getAllAsistencias(),
    ]);
  }
  
  // NOTA DE RENDIMIENTO: El método `getAllAsistencias` puede ser ineficiente si hay
  // un gran volumen de datos históricos. Para una aplicación a gran escala, sería
  // ideal tener un endpoint en el backend que devuelva solo las asistencias del día,
  // por ejemplo: `asistenciaController.getAsistenciasDeHoy()`.
  // La lógica actual en el cliente es aceptable para volúmenes de datos pequeños/medianos.

  int _getAsistenciasHoy(List<Asistencia> asistencias) {
    // AVISO IMPORTANTE: Los errores de Timeout en tus logs indican que obtener la hora de APIs externas está fallando.
    // Deberías usar DateTime.now() como fallback para que la app no se detenga.
    final hoy = DateTime.now();
    return asistencias.where((a) => date_utils.isSameDay(a.fechaHoraEntrada, hoy)).length;
  }

  Map<String, int> _getAsistenciasPorSedeHoy(List<Asistencia> asistencias, List<Sede> sedes) {
    final hoy = DateTime.now();
    final Map<String, int> asistenciasPorSede = {
      for (var sede in sedes) sede.id: 0
    };
    
    for (var asistencia in asistencias) {
      if (date_utils.isSameDay(asistencia.fechaHoraEntrada, hoy)) {
        if (asistenciasPorSede.containsKey(asistencia.sedeId)) {
          asistenciasPorSede[asistencia.sedeId] = (asistenciasPorSede[asistencia.sedeId] ?? 0) + 1;
        }
      }
    }
    
    return asistenciasPorSede;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Consumer3<SedeController, EmpleadoController, AsistenciaController>(
        builder: (context, sedeController, empleadoController, asistenciaController, _) {
          
          if (sedeController.loading || empleadoController.loading || asistenciaController.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final errorMessage = sedeController.errorMessage ?? empleadoController.errorMessage ?? asistenciaController.errorMessage;
          if (errorMessage != null) {
            return _buildErrorWidget(errorMessage, _loadData);
          }

          final sedes = sedeController.sedes;
          final empleados = empleadoController.empleados;
          final asistencias = asistenciaController.asistencias;

          final sedesActivas = sedes.where((sede) => sede.activa).length;
          final empleadosActivos = empleados.where((emp) => emp.activo).length;
          final totalSedes = sedes.length;
          final totalEmpleados = empleados.length;
          
          final asistenciasHoy = _getAsistenciasHoy(asistencias);
          final asistenciasPorSedeHoy = _getAsistenciasPorSedeHoy(asistencias, sedes);
          final tasaAsistencia = empleadosActivos > 0 
              ? (asistenciasHoy / empleadosActivos * 100)
              : 0.0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final gridCrossAxisCount = isSmallScreen ? 2 : 4;
              final cardAspectRatio = isSmallScreen ? 1.1 : 1.4;
    
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDashboardHeader(),
                      const SizedBox(height: 16),
                      
                      GridView(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          childAspectRatio: cardAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            title: 'Sedes Activas',
                            value: sedesActivas.toString(),
                            total: totalSedes.toString(),
                            icon: Icons.location_city,
                            color: Colors.blue,
                            isDarkMode: isDarkMode,
                          ),
                          _buildStatCard(
                            title: 'Empleados Activos',
                            value: empleadosActivos.toString(),
                            total: totalEmpleados.toString(),
                            icon: Icons.people,
                            color: Colors.green,
                            isDarkMode: isDarkMode,
                          ),
                          _buildStatCard(
                            title: 'Asistencias Hoy',
                            value: asistenciasHoy.toString(),
                            total: empleadosActivos.toString(),
                            icon: Icons.calendar_today,
                            color: Colors.orange,
                            isDarkMode: isDarkMode,
                          ),
                          _buildStatCard(
                            title: 'Tasa de Asistencia',
                            value: '${tasaAsistencia.toStringAsFixed(0)}%',
                            description: 'Hoy',
                            icon: Icons.analytics,
                            color: Colors.cyan,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      
                      _buildSectionHeader(
                        title: 'Asistencias Hoy por Sede',
                        actionLabel: 'Ver detalle',
                        onAction: () => widget.onNavigateToTab?.call(3),
                      ),
                      const SizedBox(height: 16),
                      _buildAsistenciasSedeChart(asistenciasPorSedeHoy, sedes, isDarkMode),
                      
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader(
                        title: 'Sedes Recientes',
                        actionLabel: sedes.length > 5 ? 'Ver todas' : null,
                        onAction: sedes.length > 5 ? () => widget.onNavigateToTab?.call(1) : null,
                      ),
                      const SizedBox(height: 16),
                      
                      ...sedes.take(5).map((sede) => _buildSedeCard(
                        sede, 
                        empleados, 
                        asistenciasPorSedeHoy[sede.id] ?? 0,
                        isDarkMode,
                      )),
                      
                      const SizedBox(height: 24),
                      
                      _buildSummaryCard(
                        totalSedes: totalSedes,
                        sedesActivas: sedesActivas,
                        totalEmpleados: totalEmpleados,
                        empleadosActivos: empleadosActivos,
                        asistenciasHoy: asistenciasHoy,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Ocurrió un error', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text('Estadísticas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  // ===== INICIO DE LA CORRECCIÓN =====
  Widget _buildSectionHeader({ required String title, String? actionLabel, VoidCallback? onAction }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Se envuelve el Text del título en un Expanded para que ocupe el espacio
          // restante y evite que el botón cause un desbordamiento.
          Expanded(
            child: Text(
              title, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis, // Corta el texto con "..." si no cabe
              maxLines: 1,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            )
        ],
      ),
    );
  }
  // ===== FIN DE LA CORRECCIÓN =====

  Widget _buildStatCard({
    required String title, required String value, String? total,
    String? description, required IconData icon, required Color color,
    required bool isDarkMode,
  }) {
    final cardColor = isDarkMode ? Color.alphaBlend(color.withOpacity(0.2), Colors.grey[900]!) : color.withOpacity(0.1);
    final borderColor = isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                if (total != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Total: $total', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            if (description != null)
              Text(
                description,
                style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciasSedeChart(Map<String, int> asistenciasPorSede, List<Sede> sedes, bool isDarkMode) {
    final activeColor = Theme.of(context).primaryColor;
    final sedesConAsistencias = sedes
        .where((sede) => (asistenciasPorSede[sede.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (asistenciasPorSede[b.id] ?? 0).compareTo(asistenciasPorSede[a.id] ?? 0));
    
    if (sedesConAsistencias.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined, size: 48, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No hay asistencias registradas hoy',
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxSedesAMostrar = (constraints.maxWidth / 60).floor().clamp(1, 8);
          final sedesAMostrar = sedesConAsistencias.take(maxSedesAMostrar).toList();
          final maxAsistencias = sedesAMostrar.isNotEmpty 
              ? sedesAMostrar.map((s) => asistenciasPorSede[s.id] ?? 0).reduce((a, b) => a > b ? a : b)
              : 1;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text('Distribución de Asistencias', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: sedesAMostrar.map((sede) {
                      final asistencias = asistenciasPorSede[sede.id] ?? 0;
                      final barHeight = maxAsistencias > 0 ? (asistencias / maxAsistencias) * 120 : 4.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildBarChartItem(
                          label: _getShortSedeName(sede.nombre),
                          value: asistencias,
                          barHeight: barHeight,
                          color: activeColor,
                          isDarkMode: isDarkMode,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  String _getShortSedeName(String nombreCompleto) {
    final palabras = nombreCompleto.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.isEmpty) return '';
    if (palabras.length == 1) {
      return nombreCompleto.length > 10 ? '${nombreCompleto.substring(0, 8)}.' : nombreCompleto;
    }
    if (palabras.length > 2) {
      return palabras.take(3).map((p) => p[0].toUpperCase()).join('');
    }
    return palabras.join(' ');
  }

  Widget _buildBarChartItem({
    required String label, required int value, required double barHeight,
    required Color color, required bool isDarkMode,
  }) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (value > 0)
            Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: barHeight.clamp(4.0, 120.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSedeCard(Sede sede, List<Empleado> allEmpleados, int asistenciasHoy, bool isDarkMode) {
    final empleadosSede = allEmpleados.where((emp) => emp.sedeId == sede.id).toList();
    final empleadosActivos = empleadosSede.where((emp) => emp.activo).length;
    final porcentajeAsistencias = empleadosActivos > 0 ? (asistenciasHoy / empleadosActivos * 100).toStringAsFixed(0) : '0';

    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final statusColor = sede.activa ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!, width: 1),
      ),
      color: cardColor,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sede.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    sede.activa ? 'Activa' : 'Inactiva',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildSedeDataItem(title: 'Empleados Activos', value: empleadosActivos.toString(), isDarkMode: isDarkMode),
                _buildSedeDataItem(title: 'Asistencias Hoy', value: asistenciasHoy.toString(), isDarkMode: isDarkMode),
                _buildSedeDataItem(title: 'Tasa Asistencia', value: '$porcentajeAsistencias%', isDarkMode: isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSedeDataItem({ required String title, required String value, required bool isDarkMode }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int totalSedes, required int sedesActivas,
    required int totalEmpleados, required int empleadosActivos,
    required int asistenciasHoy, required bool isDarkMode,
  }) {
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.grey[100];
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen General', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSummaryRow(label: 'Total de sedes:', value: totalSedes.toString(), isDarkMode: isDarkMode),
            _buildSummaryRow(label: 'Sedes activas:', value: sedesActivas.toString(), isDarkMode: isDarkMode),
            const Divider(height: 20),
            _buildSummaryRow(label: 'Total de empleados:', value: totalEmpleados.toString(), isDarkMode: isDarkMode),
            _buildSummaryRow(label: 'Empleados activos:', value: empleadosActivos.toString(), isDarkMode: isDarkMode),
             const Divider(height: 20),
            _buildSummaryRow(label: 'Asistencias registradas hoy:', value: asistenciasHoy.toString(), isDarkMode: isDarkMode),
            _buildSummaryRow(
              label: 'Porcentaje de asistencia hoy:',
              value: empleadosActivos > 0 ? '${(asistenciasHoy / empleadosActivos * 100).toStringAsFixed(1)}%' : 'N/A',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({ required String label, required String value, required bool isDarkMode }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700], fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}