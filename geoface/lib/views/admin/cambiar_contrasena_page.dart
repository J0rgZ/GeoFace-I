// FILE: lib/views/admin/cambiar_contrasena_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/usuario.dart';

/// CambiarContrasenaPage: Permite al usuario autenticado cambiar su contraseña.
///
/// Presenta un formulario seguro y validado para ingresar la contraseña actual,
/// la nueva contraseña y su confirmación. Se integra con AuthController para
/// ejecutar la lógica de negocio y proporciona retroalimentación clara al usuario.
class CambiarContrasenaPage extends StatefulWidget {
  const CambiarContrasenaPage({Key? key}) : super(key: key);

  @override
  State<CambiarContrasenaPage> createState() => _CambiarContrasenaPageState();
}

class _CambiarContrasenaPageState extends State<CambiarContrasenaPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estados locales para controlar la visibilidad de las contraseñas.
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    // Es crucial liberar los recursos de los controladores para evitar fugas de memoria.
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  /// Muestra un SnackBar con un estilo consistente.
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error 
            : Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Función que valida el formulario y llama al controlador para cambiar la contraseña.
  /// Recibe el AuthController para evitar buscarlo de nuevo en el árbol de widgets.
  Future<void> _cambiarContrasena(AuthController authController) async {
    // Si el formulario no es válido, no se procede.
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      // Llama al método del controlador que contiene la lógica de negocio.
      await authController.changePassword(
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim()
      );
      
      _showFeedback('Contraseña actualizada correctamente.');
      if (mounted) Navigator.pop(context);

    } catch (e) {
      _showFeedback('Error: ${e.toString()}', isError: true);
    }
  }

  // --- WIDGETS DE CONSTRUCCIÓN DE UI ---

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario actual una sola vez para la información del encabezado.
    final currentUser = Provider.of<AuthController>(context, listen: false).currentUser;
    final theme = Theme.of(context);
    
    // El Consumer reconstruye sus hijos cuando AuthController notifica cambios (isLoading).
    return Consumer<AuthController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cambiar Contraseña'),
          ),
          // Usamos el `child` del Consumer para el contenido que no necesita reconstruirse.
          body: child,
          // El botón sí necesita reconstruirse, por eso está dentro del builder
          // y fuera del child.
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FilledButton.icon(
              // El estado del botón depende directamente del `controller.isLoading`.
              onPressed: controller.loading 
                  ? null 
                  : () => _cambiarContrasena(controller),
              icon: controller.loading 
                  ? const SizedBox.shrink() 
                  : const Icon(Icons.save_rounded),
              label: controller.loading
                  ? const SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Guardar Cambios'),
            ),
          ),
        );
      },
      // Este es el `child` que se pasa al `builder`. No se reconstruye innecesariamente.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (currentUser != null) _buildHeader(theme, currentUser),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        labelText: 'Contraseña Actual',
                        prefixIcon: Icons.lock_open_rounded,
                        isVisible: _currentPasswordVisible,
                        onToggleVisibility: () => setState(() => _currentPasswordVisible = !_currentPasswordVisible),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingrese su contraseña actual';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        labelText: 'Nueva Contraseña',
                        prefixIcon: Icons.lock_outline_rounded,
                        isVisible: _newPasswordVisible,
                        onToggleVisibility: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingrese la nueva contraseña';
                          if (value.length < 6) return 'Debe tener al menos 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirmar Nueva Contraseña',
                        prefixIcon: Icons.lock_person_rounded,
                        isVisible: _confirmPasswordVisible,
                        onToggleVisibility: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                        validator: (value) {
                          if (value != _newPasswordController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Construye la cabecera de la página con la información del usuario.
  Widget _buildHeader(ThemeData theme, Usuario currentUser) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.security_rounded, size: 40, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Text(currentUser.nombreUsuario, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(currentUser.correo, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  /// Construye un campo de texto para contraseñas con un botón para alternar la visibilidad.
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggleVisibility,
        ),
      ),
      obscureText: !isVisible,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction, // Valida mientras se escribe.
    );
  }
}