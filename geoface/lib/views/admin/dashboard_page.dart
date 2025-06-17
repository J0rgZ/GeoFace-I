// views/admin/dashboard_page.dart
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

class _DashboardPageState extends State<DashboardPage> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    
    _animationController.forward();
  }

  int _getAsistenciasHoy(List<Asistencia> asistencias) {
    final hoy = DateTime.now();
    return asistencias.where((a) => date_utils.isSameDay(a.fechaHoraEntrada, hoy)).length;
  }

  Map<String, int> _getAsistenciasPorSedeHoy(List<Asistencia> asistencias, List<Sede> sedes) {
    final hoy = DateTime.now();
    final Map<String, int> asistenciasPorSede = {for (var sede in sedes) sede.id: 0};

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
    return RefreshIndicator(
      onRefresh: () async {
        _animationController.reset();
        await _loadData();
      },
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Consumer3<SedeController, EmpleadoController, AsistenciaController>(
        builder: (context, sedeController, empleadoController, asistenciaController, _) {
          if (sedeController.loading || empleadoController.loading || asistenciaController.loading) {
            return _buildLoadingWidget(context);
          }

          final errorMessage = sedeController.errorMessage ?? 
                              empleadoController.errorMessage ?? 
                              asistenciaController.errorMessage;
          if (errorMessage != null) {
            return _buildErrorWidget(context, errorMessage, _loadData);
          }

          final sedes = sedeController.sedes;
          final empleados = empleadoController.empleados;
          final asistencias = asistenciaController.asistencias;

          final sedesActivas = sedes.where((sede) => sede.activa).length;
          final empleadosActivos = empleados.where((emp) => emp.activo).length;
          final asistenciasHoy = _getAsistenciasHoy(asistencias);
          final asistenciasPorSedeHoy = _getAsistenciasPorSedeHoy(asistencias, sedes);
          final tasaAsistencia = empleadosActivos > 0 
              ? (asistenciasHoy / empleadosActivos * 100) 
              : 0.0;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHeader(context),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: _buildStatsGrid(
                          context,
                          sedesActivas: sedesActivas,
                          totalSedes: sedes.length,
                          empleadosActivos: empleadosActivos,
                          totalEmpleados: empleados.length,
                          asistenciasHoy: asistenciasHoy,
                          tasaAsistencia: tasaAsistencia,
                          constraints: constraints,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              _buildAsistenciasChart(context, asistenciasPorSedeHoy, sedes),
                              const SizedBox(height: 32),
                              _buildSedesSection(context, sedes, empleados, asistenciasPorSedeHoy),
                              const SizedBox(height: 32),
                              _buildInsightCards(context, sedes, empleados, asistencias),
                              const SizedBox(height: 20),
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

  // --- WIDGETS DE CONSTRUCCIÓN MODERNOS ---

  Widget _buildLoadingWidget(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando estadísticas...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message, VoidCallback onRetry) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.error.withOpacity(0.05),
            theme.colorScheme.errorContainer.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.onErrorContainer,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Algo salió mal',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _getGreeting();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Usar Wrap en lugar de Row para pantallas muy pequeñas
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Pantallas muy pequeñas - stack vertical
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dashboard',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${now.day}/${now.month}/${now.year}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Pantallas normales - layout horizontal
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dashboard',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${now.day}/${now.month}/${now.year}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
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

  Widget _buildStatsGrid(
    BuildContext context, {
    required int sedesActivas,
    required int totalSedes,
    required int empleadosActivos,
    required int totalEmpleados,
    required int asistenciasHoy,
    required double tasaAsistencia,
    required BoxConstraints constraints,
  }) {
    final isSmallScreen = constraints.maxWidth < 600;
    final crossAxisCount = isSmallScreen ? 2 : 4;

    final stats = [
      _StatCardData(
        title: 'Sedes Activas',
        value: sedesActivas.toString(),
        total: totalSedes.toString(),
        icon: Icons.location_city_rounded,
        gradient: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ],
      ),
      _StatCardData(
        title: 'Empleados Activos',
        value: empleadosActivos.toString(),
        total: totalEmpleados.toString(),
        icon: Icons.people_rounded,
        gradient: [
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.secondary.withOpacity(0.7),
        ],
      ),
      _StatCardData(
        title: 'Asistencias Hoy',
        value: asistenciasHoy.toString(),
        total: empleadosActivos.toString(),
        icon: Icons.check_circle_rounded,
        gradient: [
          Theme.of(context).colorScheme.tertiary,
          Theme.of(context).colorScheme.tertiary.withOpacity(0.7),
        ],
      ),
      _StatCardData(
        title: 'Tasa de Asistencia',
        value: '${tasaAsistencia.toStringAsFixed(0)}%',
        description: 'Hoy',
        icon: Icons.trending_up_rounded,
        gradient: [
          Colors.orange,
          Colors.orange.withOpacity(0.7),
        ],
      ),
    ];

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isSmallScreen ? 1.4 : 1.2,
        crossAxisSpacing: 17,
        mainAxisSpacing: 17,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildModernStatCard(context, stats[index], index),
        childCount: stats.length,
      ),
    );
  }

  Widget _buildModernStatCard(BuildContext context, _StatCardData data, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: data.gradient.first.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Patrón de fondo
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    left: -10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  // Contenido con mejor manejo de espacio
                  Padding(
                    padding: const EdgeInsets.all(16), // Reducido de 20 a 16
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
                      children: [
                        // Header con iconos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10), // Reducido de 12 a 10
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14), // Reducido de 16 a 14
                              ),
                              child: Icon(
                                data.icon,
                                color: Colors.white,
                                size: 20, // Reducido de 24 a 20
                              ),
                            ),
                            if (data.total != null)
                              Flexible( // Agregado Flexible
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6, // Reducido de 8 a 6
                                    vertical: 3, // Reducido de 4 a 3
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                                  ),
                                  child: Text(
                                    '/${data.total}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10, // Reducido de 12 a 10
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8), // Reducido de Spacer
                        // Valor principal
                        Flexible( // Agregado Flexible
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              data.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28, // Reducido de 32 a 28
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Título
                        Flexible( // Agregado Flexible
                          child: Text(
                            data.title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12, // Reducido de 14 a 12
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Descripción opcional
                        if (data.description != null) ...[
                          const SizedBox(height: 2), // Reducido de 4 a 2
                          Flexible( // Agregado Flexible
                            child: Text(
                              data.description!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10, // Reducido de 12 a 10
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsistenciasChart(BuildContext context, Map<String, int> asistenciasPorSede, List<Sede> sedes) {
    final theme = Theme.of(context);
    final sedesConAsistencias = sedes
        .where((sede) => (asistenciasPorSede[sede.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (asistenciasPorSede[b.id] ?? 0).compareTo(asistenciasPorSede[a.id] ?? 0));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistencias por Sede',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Distribución del día de hoy',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => widget.onNavigateToTab?.call(3),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                label: const Text('Ver más'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (sedesConAsistencias.isEmpty)
            _buildEmptyChart(context)
          else
            _buildChart(context, sedesConAsistencias, asistenciasPorSede),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin asistencias registradas',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los datos aparecerán aquí cuando se registren asistencias',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<Sede> sedes, Map<String, int> asistenciasPorSede) {
    final theme = Theme.of(context);
    final maxAsistencias = sedes
        .map((s) => asistenciasPorSede[s.id] ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 240,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: sedes.take(8).map((sede) {
            final asistencias = asistenciasPorSede[sede.id] ?? 0;
            final percentage = maxAsistencias > 0 ? asistencias / maxAsistencias : 0.0;
            final barHeight = 160 * percentage;
            
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: barHeight),
              curve: Curves.easeOutCubic,
              builder: (context, animatedHeight, child) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (asistencias > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            asistencias.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Container(
                        width: 32,
                        height: animatedHeight.clamp(4.0, 160.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 56,
                        child: Text(
                          _getShortSedeName(sede.nombre),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getShortSedeName(String nombreCompleto) {
    final palabras = nombreCompleto.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (palabras.isEmpty) return '';
    if (palabras.length == 1) {
      return nombreCompleto.length > 8 ? '${nombreCompleto.substring(0, 6)}..' : nombreCompleto;
    }
    if (palabras.length > 2) {
      return palabras.take(3).map((p) => p[0].toUpperCase()).join('');
    }
    return palabras.join(' ');
  }

  Widget _buildSedesSection(BuildContext context, List<Sede> sedes, List<Empleado> empleados, Map<String, int> asistenciasPorSedeHoy) {
    final theme = Theme.of(context);
    final sedesRecientes = sedes.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sedes Principales',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rendimiento de hoy',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => widget.onNavigateToTab?.call(0),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                label: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (sedesRecientes.isEmpty)
            _buildEmptySedes(context)
          else
            Column(
              children: sedesRecientes.map((sede) => _buildSedeCard(
                context,
                sede,
                empleados.where((e) => e.sedeId == sede.id).length,
                asistenciasPorSedeHoy[sede.id] ?? 0,
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySedes(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'Sin sedes registradas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeCard(BuildContext context, Sede sede, int empleados, int asistencias) {
    final theme = Theme.of(context);
    final tasaAsistencia = empleados > 0 ? (asistencias / empleados * 100) : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16), // Reducido de 20 a 16
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Icono de sede
          Container(
            width: 45, // Reducido de 50 a 45
            height: 45, // Reducido de 50 a 45
            decoration: BoxDecoration(
              color: sede.activa
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14), // Reducido de 16 a 14
            ),
            child: Icon(
              sede.activa ? Icons.business_rounded : Icons.business_outlined,
              color: sede.activa
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onErrorContainer,
              size: 22, // Reducido de 24 a 22
            ),
          ),
          const SizedBox(width: 12), // Reducido de 16 a 12
          // Contenido expandible
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila con nombre y estado
                Row(
                  children: [
                    Expanded(
                      flex: 3, // Más espacio para el nombre
                      child: Text(
                        sede.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Reducido para pantallas pequeñas
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible( // Cambiado de Container directo a Flexible
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reducido
                        decoration: BoxDecoration(
                          color: sede.activa
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10), // Reducido de 12 a 10
                        ),
                        child: Text(
                          sede.activa ? 'Activa' : 'Inactiva',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: sede.activa
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 10, // Reducido
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6), // Reducido de 8 a 6
                // Fila con estadísticas - USANDO WRAP PARA EVITAR OVERFLOW
                Wrap(
                  spacing: 12, // Espacio entre elementos
                  runSpacing: 4, // Espacio entre líneas si se envuelve
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14, // Reducido de 16 a 14
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$empleados emp.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11, // Reducido
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14, // Reducido de 16 a 14
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$asistencias asist.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11, // Reducido
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${tasaAsistencia.toStringAsFixed(0)}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12, // Reducido
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCards(BuildContext context, List<Sede> sedes, List<Empleado> empleados, List<Asistencia> asistencias) {
    final theme = Theme.of(context);
    final insights = _generateInsights(sedes, empleados, asistencias);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: theme.colorScheme.onTertiaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Análisis inteligente de tus datos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...insights.map((insight) => _buildInsightCard(context, insight)),
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context, _InsightData insight) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: insight.color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              insight.icon,
              color: insight.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_InsightData> _generateInsights(List<Sede> sedes, List<Empleado> empleados, List<Asistencia> asistencias) {
    final insights = <_InsightData>[];
    final hoy = DateTime.now();
    final asistenciasHoy = asistencias.where((a) => date_utils.isSameDay(a.fechaHoraEntrada, hoy)).length;
    final empleadosActivos = empleados.where((e) => e.activo).length;
    final sedesActivas = sedes.where((s) => s.activa).length;

    // Insight sobre asistencias
    if (empleadosActivos > 0) {
      final tasaAsistencia = (asistenciasHoy / empleadosActivos * 100);
      if (tasaAsistencia >= 80) {
        insights.add(_InsightData(
          title: 'Excelente asistencia',
          description: 'La tasa de asistencia de hoy es del ${tasaAsistencia.toStringAsFixed(0)}%. ¡Muy bien!',
          icon: Icons.trending_up_rounded,
          color: Colors.green,
        ));
      } else if (tasaAsistencia < 60) {
        insights.add(_InsightData(
          title: 'Baja asistencia',
          description: 'La asistencia está por debajo del promedio (${tasaAsistencia.toStringAsFixed(0)}%). Revisa las notificaciones.',
          icon: Icons.trending_down_rounded,
          color: Colors.orange,
        ));
      }
    }

    // Insight sobre sedes
    if (sedesActivas < sedes.length) {
      final sedesInactivas = sedes.length - sedesActivas;
      insights.add(_InsightData(
        title: 'Sedes inactivas',
        description: 'Tienes $sedesInactivas sede${sedesInactivas > 1 ? 's' : ''} inactiva${sedesInactivas > 1 ? 's' : ''}. Considera reactivarlas.',
        icon: Icons.business_outlined,
        color: Colors.blue,
      ));
    }

    // Si no hay insights específicos, mostrar uno general
    if (insights.isEmpty) {
      insights.add(_InsightData(
        title: 'Todo en orden',
        description: 'El sistema está funcionando correctamente. Continúa monitoreando el rendimiento.',
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
      ));
    }

    return insights;
  }
}

// Clases de datos auxiliares
class _StatCardData {
  final String title;
  final String value;
  final String? total;
  final String? description;
  final IconData icon;
  final List<Color> gradient;

  _StatCardData({
    required this.title,
    required this.value,
    this.total,
    this.description,
    required this.icon,
    required this.gradient,
  });
}

class _InsightData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _InsightData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}