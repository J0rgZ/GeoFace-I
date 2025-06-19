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
    // Obtenemos la configuración inicial del controlador.
    final controller = context.read<ApiConfigController>();
    _urlController = TextEditingController(text: controller.apiConfig.faceRecognitionApiUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final controller = context.read<ApiConfigController>();
    final success = await controller.saveApiConfig(_urlController.text);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ URL guardada correctamente."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && controller.error != null) {
      // Si hubo un error, el controlador lo tendrá almacenado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ ${controller.error}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos context.watch para que la UI se reconstruya cuando cambie el estado del controlador
    final controller = context.watch<ApiConfigController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('API de Reconocimiento'),
      ),
      body: controller.isLoading && _urlController.text.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Muestra spinner solo en la carga inicial
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URL del Servicio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa la URL completa del servicio de reconocimiento facial (ej. de ngrok).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL de la API',
                        hintText: 'https://ejemplo.ngrok-free.app/identificar',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La URL no puede estar vacía.';
                        }
                        if (!Uri.tryParse(value.trim())!.isAbsolute) {
                          return 'Por favor, ingresa una URL válida.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // Deshabilita el botón mientras se guarda
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}