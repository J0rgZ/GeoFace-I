// -----------------------------------------------------------------------------
// @Encabezado:   Página de Historial de Asistencias para Empleados
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página donde los empleados pueden
//               consultar su historial completo de asistencias. Incluye filtros
//               por fecha, vista de calendario, estadísticas y un diseño mejorado
//               para facilitar la consulta de registros históricos.
//
// @NombreArchivo: historial_asistencias_page.dart
// @Ubicacion:    lib/views/empleado/historial_asistencias_page.dart
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
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/asistencia_controller.dart';
import '../../models/asistencia.dart';
import '../../models/empleado.dart';
import '../../models/usuario.dart';
import '../../services/empleado_service.dart';

class HistorialAsistenciasPage extends StatefulWidget {
  const HistorialAsistenciasPage({super.key});

  @override
  State<HistorialAsistenciasPage> createState() => _HistorialAsistenciasPageState();
}

class _HistorialAsistenciasPageState extends State<HistorialAsistenciasPage> {
  final EmpleadoService _empleadoService = EmpleadoService();
  Empleado? _empleado;
  bool _loading = true;
  
  // Estados para vista
  bool _vistaLista = true; // true = lista, false = calendario
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _estadisticasVisible = true; // Control de visibilidad de estadísticas
  
  // Estados para paginación/scroll infinito
  static const int _itemsPerPage = 20;
  int _displayedItems = _itemsPerPage;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _scrollListenerAdded = false;
  
  @override
  void dispose() {
    if (_scrollListenerAdded) {
      _scrollController.removeListener(_onScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Esperar a que el frame esté completo antes de cargar datos y navegar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSeguridadYcargarDatos();
    });
  }
  
  void _verificarSeguridadYcargarDatos() async {
    if (!mounted) return;
    
    // Esperar un momento para que AuthController cargue los datos del usuario
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final authController = context.read<AuthController>();
    
    // Intentar obtener el usuario, esperando si es necesario
    Usuario? usuario = authController.currentUser;
    int intentos = 0;
    while ((usuario == null || !usuario.isEmpleado || usuario.empleadoId == null) && intentos < 5 && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      usuario = authController.currentUser;
      intentos++;
    }
    
    if (!mounted) return;
    
    // Verificación de seguridad inicial
    if (usuario == null || !usuario.isEmpleado || usuario.empleadoId == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
      return;
    }
    
    // Si pasa la verificación, cargar datos
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    
    final authController = context.read<AuthController>();
    final usuario = authController.currentUser;
    
    // Validación de seguridad: verificar que el usuario es empleado y tiene empleadoId
    if (usuario == null || !usuario.isEmpleado || usuario.empleadoId == null) {
      return; // Ya se manejó en _verificarSeguridadYcargarDatos
    }
    
    try {
      final empleado = await _empleadoService.getEmpleadoById(usuario.empleadoId!);
      
      // Validación de seguridad: verificar que el empleadoId del usuario coincide
      if (empleado == null || empleado.id != usuario.empleadoId) {
        if (mounted) {
          // Usar un microtask para evitar llamar showSnackBar durante build
          Future.microtask(() {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error de seguridad: No se pudo verificar la identidad del empleado'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            }
          });
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _empleado = empleado;
          _loading = false;
        });
        
        final asistenciaController = context.read<AsistenciaController>();
        // Verificar seguridad: solo cargar asistencias del empleado autenticado
        await asistenciaController.getAsistenciasByEmpleado(empleado.id);
        
        // Configurar scroll listener para paginación (solo una vez)
        if (!_scrollListenerAdded) {
          _scrollController.addListener(_onScroll);
          _scrollListenerAdded = true;
        }
        // Resetear contador de elementos mostrados
        setState(() {
          _displayedItems = _itemsPerPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        // Usar microtask para evitar llamar showSnackBar durante build
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cargar datos: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }


  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreItems();
    }
  }
  
  void _loadMoreItems() {
    if (_isLoadingMore) return;
    
    final asistenciaController = context.read<AsistenciaController>();
    final totalItems = asistenciaController.asistencias.length;
    
    if (_displayedItems < totalItems) {
      setState(() {
        _isLoadingMore = true;
      });
      
      // Simular carga asíncrona para mejor UX
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _displayedItems = (_displayedItems + _itemsPerPage).clamp(0, totalItems);
            _isLoadingMore = false;
          });
        }
      });
    }
  }
  
  Map<DateTime, List<Asistencia>> _getAsistenciasPorFecha(List<Asistencia> asistencias) {
    final map = <DateTime, List<Asistencia>>{};
    for (var asistencia in asistencias) {
      final fecha = DateTime(
        asistencia.fechaHoraEntrada.year,
        asistencia.fechaHoraEntrada.month,
        asistencia.fechaHoraEntrada.day,
      );
      if (!map.containsKey(fecha)) {
        map[fecha] = [];
      }
      map[fecha]!.add(asistencia);
    }
    return map;
  }

  List<Asistencia> _getAsistenciasDelDia(DateTime dia, List<Asistencia> asistencias) {
    final fecha = DateTime(dia.year, dia.month, dia.day);
    return asistencias.where((a) {
      final fechaAsistencia = DateTime(
        a.fechaHoraEntrada.year,
        a.fechaHoraEntrada.month,
        a.fechaHoraEntrada.day,
      );
      return fechaAsistencia.isAtSameMomentAs(fecha);
    }).toList();
  }

  Widget _buildEstadisticas(List<Asistencia> asistencias, ThemeData theme, ColorScheme colorScheme) {
    final asistenciasCompletas = asistencias.where((a) => a.fechaHoraSalida != null).length;
    final asistenciasPendientes = asistencias.where((a) => a.fechaHoraSalida == null).length;
    final totalHoras = asistencias
        .where((a) => a.fechaHoraSalida != null)
        .fold<Duration>(Duration.zero, (sum, a) => sum + a.fechaHoraSalida!.difference(a.fechaHoraEntrada));
    
    // Formatear horas de manera más compacta
    String formatHoras(Duration duration) {
      final horas = duration.inHours;
      final minutos = duration.inMinutes.remainder(60);
      if (horas > 0) {
        return minutos > 0 ? '${horas}h ${minutos}m' : '${horas}h';
      }
      return '${minutos}m';
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.6),
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con botón para colapsar
            InkWell(
              onTap: () {
                setState(() {
                  _estadisticasVisible = !_estadisticasVisible;
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resumen de Asistencias',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _estadisticasVisible ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            if (_estadisticasVisible) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCardMejorado(
                        'Completas',
                        asistenciasCompletas.toString(),
                        Icons.check_circle_rounded,
                        Colors.green,
                        theme,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCardMejorado(
                        'Pendientes',
                        asistenciasPendientes.toString(),
                        Icons.pending_rounded,
                        Colors.orange,
                        theme,
                        colorScheme,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCardMejorado(
                        'Total Horas',
                        formatHoras(totalHoras),
                        Icons.access_time_rounded,
                        colorScheme.primary,
                        theme,
                        colorScheme,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardMejorado(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asistenciaController = context.watch<AsistenciaController>();

    // Validación de seguridad adicional - solo mostrar error si hay problema
    final authController = context.read<AuthController>();
    final usuario = authController.currentUser;
    
    // Si hay un problema de seguridad, mostrar un widget de error
    if (usuario == null || !usuario.isEmpleado || _empleado == null || (usuario.empleadoId != null && usuario.empleadoId != _empleado!.id)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'No tienes permisos para acceder a esta información',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Estadísticas mejoradas
              if (asistenciaController.asistencias.isNotEmpty)
                _buildEstadisticas(asistenciaController.asistencias, theme, colorScheme),
              const SizedBox(height: 8),
              
              // Barra de herramientas mejorada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                      colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Título de vista (adaptable)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _vistaLista ? Icons.history : Icons.calendar_month,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _vistaLista ? 'Vista Lista' : 'Vista Calendario',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Toggle vista con mejor diseño y animación
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildViewButton(
                            icon: Icons.list,
                            label: 'Lista',
                            isActive: _vistaLista,
                            onTap: () {
                              setState(() {
                                _vistaLista = true;
                              });
                            },
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                          _buildViewButton(
                            icon: Icons.calendar_month,
                            label: 'Calendario',
                            isActive: !_vistaLista,
                            onTap: () {
                              setState(() {
                                _vistaLista = false;
                              });
                            },
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Expanded(
                child: asistenciaController.asistencias.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 80,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay registros de asistencia',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tus registros aparecerán aquí cuando marques tu asistencia',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (_empleado != null) {
                            await asistenciaController.getAsistenciasByEmpleado(_empleado!.id);
                            setState(() {
                              _displayedItems = _itemsPerPage;
                            });
                          }
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _vistaLista
                              ? _buildVistaLista(asistenciaController.asistencias, theme, colorScheme)
                              : _buildVistaCalendario(asistenciaController.asistencias, theme, colorScheme),
                        ),
                      ),
              ),
            ],
          );
  }

  Widget _buildVistaLista(List<Asistencia> asistencias, ThemeData theme, ColorScheme colorScheme) {
    if (asistencias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay registros de asistencia',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tus registros aparecerán aquí cuando marques tu asistencia',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final displayedAsistencias = asistencias.take(_displayedItems).toList();
    final hasMore = _displayedItems < asistencias.length;
    final allItemsShown = !hasMore && displayedAsistencias.isNotEmpty;

    // Calcular el número total de items
    int itemCount = displayedAsistencias.length;
    if (hasMore && _isLoadingMore) {
      itemCount += 1; // Indicador de carga
    } else if (allItemsShown) {
      itemCount += 1; // Mensaje de fin de lista
    }

    return ListView.builder(
      key: const ValueKey('lista_view'),
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Si estamos en el último índice y hay más items o todos están mostrados
        if (index == displayedAsistencias.length) {
          if (hasMore && _isLoadingMore) {
            // Indicador de carga para más elementos
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Cargando más registros...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (allItemsShown) {
            // Mensaje de fin de lista
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No hay más registros',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            );
          }
        }
        
        final asistencia = displayedAsistencias[index];
        return _buildAsistenciaCardMejorado(asistencia, theme, colorScheme);
      },
    );
  }

  Widget _buildVistaCalendario(List<Asistencia> asistencias, ThemeData theme, ColorScheme colorScheme) {
    final asistenciasPorFecha = _getAsistenciasPorFecha(asistencias);
    // Convertir a formato compatible con table_calendar (sin hora)
    final eventSource = <DateTime, List<Asistencia>>{};
    asistenciasPorFecha.forEach((key, value) {
      final dayKey = DateTime(key.year, key.month, key.day);
      eventSource[dayKey] = value;
    });

    return Column(
      key: const ValueKey('calendario_view'),
      children: [
        // Calendario mejorado con table_calendar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar<Asistencia>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final dayKey = DateTime(day.year, day.month, day.day);
              return eventSource[dayKey] ?? [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: colorScheme.primary),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              markerDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 8,
              markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.primary),
              titleTextStyle: (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
        ),
        // Lista de asistencias del día seleccionado
        Expanded(
          child: _buildListaDiaSeleccionado(_selectedDay, asistencias, theme, colorScheme),
        ),
      ],
    );
  }


  Widget _buildListaDiaSeleccionado(DateTime dia, List<Asistencia> asistencias, ThemeData theme, ColorScheme colorScheme) {
    final asistenciasDelDia = _getAsistenciasDelDia(dia, asistencias);
    final esHoy = isSameDay(dia, DateTime.now());

    if (asistenciasDelDia.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                esHoy 
                    ? 'No hay registros para hoy'
                    : 'No hay registros para ${DateFormat('dd/MM/yyyy').format(dia)}',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Las asistencias del día seleccionado aparecerán aquí',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: asistenciasDelDia.length,
      itemBuilder: (context, index) {
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _buildAsistenciaCardMejorado(asistenciasDelDia[index], theme, colorScheme),
        );
      },
    );
  }

  Widget _buildAsistenciaCardMejorado(Asistencia asistencia, ThemeData theme, ColorScheme colorScheme) {
    final fechaEntrada = asistencia.fechaHoraEntrada;
    final fechaSalida = asistencia.fechaHoraSalida;
    final horaEntrada = DateFormat('HH:mm:ss').format(fechaEntrada);
    final horaSalida = fechaSalida != null ? DateFormat('HH:mm:ss').format(fechaSalida) : null;

    // Calcular duración
    String? duracion;
    Duration? diferencia;
    if (fechaSalida != null) {
      diferencia = fechaSalida.difference(fechaEntrada);
      final horas = diferencia.inHours;
      final minutos = diferencia.inMinutes.remainder(60);
      final segundos = diferencia.inSeconds.remainder(60);
      duracion = '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    }

    final isCompleta = fechaSalida != null;

    final statusColor = isCompleta ? Colors.green : Colors.orange;
    final statusLightColor = isCompleta ? Colors.green.shade50 : Colors.orange.shade50;
    final statusDarkColor = isCompleta ? Colors.green.shade700 : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleta
              ? [
                  Colors.green.shade50,
                  Colors.white,
                  Colors.green.shade50.withValues(alpha: 0.3),
                ]
              : [
                  Colors.orange.shade50,
                  Colors.white,
                  Colors.orange.shade50.withValues(alpha: 0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _mostrarDetalleAsistencia(asistencia, theme, colorScheme);
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con fecha y estado mejorado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer,
                                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.event_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE', 'es_ES').format(fechaEntrada),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMMM yyyy', 'es_ES').format(fechaEntrada),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusLightColor,
                            statusLightColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleta ? Icons.check_circle_rounded : Icons.pending_rounded,
                            size: 18,
                            color: statusDarkColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCompleta ? 'Completa' : 'Pendiente',
                            style: TextStyle(
                              color: statusDarkColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              
                // Entrada mejorada
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade50,
                        Colors.green.shade50.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade100,
                              Colors.green.shade200,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.login_rounded,
                          color: Colors.green.shade800,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ENTRADA',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              horaEntrada,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                                fontSize: 20,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Salida mejorada
                if (fechaSalida != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade50,
                          Colors.red.shade50.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade100,
                                Colors.red.shade200,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade800,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SALIDA',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                horaSalida!,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                  fontSize: 20,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Duración mejorada
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.6),
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.timer_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Duración: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          duracion!,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade50,
                          Colors.orange.shade50.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pending_rounded,
                          size: 22,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Salida pendiente de registro',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleAsistencia(Asistencia asistencia, ThemeData theme, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de Asistencia',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetalleItem('Fecha', DateFormat('dd/MM/yyyy').format(asistencia.fechaHoraEntrada)),
            _buildDetalleItem('Hora Entrada', DateFormat('HH:mm:ss').format(asistencia.fechaHoraEntrada)),
            if (asistencia.fechaHoraSalida != null)
              _buildDetalleItem('Hora Salida', DateFormat('HH:mm:ss').format(asistencia.fechaHoraSalida!)),
            if (asistencia.fechaHoraSalida != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetalleItem(
                'Duración Total',
                _calcularDuracion(asistencia.fechaHoraEntrada, asistencia.fechaHoraSalida!),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calcularDuracion(DateTime inicio, DateTime fin) {
    final diferencia = fin.difference(inicio);
    final horas = diferencia.inHours;
    final minutos = diferencia.inMinutes.remainder(60);
    final segundos = diferencia.inSeconds.remainder(60);
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }
}
