// -----------------------------------------------------------------------------
// @Encabezado:   Página de Auditoría Mejorada
// @Autor:        Sistema GeoFace
// @Descripción:  Vista completa para visualizar, filtrar, ordenar y exportar
//               todos los eventos de auditoría del sistema.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/auditoria_controller.dart';
import '../../models/auditoria.dart';
import '../../utils/auditoria_pdf_generator.dart';

class AuditoriaPage extends StatefulWidget {
  const AuditoriaPage({super.key});

  @override
  State<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends State<AuditoriaPage> {
  TipoAccion? _filtroAccion;
  String? _filtroUsuario;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _ordenamiento = 'fecha_desc'; // fecha_desc, fecha_asc, usuario, accion

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarAuditoria();
    });
  }

  void _cargarAuditoria() {
    final controller = Provider.of<AuditoriaController>(context, listen: false);
    controller.cargarAuditoria(
      tipoAccion: _filtroAccion,
      usuarioId: _filtroUsuario,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );
  }

  List<Auditoria> _aplicarOrdenamiento(List<Auditoria> eventos) {
    final eventosOrdenados = List<Auditoria>.from(eventos);
    
    switch (_ordenamiento) {
      case 'fecha_desc':
        eventosOrdenados.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
        break;
      case 'fecha_asc':
        eventosOrdenados.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
        break;
      case 'usuario':
        eventosOrdenados.sort((a, b) => a.usuarioNombre.compareTo(b.usuarioNombre));
        break;
      case 'accion':
        eventosOrdenados.sort((a, b) => a.tipoAccionTexto.compareTo(b.tipoAccionTexto));
        break;
    }
    
    return eventosOrdenados;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría del Sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportarAPDF,
            tooltip: 'Exportar a PDF',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _mostrarOrdenamiento,
            tooltip: 'Ordenar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarAuditoria,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<AuditoriaController>(
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
                    onPressed: _cargarAuditoria,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final eventosFiltrados = _aplicarOrdenamiento(controller.auditoria);

          if (eventosFiltrados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay registros de auditoría',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los eventos de auditoría aparecerán aquí',
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
              _buildResumen(eventosFiltrados, theme),
              if (_tieneFiltrosActivos())
                _buildFiltrosActivos(theme, controller),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventosFiltrados.length,
                  itemBuilder: (context, index) {
                    final evento = eventosFiltrados[index];
                    return _AuditoriaCard(evento: evento);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumen(List<Auditoria> eventos, ThemeData theme) {
    final resumenPorTipo = <String, int>{};
    for (var evento in eventos) {
      final tipo = evento.tipoAccionTexto;
      resumenPorTipo[tipo] = (resumenPorTipo[tipo] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${eventos.length} evento${eventos.length != 1 ? 's' : ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${resumenPorTipo.length} tipo${resumenPorTipo.length != 1 ? 's' : ''} de acción',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: resumenPorTipo.entries.take(5).map((entry) => Chip(
              label: Text('${entry.key}: ${entry.value}'),
              labelStyle: const TextStyle(fontSize: 11),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosActivos(ThemeData theme, AuditoriaController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _obtenerTextoFiltros(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filtroAccion = null;
                _filtroUsuario = null;
                _fechaInicio = null;
                _fechaFin = null;
              });
              _cargarAuditoria();
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  String _obtenerTextoFiltros() {
    final filtros = <String>[];
    if (_filtroAccion != null) {
      filtros.add('Acción: ${_filtroAccion!.name}');
    }
    if (_filtroUsuario != null) {
      filtros.add('Usuario: $_filtroUsuario');
    }
    if (_fechaInicio != null) {
      filtros.add('Desde: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}');
    }
    if (_fechaFin != null) {
      filtros.add('Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}');
    }
    return filtros.isEmpty ? 'Sin filtros' : filtros.join(' • ');
  }

  bool _tieneFiltrosActivos() {
    return _filtroAccion != null || 
           _filtroUsuario != null || 
           _fechaInicio != null || 
           _fechaFin != null;
  }

  void _mostrarFiltros() {
    showDialog(
      context: context,
      builder: (context) => _FiltrosDialog(
        filtroAccion: _filtroAccion,
        filtroUsuario: _filtroUsuario,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        onAplicar: (accion, usuario, inicio, fin) {
          setState(() {
            _filtroAccion = accion;
            _filtroUsuario = usuario;
            _fechaInicio = inicio;
            _fechaFin = fin;
          });
          _cargarAuditoria();
        },
      ),
    );
  }

  void _mostrarOrdenamiento() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Fecha (Más reciente)'),
              value: 'fecha_desc',
              groupValue: _ordenamiento,
              onChanged: (value) {
                setState(() => _ordenamiento = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Fecha (Más antiguo)'),
              value: 'fecha_asc',
              groupValue: _ordenamiento,
              onChanged: (value) {
                setState(() => _ordenamiento = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Usuario'),
              value: 'usuario',
              groupValue: _ordenamiento,
              onChanged: (value) {
                setState(() => _ordenamiento = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Tipo de Acción'),
              value: 'accion',
              groupValue: _ordenamiento,
              onChanged: (value) {
                setState(() => _ordenamiento = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarAPDF() async {
    final controller = Provider.of<AuditoriaController>(context, listen: false);
    final eventosFiltrados = _aplicarOrdenamiento(controller.auditoria);

    if (eventosFiltrados.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay eventos para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final generator = AuditoriaPdfGenerator(
      eventos: eventosFiltrados,
      filtroTipoAccion: _filtroAccion?.name,
      filtroUsuario: _filtroUsuario,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generando PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final exito = await generator.generateAndSharePdf();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exito ? 'PDF exportado exitosamente' : 'Error al exportar PDF'),
          backgroundColor: exito ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class _FiltrosDialog extends StatefulWidget {
  final TipoAccion? filtroAccion;
  final String? filtroUsuario;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final Function(TipoAccion?, String?, DateTime?, DateTime?) onAplicar;

  const _FiltrosDialog({
    required this.filtroAccion,
    required this.filtroUsuario,
    required this.fechaInicio,
    required this.fechaFin,
    required this.onAplicar,
  });

  @override
  State<_FiltrosDialog> createState() => _FiltrosDialogState();
}

class _FiltrosDialogState extends State<_FiltrosDialog> {
  late TipoAccion? _filtroAccion;
  late String? _filtroUsuario;
  late DateTime? _fechaInicio;
  late DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _filtroAccion = widget.filtroAccion;
    _filtroUsuario = widget.filtroUsuario;
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros de Auditoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TipoAccion?>(
              value: _filtroAccion,
              decoration: const InputDecoration(
                labelText: 'Tipo de Acción',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<TipoAccion?>(value: null, child: Text('Todas')),
                ...TipoAccion.values.map((accion) => DropdownMenuItem(
                      value: accion,
                      child: Text(_obtenerNombreAccion(accion)),
                    )),
              ],
              onChanged: (value) => setState(() => _filtroAccion = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Usuario (ID o nombre)',
                border: OutlineInputBorder(),
              ),
              initialValue: _filtroUsuario,
              onChanged: (value) => _filtroUsuario = value.isEmpty ? null : value,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Fecha Inicio'),
              subtitle: Text(_fechaInicio != null
                  ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                  : 'Seleccionar'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicio ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (fecha != null) {
                    setState(() => _fechaInicio = fecha);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Fecha Fin'),
              subtitle: Text(_fechaFin != null
                  ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                  : 'Seleccionar'),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaFin ?? DateTime.now(),
                    firstDate: _fechaInicio ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (fecha != null) {
                    setState(() => _fechaFin = fecha);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            widget.onAplicar(_filtroAccion, _filtroUsuario, _fechaInicio, _fechaFin);
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  String _obtenerNombreAccion(TipoAccion accion) {
    switch (accion) {
      case TipoAccion.login:
        return 'Inicio de Sesión';
      case TipoAccion.logout:
        return 'Cierre de Sesión';
      case TipoAccion.crearEmpleado:
        return 'Crear Empleado';
      case TipoAccion.editarEmpleado:
        return 'Editar Empleado';
      case TipoAccion.eliminarEmpleado:
        return 'Eliminar Empleado';
      case TipoAccion.crearSede:
        return 'Crear Sede';
      case TipoAccion.editarSede:
        return 'Editar Sede';
      case TipoAccion.eliminarSede:
        return 'Eliminar Sede';
      case TipoAccion.crearAdministrador:
        return 'Crear Administrador';
      case TipoAccion.editarAdministrador:
        return 'Editar Administrador';
      case TipoAccion.eliminarAdministrador:
        return 'Eliminar Administrador';
      case TipoAccion.generarReporte:
        return 'Generar Reporte';
      case TipoAccion.exportarReporte:
        return 'Exportar Reporte';
      case TipoAccion.cambiarContrasena:
        return 'Cambiar Contraseña';
      case TipoAccion.actualizarConfiguracion:
        return 'Actualizar Configuración';
    }
  }
}

class _AuditoriaCard extends StatelessWidget {
  final Auditoria evento;

  const _AuditoriaCard({required this.evento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData iconData;
    Color iconColor;

    switch (evento.tipoAccion) {
      case TipoAccion.login:
      case TipoAccion.logout:
        iconData = Icons.login;
        iconColor = Colors.blue;
        break;
      case TipoAccion.crearEmpleado:
      case TipoAccion.crearSede:
      case TipoAccion.crearAdministrador:
        iconData = Icons.add_circle;
        iconColor = Colors.green;
        break;
      case TipoAccion.editarEmpleado:
      case TipoAccion.editarSede:
      case TipoAccion.editarAdministrador:
        iconData = Icons.edit;
        iconColor = Colors.orange;
        break;
      case TipoAccion.eliminarEmpleado:
      case TipoAccion.eliminarSede:
      case TipoAccion.eliminarAdministrador:
        iconData = Icons.delete;
        iconColor = Colors.red;
        break;
      case TipoAccion.generarReporte:
      case TipoAccion.exportarReporte:
        iconData = Icons.assessment;
        iconColor = Colors.purple;
        break;
      case TipoAccion.cambiarContrasena:
        iconData = Icons.lock;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.info;
        iconColor = colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          evento.tipoAccionTexto,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              evento.usuarioNombre,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(evento.fechaHora),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow('Descripción', evento.descripcion),
                if (evento.entidadNombre != null)
                  _InfoRow('Entidad', evento.entidadNombre!),
                if (evento.dispositivoMarca != null && evento.dispositivoModelo != null)
                  _InfoRow('Dispositivo', '${evento.dispositivoMarca} ${evento.dispositivoModelo}'),
                if (evento.dispositivoId != null)
                  _InfoRow('ID Dispositivo', evento.dispositivoId!),
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
            width: 100,
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
