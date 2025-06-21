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

class _MapSelectionPageState extends State<MapSelectionPage> with SingleTickerProviderStateMixin {
  late GoogleMapController _mapController;
  late LatLng _selectedLocation;
  String _selectedAddress = 'Moviendo el mapa...';
  bool _isGeocoding = false;
  
  // Para la animación del pin
  late AnimationController _pinAnimationController;
  late Animation<double> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;

    _pinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pinAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _pinAnimationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pinAnimationController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _getAddressFromLatLng(_selectedLocation);
  }

  void _onCameraMoveStarted() {
    _pinAnimationController.reverse();
  }
  
  void _onCameraIdle() {
    _getAddressFromLatLng(_selectedLocation);
    _pinAnimationController.forward().then((_) => _pinAnimationController.reverse());
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedLocation = position.target;
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        _selectedAddress = "${place.street}, ${place.locality}, ${place.country}";
      } else {
        _selectedAddress = "No se encontró dirección.";
      }
    } catch (e) {
      _selectedAddress = "Error al obtener la dirección.";
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _goToCurrentUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la ubicación. Asegúrate de tener los permisos activados.'))
        );
      }
    }
  }

  void _confirmSelection() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: widget.initialLocation, zoom: 17.0),
            onCameraMove: _onCameraMove,
            onCameraMoveStarted: _onCameraMoveStarted,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          // Marcador animado
          Center(
            child: AnimatedBuilder(
              animation: _pinAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _pinAnimation.value),
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Icon(Icons.location_pin, color: Colors.black.withOpacity(0.3), size: 55),
                   Icon(Icons.location_pin, color: theme.colorScheme.primary, size: 50),
                ],
              ),
            ),
          ),
          _buildBottomPanel(theme),
        ],
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentUserLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildBottomPanel(ThemeData theme) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isGeocoding) const LinearProgressIndicator(),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: theme.colorScheme.secondary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dirección', style: theme.textTheme.bodySmall),
                        Text(
                          _selectedAddress,
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
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