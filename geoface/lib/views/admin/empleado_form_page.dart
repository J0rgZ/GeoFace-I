// -----------------------------------------------------------------------------
// @Encabezado:   Página de Formulario de Empleado
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define el formulario para crear y editar empleados.
//               Incluye campos para información personal, laboral y de contacto,
//               selección de sede, validación de datos únicos (DNI, correo),
//               y gestión de estados activo/inactivo con validaciones
//               completas del formulario.
//
// @NombreArchivo: empleado_form_page.dart
// @Ubicacion:    lib/views/admin/empleado_form_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

// views/admin/empleado_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoface/models/empleado.dart';
import 'package:provider/provider.dart';
import '../../controllers/empleado_controller.dart';
import '../../controllers/sede_controller.dart';

class EmpleadoFormPage extends StatefulWidget {
  final Empleado? empleado;
  const EmpleadoFormPage({super.key, this.empleado});

  @override
  State<EmpleadoFormPage> createState() => _EmpleadoFormPageState();
}

class _EmpleadoFormPageState extends State<EmpleadoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _celularController = TextEditingController();
  final _correoController = TextEditingController();
  final _cargoController = TextEditingController();
  String? _sedeSeleccionada;
  bool _isLoading = false;

  String? _dniError;
  String? _correoError;

  late final EmpleadoController _empleadoController;

  @override
  void initState() {
    super.initState();
    _empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    _empleadoController.addListener(_onControllerUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SedeController>(context, listen: false).getSedes();
    });
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    final error = _empleadoController.errorMessage;
    if (error != null) {
      setState(() {
        if (error.toLowerCase().contains('dni')) {
          _dniError = error;
        } else if (error.toLowerCase().contains('correo')) {
          _correoError = error;
        }
      });
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    _cargoController.dispose();
    _empleadoController.removeListener(_onControllerUpdate);
    super.dispose();
  }

  Future<void> _guardarEmpleado() async {
    setState(() {
      _dniError = null;
      _correoError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _empleadoController.addEmpleado(
        nombre: _nombreController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        dni: _dniController.text.trim(),
        celular: _celularController.text.trim(),
        correo: _correoController.text.trim(),
        cargo: _cargoController.text.trim(),
        sedeId: _sedeSeleccionada!,
      );

      if (mounted) {
        if (success) {
          _mostrarNotificacion('Empleado registrado con éxito', esError: false);
          Navigator.pop(context);
        } else {
          final errorMsg = _empleadoController.errorMessage;
          if (errorMsg != null && _dniError == null && _correoError == null) {
            _mostrarNotificacion(errorMsg, esError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarNotificacion('Error inesperado: ${e.toString()}', esError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 20),
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
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        validator: validator,
        textCapitalization: textCapitalization,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
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
        items: items,
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Empleado'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer<SedeController>(
        builder: (context, sedeController, _) {
          if (sedeController.loading) {
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

          if (sedeController.errorMessage != null && sedeController.sedes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar sedes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sedeController.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
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
                  // Header con descripción
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registro de Empleado',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete la información del nuevo empleado',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sección de Identidad
                  _buildSectionHeader('Información Personal', Icons.person_outline),
                  _buildTextField(
                    controller: _dniController,
                    label: 'DNI',
                    icon: Icons.credit_card_outlined,
                    hint: 'Ingrese 8 dígitos',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 8,
                    validator: (value) {
                      if (_dniError != null) return _dniError;
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

                  // Sección de Contacto
                  _buildSectionHeader('Información de Contacto', Icons.contact_phone_outlined),
                  _buildTextField(
                    controller: _celularController,
                    label: 'Celular',
                    icon: Icons.phone_android_outlined,
                    hint: 'Ingrese 9 dígitos',
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
                      if (_correoError != null) return _correoError;
                      if (value == null || value.isEmpty) return 'El correo es obligatorio';
                      final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegExp.hasMatch(value)) return 'Ingrese un correo válido';
                      return null;
                    },
                  ),

                  // Sección Laboral
                  _buildSectionHeader('Información Laboral', Icons.work_outline),
                  _buildTextField(
                    controller: _cargoController,
                    label: 'Cargo',
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => (value?.isEmpty ?? true) ? 'El cargo es obligatorio' : null,
                  ),
                  _buildDropdownField(
                    label: 'Sede Asignada',
                    icon: Icons.location_on_outlined,
                    value: _sedeSeleccionada,
                    items: sedeController.sedes.map((sede) {
                      return DropdownMenuItem<String>(
                        value: sede.id.toString(),
                        child: Text(sede.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sedeSeleccionada = value;
                      });
                    },
                    validator: (value) => value == null ? 'Seleccione una sede' : null,
                  ),

                  const SizedBox(height: 24),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                          onPressed: _isLoading ? null : _guardarEmpleado,
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
                          label: Text(_isLoading ? 'Guardando...' : 'Registrar Empleado'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}