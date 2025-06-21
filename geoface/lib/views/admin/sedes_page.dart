import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../controllers/sede_controller.dart';
import '../../controllers/empleado_controller.dart';
import '../../models/sede.dart';
import 'sede_form_page.dart';

/// SedesPage: Versión mejorada con UX y UI inspirada en EmpleadosPage.
class SedesPage extends StatefulWidget {
  const SedesPage({super.key});

  @override
  State<SedesPage> createState() => _SedesPageState();
}

class _SedesPageState extends State<SedesPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _searchAnimation;
  bool _isSearchExpanded = false;
  String _selectedFilter = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de animación
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOutCubic,
    );
    
    // Animar FAB al cargar
    _fabAnimationController.forward();
    
    Future.microtask(() {
      Provider.of<SedeController>(context, listen: false).getSedes();
      // Precargar empleados para la validación de eliminación
      Provider.of<EmpleadoController>(context, listen: false).getEmpleados();
    });

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE LÓGICA Y ACCIONES ---

  void _onSearchChanged() {
    setState(() {});
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus && !_isSearchExpanded) {
      _expandSearch();
    }
  }

  void _expandSearch() {
    setState(() => _isSearchExpanded = true);
    _searchAnimationController.forward();
    HapticFeedback.lightImpact();
  }

  void _collapseSearch() {
    if (_searchController.text.isEmpty) {
      setState(() => _isSearchExpanded = false);
      _searchAnimationController.reverse();
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await Provider.of<SedeController>(context, listen: false).getSedes();
  }
  
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error 
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _toggleSedeStatus(Sede sede) async {
    final controller = Provider.of<SedeController>(context, listen: false);
    final sedeActualizada = sede.copyWith(activa: !sede.activa);
    
    final success = await controller.updateSede(
      id: sedeActualizada.id,
      nombre: sedeActualizada.nombre,
      direccion: sedeActualizada.direccion,
      latitud: sedeActualizada.latitud,
      longitud: sedeActualizada.longitud,
      radioPermitido: sedeActualizada.radioPermitido,
      activa: sedeActualizada.activa,
    );
    
    if (success) {
      _showFeedback('Estado de ${sede.nombre} actualizado.');
    } else {
      _showFeedback('Error al actualizar el estado.', isError: true);
    }
  }

  Future<void> _deleteSede(Sede sede) async {
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    final empleadosEnSede = await empleadoController.getEmpleadosPorSede(sede.id);

    if (empleadosEnSede.isNotEmpty) {
      _showFeedback(
        'No se puede eliminar: La sede tiene ${empleadosEnSede.length} empleado(s) asignado(s).',
        isError: true
      );
      return;
    }

    final sedeController = Provider.of<SedeController>(context, listen: false);
    final success = await sedeController.deleteSede(sede.id);
    if (success) {
      _showFeedback('${sede.nombre} ha sido eliminada.');
    } else {
      _showFeedback('Error al eliminar la sede.', isError: true);
    }
  }
  
  String _getSedeInitials(String nombreSede) {
    if (nombreSede.isEmpty) return "S";
    final words = nombreSede.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return "S";
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
  
  List<Sede> _filterSedes(List<Sede> sedes) {
    final query = _searchController.text.toLowerCase();
    
    // Filtrar por estado
    List<Sede> filteredByStatus;
    switch (_selectedFilter) {
      case 'active':
        filteredByStatus = sedes.where((s) => s.activa).toList();
        break;
      case 'inactive':
        filteredByStatus = sedes.where((s) => !s.activa).toList();
        break;
      default:
        filteredByStatus = sedes;
    }
    
    // Filtrar por texto de búsqueda
    if (query.isEmpty) return filteredByStatus;
    return filteredByStatus.where((s) {
      return s.nombre.toLowerCase().contains(query) ||
             s.direccion.toLowerCase().contains(query);
    }).toList();
  }

  // --- MÉTODOS DE NAVEGACIÓN ---

  void _navigateToForm({Sede? sede}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            SedeFormPage(sede: sede),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOutCubic)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) => _refreshData());
  }

  // --- WIDGETS DE CONSTRUCCIÓN DE UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SedeController>(
        builder: (context, controller, _) {
          Widget content;
          if (controller.loading && controller.sedes.isEmpty) {
            content = _buildLoadingState();
          } else if (controller.errorMessage != null) {
            content = _buildErrorState(controller.errorMessage!);
          } else {
            final filteredList = _filterSedes(controller.sedes);
            content = Column(
              children: [
                _buildHeader(controller.sedes.length),
                _buildSearchAndFilters(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    child: filteredList.isEmpty
                        ? (_searchController.text.isNotEmpty || _selectedFilter != 'all' 
                            ? _buildNoResultsState() 
                            : _buildEmptyState())
                        : _buildSedesList(filteredList),
                  ),
                ),
              ],
            );
          }
          
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: content,
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(),
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Nueva Sede'),
          heroTag: "sede_fab",
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando sedes...'),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalSedes) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: kToolbarHeight / 2, left: 16, right: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sedes',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalSedes sede${totalSedes != 1 ? 's' : ''} registrada${totalSedes != 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              totalSedes.toString(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isSearchExpanded 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: _isSearchExpanded ? 2 : 1,
            ),
            color: theme.colorScheme.surface,
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o dirección...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _collapseSearch();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final filters = [
      {'key': 'all', 'label': 'Todas', 'icon': MdiIcons.officeBuilding},
      {'key': 'active', 'label': 'Activas', 'icon': MdiIcons.officeBuildingMarker},
      {'key': 'inactive', 'label': 'Inactivas', 'icon': MdiIcons.officeBuildingRemove},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter['key'] as String);
                  HapticFeedback.selectionClick();
                }
              },
              label: Text(filter['label'] as String),
              avatar: Icon(
                filter['icon'] as IconData,
                size: 18,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
              side: BorderSide(
                color: isSelected ? Colors.transparent : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSedesList(List<Sede> sedes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Espacio para el FAB
      itemCount: sedes.length,
      itemBuilder: (context, index) {
        return _buildSedeCard(sedes[index]);
      },
    );
  }
  
  Widget _buildSedeCard(Sede sede) {
    final theme = Theme.of(context);
    final colorEstado = sede.activa ? Colors.green.shade600 : theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: InkWell(
          onTap: () => _showSedeOptions(context, sede),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'sede-avatar-${sede.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primaryContainer.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getSedeInitials(sede.nombre),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'sede-nombre-${sede.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            sede.nombre,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sede.direccion,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorEstado.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              sede.activa ? Icons.check_circle_outline : Icons.highlight_off,
                              size: 14,
                              color: colorEstado,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sede.activa ? 'Activa' : 'Inactiva',
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE ESTADOS ---

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.officeBuildingMarkerOutline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text('No hay sedes registradas', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón para agregar tu primera sede',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Sede'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text('Sin resultados', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'No se encontraron sedes con los filtros aplicados',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedFilter = 'all');
                _collapseSearch();
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Limpiar Filtros'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text('Ocurrió un error', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEET MEJORADO ---

  void _showSedeOptions(BuildContext context, Sede sede) {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, width: 40, decoration: BoxDecoration(color: theme.colorScheme.outline.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.7)]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text(_getSedeInitials(sede.nombre), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sede.nombre, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(sede.direccion, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                _buildOptionTile(Icons.edit_note_rounded, 'Editar Sede', 'Modificar información y ubicación', () {
                  Navigator.pop(context);
                  _navigateToForm(sede: sede);
                }),
                
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(sede.activa ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: sede.activa ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estado de la Sede', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text(sede.activa ? 'Activa' : 'Inactiva', style: theme.textTheme.bodySmall?.copyWith(color: sede.activa ? Colors.green.shade600 : theme.colorScheme.error, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: sede.activa,
                        onChanged: (value) {
                          Navigator.pop(context);
                          _toggleSedeStatus(sede);
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildOptionTile(Icons.delete_outline_rounded, 'Eliminar Sede', 'Esta acción no se puede deshacer', () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(sede);
                }, isDestructive: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDestructive ? theme.colorScheme.error.withOpacity(0.2) : theme.colorScheme.outline.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: isDestructive ? theme.colorScheme.error.withOpacity(0.1) : theme.colorScheme.primaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: isDestructive ? theme.colorScheme.error.withOpacity(0.7) : theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Sede sede) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Sede'),
        content: Text('¿Está seguro de que desea eliminar la sede "${sede.nombre}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSede(sede);
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}