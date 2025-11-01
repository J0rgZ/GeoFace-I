// -----------------------------------------------------------------------------
// @Encabezado:   Página de Crear/Editar Administrador
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define el formulario para crear y editar usuarios
//               administradores. Incluye campos para nombre, correo electrónico
//               y contraseña, validación de formularios, gestión de estados
//               de carga, animaciones y navegación con integración al
//               AdministradorController para persistir los datos.
//
// @NombreArchivo: add_edit_admin_page.dart
// @Ubicacion:    lib/views/admin/add_edit_admin_page.dart
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
import '../../controllers/administrador_controller.dart';
import '../../models/usuario.dart';

class AddEditAdminPage extends StatefulWidget {
  final Usuario? admin;

  const AddEditAdminPage({super.key, this.admin});

  @override
  State<AddEditAdminPage> createState() => _AddEditAdminPageState();
}

class _AddEditAdminPageState extends State<AddEditAdminPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _passwordController;

  bool _isEditMode = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.admin != null;

    _nombreController = TextEditingController(text: _isEditMode ? widget.admin!.nombreUsuario : '');
    _correoController = TextEditingController(text: _isEditMode ? widget.admin!.correo : '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final adminController = Provider.of<AdministradorController>(context, listen: false);
    bool success = false;

    if (_isEditMode) {
      success = await adminController.updateAdmin(
        userId: widget.admin!.id,
        nombreUsuario: _nombreController.text.trim(),
      );
    } else {
      success = await adminController.createAdmin(
        nombreUsuario: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      final successMessage = _isEditMode 
          ? 'Administrador actualizado exitosamente' 
          : 'Administrador creado exitosamente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(successMessage)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: ${adminController.errorMessage}')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminController = context.watch<AdministradorController>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditMode ? 'Editar Administrador' : 'Nuevo Administrador',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card de encabezado
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _isEditMode ? Icons.edit_rounded : Icons.person_add_rounded,
                          size: 32,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditMode ? 'Editar Administrador' : 'Nuevo Administrador',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEditMode 
                                  ? 'Modifica la información del administrador'
                                  : 'Completa los datos para crear un nuevo administrador',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Campo Nombre
                _buildFormField(
                  controller: _nombreController,
                  label: 'Nombre de Usuario',
                  icon: Icons.person_outline_rounded,
                  hint: 'Ingresa el nombre completo',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre de usuario es requerido';
                    }
                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),

                // Campo Correo
                _buildFormField(
                  controller: _correoController,
                  label: 'Correo Electrónico',
                  icon: Icons.email_outlined,
                  hint: _isEditMode 
                      ? 'No se puede modificar' 
                      : 'ejemplo@admin.com',
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _isEditMode,
                  validator: (value) {
                    if (_isEditMode) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo electrónico es requerido';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Ingresa un correo electrónico válido';
                    }
                    return null;
                  },
                ),

                // Campo Contraseña (solo en creación)
                if (!_isEditMode) ...[
                  _buildFormField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    hint: 'Mínimo 6 caracteres',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword 
                            ? Icons.visibility_off_outlined 
                            : Icons.visibility_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es requerida';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  
                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información importante',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'El administrador recibirá un correo con sus credenciales de acceso al sistema.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Botón de guardar
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: adminController.isLoading ? null : _saveForm,
                    icon: adminController.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            _isEditMode ? Icons.save_rounded : Icons.person_add_rounded,
                            size: 22,
                          ),
                    label: Text(
                      adminController.isLoading
                          ? 'Procesando...'
                          : (_isEditMode ? 'Guardar Cambios' : 'Crear Administrador'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              color: readOnly ? colorScheme.onSurface.withValues(alpha: 0.6) : colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: readOnly 
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: readOnly 
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  size: 22,
                ),
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: readOnly 
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
