// -----------------------------------------------------------------------------
// @Encabezado:   Página de Inicio de Sesión para Empleados
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página de login para empleados de la
//               aplicación GeoFace. Permite a los empleados iniciar sesión con
//               su DNI como usuario y contraseña, y redirige al cambio de
//               contraseña si es necesario.
//
// @NombreArchivo: login_empleado_page.dart
// @Ubicacion:    lib/views/auth/login_empleado_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes.dart';
import '../../services/usuario_service.dart';

class LoginEmpleadoPage extends StatefulWidget {
  const LoginEmpleadoPage({super.key});

  @override
  State<LoginEmpleadoPage> createState() => _LoginEmpleadoPageState();
}

class _LoginEmpleadoPageState extends State<LoginEmpleadoPage> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dni = _dniController.text.trim();
      final password = _passwordController.text;
      final email = '$dni@geoface.com';

      // Iniciar sesión con Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtener datos del usuario desde Firestore
      final usuarioService = UsuarioService();
      final usuario = await usuarioService.getUsuarioByEmail(email);

      if (usuario == null) {
        throw Exception('No se encontraron datos del usuario');
      }

      if (!usuario.activo) {
        await FirebaseAuth.instance.signOut();
        throw Exception('Tu cuenta ha sido desactivada. Contacta al administrador.');
      }

      // El AuthController se actualizará automáticamente con el listener de Firebase Auth

      if (mounted) {
        // Navegar al layout (el layout mostrará el consejo opcional si debeCambiarContrasena == true)
        Navigator.of(context).pushReplacementNamed(AppRoutes.empleadoLayout);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMsg = 'DNI o contraseña incorrectos';
          break;
        case 'invalid-email':
          errorMsg = 'El formato del DNI no es válido';
          break;
        case 'user-disabled':
          errorMsg = 'Esta cuenta ha sido deshabilitada';
          break;
        default:
          errorMsg = 'Error de autenticación: ${e.message}';
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 80,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Inicio de Sesión',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ingresa tu DNI y contraseña',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          
                          TextFormField(
                            controller: _dniController,
                            decoration: InputDecoration(
                              labelText: 'DNI',
                              hintText: '12345678',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor ingresa tu DNI';
                              }
                              if (value.trim().length < 8) {
                                return 'El DNI debe tener al menos 8 dígitos';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: colorScheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: colorScheme.onErrorContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(AppRoutes.mainMenu);
                            },
                            child: const Text('Volver al Menú Principal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

