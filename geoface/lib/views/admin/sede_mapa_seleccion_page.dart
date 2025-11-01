// views/admin/map_selection_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapSelectionPage extends StatefulWidget {
  final LatLng initialLocation;

  const MapSelectionPage({super.key, required this.initialLocation});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  late GoogleMapController _mapController;
  late AnimationController _pinAnimationController;

  // State
  late LatLng _selectedLocation;
  String _selectedAddress = 'Moviendo el mapa...';
  bool _isGeocoding = false;
  bool _showHelpOverlay = true;

  // Animations
  late Animation<double> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;

    // MEJORA: Animación del pin más pronunciada para mejor feedback.
    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pinAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(
          parent: _pinAnimationController, curve: Curves.easeInOutBack),
    );
    
    // MEJORA: Ocultar el mensaje de ayuda después de unos segundos.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHelpOverlay = false);
    });
  }

  @override
  void dispose() {
    _pinAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- Map Callbacks ---

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _getAddressFromLatLng(_selectedLocation);
  }

  void _onCameraMoveStarted() {
    // MEJORA: Ocultar ayuda en la primera interacción y animar el pin.
    if (_showHelpOverlay) setState(() => _showHelpOverlay = false);
    _pinAnimationController.reverse();
  }

  void _onCameraIdle() {
    // MEJORA: Animar el pin al detenerse y luego obtener la dirección.
    _pinAnimationController
        .forward()
        .then((_) => _pinAnimationController.reverse());
    _getAddressFromLatLng(_selectedLocation);
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedLocation = position.target;
      _selectedAddress = 'Moviendo el mapa...';
      _isGeocoding = true; // Mostrar feedback de carga mientras se mueve
    });
  }

  // --- Logic Methods ---

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
          );
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        // MEJORA: Formato de dirección más completo y limpio.
        _selectedAddress = [
          place.street,
          place.subLocality,
          place.locality,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        if (_selectedAddress.isEmpty) {
          _selectedAddress = "Ubicación sin nombre de calle.";
        }
      } else {
        _selectedAddress = "No se encontró dirección.";
      }
    } catch (e) {
      _selectedAddress = "Error al obtener la dirección.";
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _confirmSelection() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _selectedAddress,
    });
  }

  // --- Map Control Methods ---

  Future<void> _goToCurrentUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ));
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude), 17.0),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No se pudo obtener la ubicación. Revise los permisos.')));
      }
    }
  }

  void _zoomIn() {
    _mapController.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController.animateCamera(CameraUpdate.zoomOut());
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        // MEJORA: AppBar transparente para un look más inmersivo.
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                Theme.of(context).colorScheme.primary.withValues(alpha:0.6)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // MEJORA: Se quita el FAB para evitar solapamiento.
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition:
                CameraPosition(target: widget.initialLocation, zoom: 17.0),
            onCameraMove: _onCameraMove,
            onCameraMoveStarted: _onCameraMoveStarted,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false, // Desactivamos los controles nativos
          ),
          _buildCenterMarker(),
          _buildInfoPanel(),
          _buildMapControls(), // MEJORA: Panel de control personalizado
          _buildHelpOverlay(), // MEJORA: Mensaje de ayuda inicial
        ],
      ),
    );
  }

  /// MEJORA: Un retículo central fijo y un pin que se anima sobre él.
  Widget _buildCenterMarker() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pinAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _pinAnimation.value),
                child: child,
              );
            },
            child: Icon(Icons.location_pin,
                color: Theme.of(context).colorScheme.primary, size: 50),
          ),
          // Sombra del pin para dar efecto de profundidad.
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha:0.3),
              shape: BoxShape.circle,
            ),
          ),
          // Espacio para que el pin no tape el centro exacto.
          const SizedBox(height: 55),
        ],
      ),
    );
  }

  /// MEJORA: Panel inferior con la dirección y el botón de confirmación.
  Widget _buildInfoPanel() {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding:
              const EdgeInsets.only(top: 8.0, left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Handle" visual
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (_isGeocoding)
                const LinearProgressIndicator(minHeight: 2)
              else
                const SizedBox(height: 2), // Para mantener la altura
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      color: theme.colorScheme.secondary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dirección Seleccionada',
                            style: theme.textTheme.labelMedium),
                        Text(
                          _selectedAddress,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar Ubicación'),
                  onPressed: _isGeocoding ? null : _confirmSelection,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// MEJORA: Panel de control del mapa para zoom y ubicación.
  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _zoomIn,
                  tooltip: 'Acercar'),
              const Divider(height: 1),
              IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _zoomOut,
                  tooltip: 'Alejar'),
              const Divider(height: 1),
              IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _goToCurrentUserLocation,
                  tooltip: 'Mi ubicación'),
            ],
          ),
        ),
      ),
    );
  }

  /// MEJORA: Overlay de ayuda que se desvanece automáticamente.
  Widget _buildHelpOverlay() {
    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _showHelpOverlay ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Mueve el mapa para ajustar la ubicación',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}