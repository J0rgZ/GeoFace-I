// -----------------------------------------------------------------------------
// @Encabezado:   Página del Dashboard Administrativo
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página principal del dashboard
//               administrativo de GeoFace. Proporciona una vista general
//               de las estadísticas del sistema, incluyendo métricas de
//               sedes, empleados, asistencias y gráficos de rendimiento.
//               Incluye animaciones, estados de carga con shimmer y
//               navegación a otras secciones administrativas.
//
// @NombreArchivo: dashboard_page.dart
// @Ubicacion:    lib/views/admin/dashboard_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/sede_controller.dart';
import '../../controllers/empleado_controller.dart';
import '../../controllers/asistencia_controller.dart';
import '../../models/sede.dart';
import '../../models/empleado.dart';
import '../../models/asistencia.dart';
import '../../utils/date_utils.dart' as date_utils;
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  const DashboardPage({super.key, this.onNavigateToTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    
    final curvedAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curvedAnimation);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    _animationController.reset();

    final sedeController = Provider.of<SedeController>(context, listen: false);
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    final asistenciaController = Provider.of<AsistenciaController>(context, listen: false);

    await Future.wait([
      sedeController.getSedes(),
      empleadoController.getEmpleados(),
      asistenciaController.getAsistenciasDeHoy(),
    ]);
    
    if (mounted) _animationController.forward();
  }

  int _getAsistenciasHoy(List<Asistencia> asistencias) {
    return asistencias.length;
  }

  Map<String, int> _getAsistenciasPorSedeHoy(List<Asistencia> asistencias, List<Sede> sedes) {
    final hoy = DateTime.now();
    final Map<String, int> asistenciasPorSede = {for (var sede in sedes) sede.id: 0};
    for (var asistencia in asistencias.where((a) => date_utils.isSameDay(a.fechaHoraEntrada, hoy))) {
      if (asistenciasPorSede.containsKey(asistencia.sedeId)) {
        asistenciasPorSede[asistencia.sedeId] = (asistenciasPorSede[asistencia.sedeId] ?? 0) + 1;
      }
    }
    return asistenciasPorSede;
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Consumer3<SedeController, EmpleadoController, AsistenciaController>(
        builder: (context, sedeController, empleadoController, asistenciaController, _) {
          final bool isLoading = sedeController.loading || empleadoController.loading || asistenciaController.loading;
          final String? errorMessage = sedeController.errorMessage ?? empleadoController.errorMessage ?? asistenciaController.errorMessage;

          if (isLoading) {
            return _buildLoadingSkeleton(context);
          }

          if (errorMessage != null) {
            return _buildErrorWidget(context, errorMessage, _loadData);
          }

          final sedes = sedeController.sedes;
          final empleados = empleadoController.empleados;
          final asistencias = asistenciaController.asistencias;
          final sedesActivas = sedes.where((s) => s.activa).length;
          final empleadosActivos = empleados.where((e) => e.activo).length;
          final asistenciasHoy = _getAsistenciasHoy(asistencias);
          final asistenciasPorSedeHoy = _getAsistenciasPorSedeHoy(asistencias, sedes);
          final tasaAsistencia = empleadosActivos > 0 ? (asistenciasHoy / empleadosActivos * 100) : 0.0;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(context)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        sliver: _buildStatsGrid(context,
                          sedesActivas: sedesActivas, totalSedes: sedes.length,
                          empleadosActivos: empleadosActivos, totalEmpleados: empleados.length,
                          asistenciasHoy: asistenciasHoy, tasaAsistencia: tasaAsistencia,
                          constraints: constraints,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildAsistenciasChart(context, asistenciasPorSedeHoy, sedes),
                              const SizedBox(height: 32),
                              _buildSedesSection(context, sedes, empleados, asistenciasPorSedeHoy),
                              const SizedBox(height: 32),
                              _buildInsightCards(context, sedes, empleados, asistencias),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainer,
      highlightColor: theme.colorScheme.surfaceContainerHighest,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.0, crossAxisSpacing: 16, mainAxisSpacing: 16), // <-- AspectRatio ajustado
              delegate: SliverChildBuilderDelegate((context, index) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28))), childCount: 4),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                Container(height: 350, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28))),
                const SizedBox(height: 32),
                Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message, VoidCallback onRetry) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error, size: 56),
          const SizedBox(height: 24),
          Text('Ocurrió un Problema', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Volver a intentar')),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _getGreeting();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 12,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Dashboard', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(100)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text('${now.day}/${now.month}/${now.year}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            ]),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
  
  Widget _buildStatsGrid(BuildContext context, {
    required int sedesActivas, required int totalSedes,
    required int empleadosActivos, required int totalEmpleados,
    required int asistenciasHoy, required double tasaAsistencia,
    required BoxConstraints constraints,
  }) {
    final theme = Theme.of(context);
    final isSmallScreen = constraints.maxWidth < 600;
    final crossAxisCount = isSmallScreen ? 2 : 4;
    // <-- CAMBIO CLAVE: Cambiamos el aspect ratio a 1.0 para hacer las tarjetas cuadradas
    // y menos altas, lo que da más espacio al contenido y evita el overflow.
    final childAspectRatio = isSmallScreen ? 1.0 : 1.25;

    final stats = [
      _StatCardData(title: 'Sedes Activas', value: sedesActivas.toString(), total: totalSedes.toString(), icon: Icons.location_city_rounded, color: theme.colorScheme.primary, onColor: theme.colorScheme.onPrimary),
      _StatCardData(title: 'Empleados', value: empleadosActivos.toString(), total: totalEmpleados.toString(), icon: Icons.people_alt_rounded, color: theme.colorScheme.secondary, onColor: theme.colorScheme.onSecondary),
      _StatCardData(title: 'Asistencias', value: asistenciasHoy.toString(), description: 'Hoy', icon: Icons.check_circle_rounded, color: theme.colorScheme.tertiary, onColor: theme.colorScheme.onTertiary),
      _StatCardData(title: 'Tasa Asistencia', value: '${tasaAsistencia.toStringAsFixed(0)}%', icon: Icons.show_chart_rounded, color: const Color(0xFF00C853), onColor: Colors.white),
    ];

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, childAspectRatio: childAspectRatio, crossAxisSpacing: 16, mainAxisSpacing: 16),
      delegate: SliverChildBuilderDelegate((context, index) => _buildModernStatCard(context, stats[index]), childCount: stats.length),
    );
  }

  // <-- CAMBIO CLAVE: REFACTORIZACIÓN COMPLETA DE LA TARJETA PARA SER RESPONSIVA
  Widget _buildModernStatCard(BuildContext context, _StatCardData data) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [data.color, data.color.withAlpha(200)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: data.color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuye el espacio verticalmente
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: data.onColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: Icon(data.icon, color: data.onColor, size: 24),
              ),
              if (data.total != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: data.onColor.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                  child: Text('de ${data.total}', style: theme.textTheme.labelMedium?.copyWith(color: data.onColor)),
                ),
            ],
          ),
          
          // <-- SOLUCIÓN DEFINITIVA: Un FittedBox que envuelve todo el contenido inferior.
          // Esto escala todo el bloque de texto (número, título, descripción) para que
          // quepa perfectamente en el espacio restante, eliminando cualquier overflow.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: data.onColor,
                    fontWeight: FontWeight.bold,
                    height: 1.0, // Altura de línea compacta para ganar espacio
                  ),
                ),
                Text(
                  data.title,
                  // Usamos un estilo un poco más compacto para el título.
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: data.onColor,
                    fontWeight: FontWeight.w500
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (data.description != null)
                  Text(
                    data.description!,
                    style: theme.textTheme.bodySmall?.copyWith(color: data.onColor.withOpacity(0.7)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAsistenciasChart(BuildContext context, Map<String, int> asistenciasPorSede, List<Sede> sedes) {
    final theme = Theme.of(context);
    final sedesConAsistencias = sedes.where((sede) => (asistenciasPorSede[sede.id] ?? 0) > 0).toList()
      ..sort((a, b) => (asistenciasPorSede[b.id] ?? 0).compareTo(asistenciasPorSede[a.id] ?? 0));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionHeader(context, icon: Icons.bar_chart_rounded, color: theme.colorScheme.primary, title: 'Asistencias por Sede', subtitle: 'Distribución del día de hoy', onSeeMore: () => widget.onNavigateToTab?.call(3)),
        const SizedBox(height: 24),
        if (sedesConAsistencias.isEmpty)
          _buildEmptyState(context, icon: Icons.analytics_outlined, text: 'Sin asistencias para mostrar hoy.')
        else
          _buildChartContent(context, sedesConAsistencias, asistenciasPorSede),
      ]),
    );
  }
  
  Widget _buildChartContent(BuildContext context, List<Sede> sedes, Map<String, int> asistenciasPorSede) {
    final theme = Theme.of(context);
    final maxAsistencias = sedes.map((s) => asistenciasPorSede[s.id] ?? 0).fold(1, (p, c) => c > p ? c : p);
  
    return SizedBox(
      height: 250,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(math.min(sedes.length, 10), (index) {
            final sede = sedes[index];
            final asistencias = asistenciasPorSede[sede.id] ?? 0;
            final percentage = asistencias / maxAsistencias;
            final barHeight = 150.0 * percentage;
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 50)),
              tween: Tween(begin: 0.0, end: barHeight),
              curve: Curves.elasticOut,
              builder: (context, animatedHeight, child) {
                return Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (asistencias > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                          child: Text(asistencias.toString(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        width: 40,
                        height: animatedHeight.clamp(4.0, 150.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(150),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          border: Border.all(color: theme.colorScheme.primary, width: 2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // <-- CAMBIO CLAVE: Usamos Flexible para que el texto se adapte sin causar overflow.
                      Flexible(
                        child: Text(
                          sede.nombre,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSedesSection(BuildContext context, List<Sede> sedes, List<Empleado> empleados, Map<String, int> asistenciasPorSedeHoy) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionHeader(context, icon: Icons.business_rounded, color: theme.colorScheme.secondary, title: 'Sedes Principales', subtitle: 'Rendimiento de hoy', onSeeMore: () => widget.onNavigateToTab?.call(0)),
        const SizedBox(height: 24),
        if (sedes.isEmpty)
          _buildEmptyState(context, icon: Icons.add_business_rounded, text: 'Aún no has registrado sedes.')
        else
          ListView.separated(
            itemCount: math.min(sedes.length, 4),
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sede = sedes[index];
              return _buildSedeCard(context, sede, empleados.where((e) => e.sedeId == sede.id).length, asistenciasPorSedeHoy[sede.id] ?? 0);
            },
          )
      ]),
    );
  }

  // <-- CAMBIO CLAVE: Tarjeta más compacta
  Widget _buildSedeCard(BuildContext context, Sede sede, int empleados, int asistencias) {
    final theme = Theme.of(context);
    final tasaAsistencia = empleados > 0 ? (asistencias / empleados * 100) : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Padding reducido
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: sede.activa ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(18)),
          child: Icon(sede.activa ? Icons.business_rounded : Icons.business_outlined, color: sede.activa ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(sede.nombre, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6), // Espacio reducido
          Wrap(spacing: 12, runSpacing: 4, children: [ // Espaciado del Wrap reducido
            _buildStatChip(context, Icons.people_outline_rounded, '$empleados emp.'),
            _buildStatChip(context, Icons.check_circle_outline_rounded, '$asistencias asist.'),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pie_chart_outline_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text('${tasaAsistencia.toStringAsFixed(0)}%', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ])),
      ]),
    );
  }
  
  Widget _buildInsightCards(BuildContext context, List<Sede> sedes, List<Empleado> empleados, List<Asistencia> asistencias) {
    final theme = Theme.of(context);
    final insights = _generateInsights(context, sedes, empleados, asistencias);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(context, icon: Icons.lightbulb_outline_rounded, color: theme.colorScheme.tertiary, title: 'Insights', subtitle: 'Análisis inteligente de tus datos'),
      const SizedBox(height: 24),
      if (insights.isEmpty)
        _buildEmptyState(context, icon: Icons.science_outlined, text: 'No hay insights para mostrar.')
      else
        ListView.separated(
          itemCount: insights.length, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildInsightCard(context, insights[index]),
        ),
    ]);
  }

  Widget _buildInsightCard(BuildContext context, _InsightData insight) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: insight.color, width: 5)),
      ),
      child: Row(children: [
        Icon(insight.icon, color: insight.color, size: 32),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(insight.title, style: theme.textTheme.titleMedium?.copyWith(color: insight.color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(insight.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, VoidCallback? onSeeMore}) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: color, size: 28),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ])),
      if (onSeeMore != null)
        TextButton(onPressed: onSeeMore, child: const Text('Ver más')),
    ]);
  }

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return SizedBox( // Cambiado a SizedBox para no forzar una altura fija siempre
      height: 150,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(text, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 6),
      Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }

  List<_InsightData> _generateInsights(BuildContext context, List<Sede> sedes, List<Empleado> empleados, List<Asistencia> asistencias) {
    final theme = Theme.of(context);
    final insights = <_InsightData>[];
    final hoy = DateTime.now();
    final asistenciasHoy = asistencias.where((a) => date_utils.isSameDay(a.fechaHoraEntrada, hoy)).length;
    final empleadosActivos = empleados.where((e) => e.activo).length;
    final sedesActivas = sedes.where((s) => s.activa).length;

    if (empleadosActivos > 0) {
      final tasaAsistencia = (asistenciasHoy / empleadosActivos * 100);
      if (tasaAsistencia >= 90) {
        insights.add(_InsightData(title: 'Asistencia Ejemplar', description: 'Con un ${tasaAsistencia.toStringAsFixed(0)}% de asistencia, el compromiso es máximo. ¡Excelente trabajo!', icon: Icons.emoji_events_rounded, color: const Color(0xFFFFC107)));
      } else if (tasaAsistencia < 70 && asistenciasHoy > 0) {
        insights.add(_InsightData(title: 'Asistencia Baja', description: 'La tasa de ${tasaAsistencia.toStringAsFixed(0)}% es menor a la esperada. Se recomienda seguimiento.', icon: Icons.trending_down_rounded, color: theme.colorScheme.error));
      }
    }

    final sedesInactivas = sedes.length - sedesActivas;
    if (sedesInactivas > 0) {
      insights.add(_InsightData(title: '$sedesInactivas Sede${sedesInactivas > 1 ? 's' : ''} Inactiva${sedesInactivas > 1 ? 's' : ''}', description: 'Hay sedes que no están operativas. Revisa su estado para no perder datos.', icon: Icons.power_settings_new_rounded, color: theme.colorScheme.secondary));
    }

    if (insights.isEmpty) {
      insights.add(_InsightData(title: 'Operando con Normalidad', description: 'Todos los indicadores se encuentran dentro de los parámetros esperados. Buen trabajo de monitoreo.', icon: Icons.check_circle_outline_rounded, color: theme.colorScheme.primary));
    }
    return insights;
  }
}

class _StatCardData {
  final String title, value; final String? total, description; final IconData icon; final Color color, onColor;
  _StatCardData({required this.title, required this.value, this.total, this.description, required this.icon, required this.color, required this.onColor});
}
class _InsightData {
  final String title, description; final IconData icon; final Color color;
  _InsightData({required this.title, required this.description, required this.icon, required this.color});
}