// -----------------------------------------------------------------------------
// @Encabezado:   Página de Detalle de Empleado
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página de detalle completo de un empleado
//               específico. Incluye visualización de información personal,
//               laboral y de contacto, edición de datos, gestión de datos
//               biométricos, historial de asistencias y navegación a funciones
//               relacionadas como registro biométrico.
//
// @NombreArchivo: empleado_detail_page.dart
// @Ubicacion:    lib/views/admin/empleado_detail_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoface/views/admin/registro_biometrico_page.dart';
import 'package:provider/provider.dart';
import '../../controllers/empleado_controller.dart';
import '../../controllers/sede_controller.dart';
import '../../models/empleado.dart';

class EmpleadoDetailPage extends StatefulWidget {
  final String empleadoId;

  const EmpleadoDetailPage({super.key, required this.empleadoId});

  @override
  State<EmpleadoDetailPage> createState() => _EmpleadoDetailPageState();
}

class _EmpleadoDetailPageState extends State<EmpleadoDetailPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  Empleado? _empleado;

  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _celularController = TextEditingController();
  final _correoController = TextEditingController();
  final _cargoController = TextEditingController();
  String? _sedeSeleccionada;
  
  late final EmpleadoController _empleadoController;
  late final SedeController _sedeController;

  @override
  void initState() {
    super.initState();
    _empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    _sedeController = Provider.of<SedeController>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _sedeController.getSedes(),
        _empleadoController.getEmpleadoById(widget.empleadoId),
      ]);

      final empleado = results[1] as Empleado?;

      if (empleado != null && mounted) {
        setState(() {
          _empleado = empleado;
          _populateControllers(empleado);
        });
      }
    } catch (error) {
      if (mounted) {
        _mostrarNotificacion('Error al cargar los datos: $error', esError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateControllers(Empleado empleado) {
    _nombreController.text = empleado.nombre;
    _apellidosController.text = empleado.apellidos;
    _dniController.text = empleado.dni;
    _celularController.text = empleado.celular;
    _correoController.text = empleado.correo;
    _cargoController.text = empleado.cargo;
    _sedeSeleccionada = empleado.sedeId;
  }

  Future<void> _guardarCambios() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _empleadoController.updateEmpleado(
        id: widget.empleadoId,
        nombre: _nombreController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        dni: _dniController.text.trim(),
        celular: _celularController.text.trim(),
        correo: _correoController.text.trim(),
        cargo: _cargoController.text.trim(),
        sedeId: _sedeSeleccionada!,
        activo: _empleado!.activo,
      );

      if (mounted) {
        if (success) {
          _mostrarNotificacion('Empleado actualizado correctamente', esError: false);
          setState(() => _isEditing = false);
          await _loadData();
        } else {
          _mostrarNotificacion(_empleadoController.errorMessage ?? 'No se pudo actualizar el empleado', esError: true);
        }
      }
    } catch (error) {
      if (mounted) {
        _mostrarNotificacion('Error al actualizar: $error', esError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToBiometrico(Empleado empleado) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistroBiometricoScreen(empleado: empleado)),
    ).then((_) => _loadData()); // Recargar datos al regresar
  }
  
  void _mostrarNotificacion(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: esError 
            ? Theme.of(context).colorScheme.error 
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
    );
  }

  String _getInitials(String nombreCompleto) {
    if (nombreCompleto.trim().isEmpty) return "?";
    final names = nombreCompleto.trim().split(' ');
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names.first[0]}${names.last[0]}'.toUpperCase();
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: !_isEditing,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          counterText: maxLength != null ? '' : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          filled: true,
          fillColor: _isEditing 
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        validator: validator,
        textCapitalization: textCapitalization,
        style: _isEditing ? null : TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    if (_isEditing) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: DropdownButtonFormField<String>(
          value: _sedeSeleccionada,
          decoration: InputDecoration(
            labelText: 'Sede Asignada',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: _sedeController.sedes.map((sede) {
            return DropdownMenuItem<String>(
              value: sede.id.toString(),
              child: Text(sede.nombre),
            );
          }).toList(),
          onChanged: (value) => setState(() => _sedeSeleccionada = value),
          validator: (value) => value == null ? 'Seleccione una sede' : null,
          isExpanded: true,
        ),
      );
    } else {
      final sedeActual = _sedeController.sedes
          .firstWhere((s) => s.id.toString() == _sedeSeleccionada, orElse: () => _sedeController.sedes.first)
          .nombre;
      return _buildTextField(
        controller: TextEditingController(text: sedeActual),
        label: 'Sede Asignada',
        icon: Icons.location_on_outlined,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Empleado' : 'Detalle de Empleado'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          if (!_isEditing && !_isLoading && _empleado != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Cargando información...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (_empleado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Empleado no encontrado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudo cargar la información del empleado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(),
            
            // Información Personal
            _buildSectionHeader('Información Personal', Icons.person_outline),
            _buildTextField(
              controller: _dniController,
              label: 'DNI',
              icon: Icons.credit_card_outlined,
              hint: 'Número de documento',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 8,
              validator: (value) {
                if (value == null || value.isEmpty) return 'El DNI es obligatorio';
                if (value.length != 8) return 'El DNI debe tener 8 dígitos';
                return null;
              },
            ),
            _buildTextField(
              controller: _nombreController,
              label: 'Nombres',
              icon: Icons.account_circle_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value?.isEmpty ?? true) ? 'Los nombres son obligatorios' : null,
            ),
            _buildTextField(
              controller: _apellidosController,
              label: 'Apellidos',
              icon: Icons.account_circle_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value?.isEmpty ?? true) ? 'Los apellidos son obligatorios' : null,
            ),

            // Información de Contacto
            _buildSectionHeader('Información de Contacto', Icons.contact_phone_outlined),
            _buildTextField(
              controller: _celularController,
              label: 'Celular',
              icon: Icons.phone_android_outlined,
              hint: 'Número de celular',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 9,
              validator: (value) {
                if (value == null || value.isEmpty) return 'El celular es obligatorio';
                if (value.length != 9) return 'El celular debe tener 9 dígitos';
                return null;
              },
            ),
            _buildTextField(
              controller: _correoController,
              label: 'Correo Electrónico',
              icon: Icons.email_outlined,
              hint: 'ejemplo@dominio.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'El correo es obligatorio';
                final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegExp.hasMatch(value)) return 'Ingrese un correo válido';
                return null;
              },
            ),

            // Información Laboral
            _buildSectionHeader('Información Laboral', Icons.work_outline),
            _buildTextField(
              controller: _cargoController,
              label: 'Cargo',
              icon: Icons.badge_outlined,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => (value?.isEmpty ?? true) ? 'El cargo es obligatorio' : null,
            ),
            _buildDropdownField(),
            
            // Datos Biométricos
            _buildSectionHeader('Datos Biométricos', Icons.fingerprint),
            _buildBiometricCard(),

            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final nombreCompleto = '${_nombreController.text} ${_apellidosController.text}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'empleado-avatar-${widget.empleadoId}',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    _getInitials(nombreCompleto),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _empleado!.activo ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _empleado!.activo ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Hero(
            tag: 'empleado-nombre-${widget.empleadoId}',
            child: Material(
              color: Colors.transparent,
              child: Text(
                nombreCompleto,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _cargoController.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (_empleado!.activo ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _empleado!.activo ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _empleado!.activo ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: _empleado!.activo ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  _empleado!.activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: _empleado!.activo ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
    final hasBiometrics = _empleado!.hayDatosBiometricos;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasBiometrics 
              ? Colors.green.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        color: hasBiometrics
            ? Colors.green.withOpacity(0.05)
            : Theme.of(context).colorScheme.surface,
      ),
      child: InkWell(
        onTap: () => _navigateToBiometrico(_empleado!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasBiometrics
                      ? Colors.green.withOpacity(0.1)
                      : Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasBiometrics ? Icons.face : Icons.face_retouching_off,
                  color: hasBiometrics 
                      ? Colors.green.shade700
                      : Theme.of(context).colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasBiometrics
                          ? 'Datos biométricos registrados'
                          : 'Sin datos biométricos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasBiometrics
                            ? Colors.green.shade800
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasBiometrics
                          ? 'Reconocimiento facial habilitado'
                          : 'Toque para configurar reconocimiento facial',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => setState(() {
                _isEditing = false;
                _populateControllers(_empleado!);
              }),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _guardarCambios,
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return FilledButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Volver a la Lista'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}