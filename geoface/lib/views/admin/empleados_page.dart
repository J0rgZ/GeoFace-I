// -----------------------------------------------------------------------------
// @Encabezado:   Página de Gestión de Empleados
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página de gestión completa de empleados
//               para administradores. Incluye funcionalidades de búsqueda,
//               filtrado por estado, creación, edición, eliminación y gestión
//               de datos biométricos. Proporciona una interfaz moderna con
//               animaciones, estados de carga y navegación fluida entre
//               diferentes vistas de gestión de empleados.
//
// @NombreArchivo: empleados_page.dart
// @Ubicacion:    lib/views/admin/empleados_page.dart
// @FechaInicio:  15/05/2025
// @FechaFin:     25/05/2025
// -----------------------------------------------------------------------------
// @Modificacion: [Número de modificación]
// @Fecha:        [Fecha de Modificación]
// @Autor:        [Nombre de quien modificó]
// @Descripción:  [Descripción de los cambios realizados]
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoface/views/admin/empleado_detail_page.dart';
import 'package:geoface/views/admin/empleado_form_page.dart';
import 'package:geoface/views/admin/registro_biometrico_page.dart';
import 'package:provider/provider.dart';
import '../../controllers/empleado_controller.dart';
import '../../models/empleado.dart';

/// EmpleadosPage: Versión mejorada con mejor UX y animaciones
class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> with TickerProviderStateMixin {
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
    await Provider.of<EmpleadoController>(context, listen: false).getEmpleados();
  }
  
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    
    // Feedback háptico
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
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _toggleEmpleadoStatus(Empleado empleado) async {
    final controller = Provider.of<EmpleadoController>(context, listen: false);
    final success = await controller.toggleEmpleadoActivo(empleado);
    if (success) {
      _showFeedback('Estado de ${empleado.nombreCompleto} actualizado.');
    } else {
      _showFeedback('Error al actualizar el estado.', isError: true);
    }
  }

  Future<void> _deleteEmpleado(Empleado empleado) async {
    final controller = Provider.of<EmpleadoController>(context, listen: false);
    final success = await controller.deleteEmpleado(empleado.id);
    if (success) {
      _showFeedback('${empleado.nombreCompleto} ha sido eliminado.');
    } else {
      _showFeedback('Error al eliminar el empleado.', isError: true);
    }
  }
  
  String _getInitials(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return "?";
    final names = nombreCompleto.trim().split(' ');
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names.first[0]}${names.last[0]}'.toUpperCase();
  }
  
  List<Empleado> _filterEmpleados(List<Empleado> empleados) {
    final query = _searchController.text.toLowerCase();
    
    // Filtrar por estado
    List<Empleado> filteredByStatus = empleados;
    switch (_selectedFilter) {
      case 'active':
        filteredByStatus = empleados.where((e) => e.activo).toList();
        break;
      case 'inactive':
        filteredByStatus = empleados.where((e) => !e.activo).toList();
        break;
      default:
        filteredByStatus = empleados;
    }
    
    // Filtrar por texto de búsqueda
    if (query.isEmpty) return filteredByStatus;
    return filteredByStatus.where((e) {
      return e.nombreCompleto.toLowerCase().contains(query) ||
             e.correo.toLowerCase().contains(query) ||
             e.dni.toLowerCase().contains(query) ||
             e.cargo.toLowerCase().contains(query);
    }).toList();
  }

  // --- MÉTODOS DE NAVEGACIÓN ---

  void _navigateToForm({Empleado? empleado}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            EmpleadoFormPage(empleado: empleado),
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

  // Esta función es para ver los detalles y editar
  void _navigateToDetail(Empleado empleado) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmpleadoDetailPage(empleadoId: empleado.id),
      ),
    ).then((_) => _refreshData());
  }

    void _navigateToBiometrico(Empleado empleado) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistroBiometricoScreen(empleado: empleado)),
    );
  }

  // --- WIDGETS DE CONSTRUCCIÓN DE UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EmpleadoController>(
        builder: (context, controller, _) {
          Widget content;
          if (controller.loading && controller.empleados.isEmpty) {
            content = _buildLoadingState();
          } else if (controller.errorMessage != null) {
            content = _buildErrorState(controller.errorMessage!);
          } else {
            final filteredList = _filterEmpleados(controller.empleados);
            content = Column(
              children: [
                _buildHeader(controller.empleados.length),
                _buildSearchAndFilters(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    child: filteredList.isEmpty
                        ? (_searchController.text.isNotEmpty || _selectedFilter != 'all' 
                            ? _buildNoResultsState() 
                            : _buildEmptyState())
                        : _buildEmpleadosList(filteredList),
                  ),
                ),
              ],
            );
          }
          
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            child: content,
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Nuevo Empleado'),
          heroTag: "empleado_fab",
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
          Text('Cargando empleados...'),
        ],
      ),
    );
  }

  Widget _buildHeader(int totalEmpleados) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empleados',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$totalEmpleados empleado${totalEmpleados != 1 ? 's' : ''} registrado${totalEmpleados != 1 ? 's' : ''}',
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
              totalEmpleados.toString(),
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
              hintText: 'Buscar empleados...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              prefixIcon: AnimatedRotation(
                turns: _searchAnimation.value * 0.5,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.search_rounded,
                  color: _isSearchExpanded 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              suffixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _searchController.text.isNotEmpty
                    ? IconButton(
                        key: const ValueKey('clear'),
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _collapseSearch();
                        },
                      )
                    : _isSearchExpanded
                        ? IconButton(
                            key: const ValueKey('collapse'),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded),
                            onPressed: _collapseSearch,
                          )
                        : const SizedBox.shrink(),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onSubmitted: (_) => _collapseSearch(),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final filters = [
      {'key': 'all', 'label': 'Todos', 'icon': Icons.people_rounded},
      {'key': 'active', 'label': 'Activos', 'icon': Icons.check_circle_rounded},
      {'key': 'inactive', 'label': 'Inactivos', 'icon': Icons.pause_circle_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter = filter['key'] as String);
                    HapticFeedback.selectionClick();
                  }
                },
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(filter['label'] as String),
                  ],
                ),
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.onPrimary 
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpleadosList(List<Empleado> empleados) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Espacio para el FAB
      itemCount: empleados.length,
      itemBuilder: (context, index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutBack,
          child: _buildEmpleadoCard(empleados[index], index),
        );
      },
    );
  }
  
  Widget _buildEmpleadoCard(Empleado empleado, int index) {
    final theme = Theme.of(context);
    final colorEstado = empleado.activo 
        ? Colors.green.shade600 
        : theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _showEmpleadoOptions(context, empleado),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'empleado-avatar-${empleado.id}',
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
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(empleado.nombreCompleto),
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
                        tag: 'empleado-nombre-${empleado.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            empleado.nombreCompleto,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        empleado.cargo,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colorEstado,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  empleado.activo ? 'Activo' : 'Inactivo',
                                  style: TextStyle(
                                    color: colorEstado,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (empleado.hayDatosBiometricos)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fingerprint,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay empleados',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comienza agregando tu primer empleado',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Agregar Empleado'),
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 50,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin resultados',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron empleados con los filtros aplicados',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ocurrió un error',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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

  void _showEmpleadoOptions(BuildContext context, Empleado empleado) {
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
                // Handle indicator
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Avatar y información
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.primaryContainer.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(empleado.nombreCompleto),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empleado.nombreCompleto,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            empleado.cargo,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            empleado.correo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Opciones
                _buildOptionTile(
                  Icons.edit_rounded,
                  'Editar Perfil',
                  'Modificar información del empleado',
                  () {
                    Navigator.pop(context);
                    _navigateToDetail(empleado);
                  },
                ),
                
                _buildOptionTile(
                  Icons.fingerprint_rounded,
                  'Datos Biométricos',
                  empleado.hayDatosBiometricos 
                      ? 'Datos configurados' 
                      : 'Configurar datos biométricos',
                  () {
                    Navigator.pop(context);
                    _navigateToBiometrico(empleado);
                  },
                  trailing: empleado.hayDatosBiometricos 
                      ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20)
                      : Icon(Icons.radio_button_unchecked_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                ),
                
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        empleado.activo 
                            ? Icons.toggle_on_rounded 
                            : Icons.toggle_off_rounded,
                        color: empleado.activo 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estado del Empleado',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              empleado.activo ? 'Activo' : 'Inactivo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: empleado.activo 
                                    ? Colors.green.shade600 
                                    : theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: empleado.activo,
                        onChanged: (value) {
                          Navigator.pop(context);
                          _toggleEmpleadoStatus(empleado);
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildOptionTile(
                  Icons.delete_outline_rounded,
                  'Eliminar Empleado',
                  'Esta acción no se puede deshacer',
                  () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(empleado);
                  },
                  isDestructive: true,
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive 
        ? theme.colorScheme.error 
        : theme.colorScheme.onSurface;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
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
              border: Border.all(
                color: isDestructive 
                    ? theme.colorScheme.error.withOpacity(0.2)
                    : theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive 
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDestructive 
                              ? theme.colorScheme.error.withOpacity(0.7)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ] else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Empleado empleado) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Eliminar Empleado'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de que desea eliminar a ${empleado.nombreCompleto}?',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEmpleado(empleado);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}