// views/admin/sede_form_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/sede_controller.dart';
import '../../models/sede.dart';
import '../../utils/validators.dart';
import 'sede_mapa_seleccion_page.dart';

class SedeFormPage extends StatefulWidget {
  final Sede? sede;
  const SedeFormPage({super.key, this.sede});

  @override
  State<SedeFormPage> createState() => _SedeFormPageState();
}

class _SedeFormPageState extends State<SedeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();

  bool _activa = true;
  String? _direccion;
  LatLng? _ubicacion;
  double _radioPermitido = 100.0;

  GoogleMapController? _mapPreviewController;
  late Future<LatLng> _initialLocationFuture;

  bool get _isEditing => widget.sede != null;

  static const _gapH8 = SizedBox(height: 8.0);
  static const _gapH16 = SizedBox(height: 16.0);
  static const _gapH24 = SizedBox(height: 24.0);

  @override
  void initState() {
    super.initState();
    _initialLocationFuture = _getInitialLocation();
  }

  Future<LatLng> _getInitialLocation() async {
    if (_isEditing) {
      _nombreController.text = widget.sede!.nombre;
      _radioPermitido = widget.sede!.radioPermitido.toDouble();
      _activa = widget.sede!.activa;
      _direccion = widget.sede!.direccion;
      _ubicacion = LatLng(widget.sede!.latitud, widget.sede!.longitud);
      return _ubicacion!;
    } else {
      return _getCurrentDeviceLocation();
    }
  }

  Future<LatLng> _getCurrentDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Los permisos de ubicación están permanentemente denegados.');
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return const LatLng(-12.046374, -77.042793); // Lima, Perú
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _mapPreviewController?.dispose();
    super.dispose();
  }

  Future<void> _openMapSelection() async {
    if (_ubicacion == null) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage(initialLocation: _ubicacion!),
      ),
    );

    if (result != null) {
      setState(() {
        _ubicacion = result['location'];
        _direccion = result['address'];
        _mapPreviewController
            ?.animateCamera(CameraUpdate.newLatLng(_ubicacion!));
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_ubicacion == null || _direccion == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, selecciona una ubicación en el mapa.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      final sedeController =
          Provider.of<SedeController>(context, listen: false);
      bool success;

      if (_isEditing) {
        success = await sedeController.updateSede(
          id: widget.sede!.id,
          nombre: _nombreController.text.trim(),
          direccion: _direccion!,
          latitud: _ubicacion!.latitude,
          longitud: _ubicacion!.longitude,
          radioPermitido: _radioPermitido.toInt(),
          activa: _activa,
        );
      } else {
        success = await sedeController.addSede(
          nombre: _nombreController.text.trim(),
          direccion: _direccion!,
          latitud: _ubicacion!.latitude,
          longitud: _ubicacion!.longitude,
          radioPermitido: _radioPermitido.toInt(),
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Sede actualizada' : 'Sede agregada'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Sede' : 'Nueva Sede')),
      body: FutureBuilder<LatLng>(
        future: _initialLocationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  _gapH16,
                  Text("Obteniendo ubicación...")
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.hasData && _ubicacion == null) {
            _ubicacion = snapshot.data;
          }

          // MEJORA: Usamos SingleChildScrollView. Si el contenido cabe, no habrá scroll.
          // Esto elimina la necesidad de un botón flotante y cumple con el requisito.
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  // MEJORA: `crossAxisAlignment` en `start` es mejor para formularios.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationCard(),
                    _gapH24,
                    _buildDetailsCard(),
                    _gapH24,
                    // MEJORA: El botón de acción ahora es parte del flujo del formulario.
                    // Ya no está en una barra flotante.
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildSectionTitle('Ubicación de la Sede'),
          ),
          _buildMapPreview(),
          _gapH8,
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: ListTile(
              leading: Icon(Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Dirección',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_direccion ??
                  'Toca el mapa para seleccionar y obtener la dirección'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Detalles de la Sede'),
            _gapH16,
            TextFormField(
              controller: _nombreController,
              decoration: _buildInputDecoration(
                  'Nombre de la Sede', Icons.business_center_outlined),
              validator: (value) => Validators.validateRequired(value, 'Nombre'),
            ),
            _gapH24,
            _buildRadioSlider(),
            if (_isEditing) ...[
              _gapH16,
              SwitchListTile(
                title: const Text('Sede activa'),
                value: _activa,
                onChanged: (value) => setState(() => _activa = value),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                secondary: Icon(
                  _activa ? Icons.check_circle_outline : Icons.highlight_off,
                  color: _activa ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_ubicacion != null)
            GoogleMap(
              onMapCreated: (controller) => _mapPreviewController = controller,
              initialCameraPosition:
                  CameraPosition(target: _ubicacion!, zoom: 16),
              markers: {
                Marker(
                    markerId: const MarkerId('sede_location'),
                    position: _ubicacion!)
              },
              gestureRecognizers: const {},
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            child: Material(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _openMapSelection,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_location_alt_outlined,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Editar Ubicación en Mapa',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Radio Permitido para Marcar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        _gapH8,
        Row(
          children: [
            Icon(Icons.radar_outlined,
                color: Theme.of(context).colorScheme.primary),
            Expanded(
              child: Slider(
                value: _radioPermitido,
                min: 10,
                max: 500,
                divisions: 49,
                label: '${_radioPermitido.toInt()} m',
                onChanged: (value) => setState(() => _radioPermitido = value),
              ),
            ),
            Text(
              '${_radioPermitido.toInt()} m',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.black.withOpacity(0.04),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }

  // MEJORA: El botón ahora es un widget independiente que se coloca al final.
  // Tiene un estilo más limpio y ocupa todo el ancho disponible.
  Widget _buildActionButton() {
    return Consumer<SedeController>(
      builder: (context, controller, _) {
        final isSaving = controller.loading;
        return FilledButton.icon(
          onPressed: isSaving ? null : _submitForm,
          icon: isSaving
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Icon(_isEditing
                  ? Icons.save_as_outlined
                  : Icons.add_circle_outline),
          label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Sede'),
          style: FilledButton.styleFrom(
            // Ocupa todo el ancho y tiene una altura fija para un mejor look & feel.
            minimumSize: const Size.fromHeight(50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
      },
    );
  }
}