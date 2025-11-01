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
import '../../controllers/auth_controller.dart';
import '../../controllers/asistencia_controller.dart';
import '../../models/asistencia.dart';
import '../../models/empleado.dart';
import '../../models/usuario.dart';
import '../../services/empleado_service.dart';
import '../../utils/date_utils.dart';

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

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Completas',
              asistenciasCompletas.toString(),
              Icons.check_circle,
              Colors.green,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pendientes',
              asistenciasPendientes.toString(),
              Icons.pending,
              Colors.orange,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Horas',
              '${totalHoras.inHours}h ${totalHoras.inMinutes.remainder(60)}m',
              Icons.access_time,
              colorScheme.primary,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.white
                    : colorScheme.onSurface.withValues(alpha: 0.7),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _vistaLista ? Icons.history : Icons.calendar_month,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _vistaLista ? 'Vista Lista' : 'Vista Calendario',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    // Toggle vista con mejor diseño
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
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
                          }
                        },
                        child: _vistaLista
                            ? _buildVistaLista(asistenciaController.asistencias, theme, colorScheme)
                            : _buildVistaCalendario(asistenciaController.asistencias, theme, colorScheme),
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: asistencias.length,
      itemBuilder: (context, index) {
        final asistencia = asistencias[index];
        return _buildAsistenciaCardMejorado(asistencia, theme, colorScheme);
      },
    );
  }

  Widget _buildVistaCalendario(List<Asistencia> asistencias, ThemeData theme, ColorScheme colorScheme) {
    final asistenciasPorFecha = _getAsistenciasPorFecha(asistencias);

    return Column(
      children: [
        // Selector de mes
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                      });
                    },
                    icon: Icon(Icons.chevron_left, color: colorScheme.primary),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay).toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                      });
                    },
                    icon: Icon(Icons.chevron_right, color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Grid de días del mes
              _buildCalendarioMes(_focusedDay, asistenciasPorFecha, theme, colorScheme),
            ],
          ),
        ),
        // Lista de asistencias del día seleccionado
        Expanded(
          child: _buildListaDiaSeleccionado(_selectedDay, asistencias, theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildCalendarioMes(DateTime mes, Map<DateTime, List<Asistencia>> asistenciasPorFecha, ThemeData theme, ColorScheme colorScheme) {
    final primerDia = DateTime(mes.year, mes.month, 1);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0);
    final diasEnMes = ultimoDia.day;
    final primerDiaSemana = primerDia.weekday; // 1=Lunes, 7=Domingo
    
    // Días de la semana
    final diasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    
    return Column(
      children: [
        // Encabezado de días de la semana
        Row(
          children: diasSemana.map((dia) => Expanded(
            child: Center(
              child: Text(
                dia,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // Días del mes
        ...List.generate((diasEnMes + primerDiaSemana - 1) ~/ 7 + ((diasEnMes + primerDiaSemana - 1) % 7 > 0 ? 1 : 0), (semana) {
          return Row(
            children: List.generate(7, (diaSemana) {
              final diaIndex = semana * 7 + diaSemana - primerDiaSemana + 1;
              if (diaIndex < 1 || diaIndex > diasEnMes) {
                return Expanded(child: Container()); // Espacio vacío
              }
              
              final fecha = DateTime(mes.year, mes.month, diaIndex);
              final tieneAsistencia = asistenciasPorFecha.keys.any((d) => isSameDay(d, fecha));
              final esSeleccionado = isSameDay(_selectedDay, fecha);
              final esHoy = isSameDay(DateTime.now(), fecha);
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = fecha;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: esSeleccionado
                          ? colorScheme.primary
                          : esHoy
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: esSeleccionado
                            ? colorScheme.primary
                            : esHoy
                                ? colorScheme.primary
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          diaIndex.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: esSeleccionado || esHoy ? FontWeight.bold : FontWeight.normal,
                            color: esSeleccionado
                                ? Colors.white
                                : esHoy
                                    ? colorScheme.primary
                                    : Colors.black87,
                          ),
                        ),
                        if (tieneAsistencia)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: esSeleccionado ? Colors.white : colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildListaDiaSeleccionado(DateTime dia, List<Asistencia> asistencias, ThemeData theme, ColorScheme colorScheme) {
    final asistenciasDelDia = _getAsistenciasDelDia(dia, asistencias);

    if (asistenciasDelDia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay registros para ${DateFormat('dd/MM/yyyy').format(dia)}',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: asistenciasDelDia.length,
      itemBuilder: (context, index) {
        return _buildAsistenciaCardMejorado(asistenciasDelDia[index], theme, colorScheme);
      },
    );
  }

  Widget _buildAsistenciaCardMejorado(Asistencia asistencia, ThemeData theme, ColorScheme colorScheme) {
    final fechaEntrada = asistencia.fechaHoraEntrada;
    final fechaSalida = asistencia.fechaHoraSalida;
    final fechaFormateada = DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(fechaEntrada);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleta
              ? [
                  Colors.green.shade50,
                  Colors.white,
                ]
              : [
                  Colors.orange.shade50,
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleta
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleta ? Colors.green : Colors.orange).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _mostrarDetalleAsistencia(asistencia, theme, colorScheme);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con fecha y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fechaFormateada,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCompleta ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleta ? Colors.green.shade300 : Colors.orange.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleta ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: isCompleta ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCompleta ? 'Completa' : 'Pendiente',
                          style: TextStyle(
                            color: isCompleta ? Colors.green.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Entrada
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.login, color: Colors.green.shade700, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entrada',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            horaEntrada,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Salida
              if (fechaSalida != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.logout, color: Colors.red.shade700, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salida',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              horaSalida!,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Duración
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Duración: ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        duracion!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
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
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pending, size: 20, color: Colors.orange.shade700),
                      const SizedBox(width: 10),
                      Text(
                        'Salida pendiente de registro',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
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
