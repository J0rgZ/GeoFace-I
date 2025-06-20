// lib/screens/admin/api_config_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/api_config_controller.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<ApiConfigController>();
    // Inicializamos el controlador con la URL base del modelo
    _urlController = TextEditingController(text: controller.apiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;
    
    final controller = context.read<ApiConfigController>();
    final success = await controller.saveApiConfigFromBaseUrl(_urlController.text);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ URLs guardadas correctamente."), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${controller.error}"), backgroundColor: Colors.red),
      );
    }
  }

  // NUEVO: Función para manejar la sincronización
  Future<void> _syncApi() async {
    final controller = context.read<ApiConfigController>();
    // Mostramos un diálogo de espera
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    final message = await controller.syncRemoteDatabase();
    
    if (!mounted) return;
    Navigator.pop(context); // Cierra el diálogo de espera

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('✅') ? Colors.blueAccent : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ApiConfigController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de API'),
      ),
      body: controller.isLoading && _urlController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'URL Base del Servicio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa la URL base de tu API (ej. de ngrok), sin incluir "/identificar".',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL Base de la API',
                        hintText: 'https://ejemplo.ngrok-free.app',
                        prefixIcon: Icon(Icons.dns_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La URL no puede estar vacía.';
                        }
                        if (!Uri.tryParse(value.trim())!.isAbsolute) {
                          return 'Por favor, ingresa una URL válida.';
                        }
                        if (value.trim().endsWith('/')) {
                          return 'No incluyas la barra ("/") al final.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading ? null : _saveUrl,
                      icon: controller.isLoading
                          ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(controller.isLoading ? 'Guardando...' : 'Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(
                      'Mantenimiento de la API',
                       style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Si has añadido nuevos empleados, pulsa este botón para que la API actualice su base de datos de rostros.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    // --- NUEVO BOTÓN DE SINCRONIZACIÓN ---
                    OutlinedButton.icon(
                      onPressed: controller.isSyncing ? null : _syncApi,
                      icon: controller.isSyncing
                          ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(strokeWidth: 3))
                          : const Icon(Icons.sync_rounded),
                      label: Text(controller.isSyncing ? 'Sincronizando...' : 'Actualizar Datos en API'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}