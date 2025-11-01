// -----------------------------------------------------------------------------
// @Encabezado:   Página de Gestión de Sedes
// @Autor:        Jorge Luis Briceño Diaz
// @Descripción:  Este archivo define la página de gestión completa de sedes
//               para administradores. Incluye funcionalidades de búsqueda,
//               filtrado por estado, creación, edición, eliminación y cambio
//               de estado de sedes. Proporciona una interfaz moderna con
//               animaciones, validaciones de integridad referencial y
//               navegación fluida entre diferentes vistas de gestión.
//
// @NombreArchivo: sedes_page.dart
// @Ubicacion:    lib/views/admin/sedes_page.dart
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
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../controllers/sede_controller.dart';
import '../../controllers/empleado_controller.dart';
import '../../models/sede.dart';
import 'sede_form_page.dart';

/// Página principal para visualizar y gestionar la lista de Sedes.
///
/// Presenta una interfaz de usuario inspirada en la `EmpleadosPage` para mantener
/// la consistencia visual y de experiencia de usuario en la aplicación.
/// Incluye funcionalidades como búsqueda, filtrado, y acciones CRUD (Crear, Leer, Actualizar, Eliminar).
class SedesPage extends StatefulWidget {
  const SedesPage({super.key});

  @override
  State<SedesPage> createState() => _SedesPageState();
}

/// Estado de la `SedesPage`.
///
/// `with TickerProviderStateMixin` se utiliza para proporcionar los `Ticker`
/// necesarios para los `AnimationController`, que gestionan las animaciones de la UI.
class _SedesPageState extends State<SedesPage> with TickerProviderStateMixin {
  // --- CONTROLADORES Y NODOS DE FOCUS ---

  /// Controlador para el campo de texto de búsqueda.
  final TextEditingController _searchController = TextEditingController();
  
  /// Nodo de focus para el campo de búsqueda, para controlar su estado (enfocado/desenfocado).
  final FocusNode _searchFocusNode = FocusNode();
  
  // --- CONTROLADORES DE ANIMACIÓN ---

  /// Controlador para la animación del Floating Action Button (FAB).
  late AnimationController _fabAnimationController;
  
  /// Controlador para la animación de expansión/colapso de la barra de búsqueda.
  late AnimationController _searchAnimationController;
  
  // --- ANIMACIONES ---

  /// Animación específica para el FAB, con una curva elástica para un efecto de "rebote".
  late Animation<double> _fabAnimation;
  
  /// Animación para la barra de búsqueda, con una curva suave para transiciones elegantes.
  late Animation<double> _searchAnimation;
  
  // --- ESTADO DE LA UI ---

  /// Booleano que indica si la barra de búsqueda está en su estado expandido.
  bool _isSearchExpanded = false;
  
  /// String que almacena el filtro actualmente seleccionado ('all', 'active', 'inactive').
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    
    // 1. Inicialización de los controladores de animación.
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // 2. Vinculación de las animaciones a sus controladores con curvas específicas.
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOutCubic,
    );
    
    // 3. Inicia la animación de entrada del FAB.
    _fabAnimationController.forward();
    
    // 4. Carga de datos iniciales.
    // `Future.microtask` ejecuta el código después del primer frame,
    // evitando que operaciones pesadas bloqueen la renderización inicial de la UI.
    Future.microtask(() {
      if (!mounted) return;
      // Obtiene la lista de sedes.
      Provider.of<SedeController>(context, listen: false).getSedes();
      // Precarga la lista de empleados. Esto es una optimización para que la validación
      // al intentar eliminar una sede sea instantánea.
      Provider.of<EmpleadoController>(context, listen: false).getEmpleados();
    });

    // 5. Se añaden listeners para reaccionar a cambios en el texto de búsqueda y el focus.
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    // Es crucial liberar los recursos de los controladores y nodos para evitar memory leaks.
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE LÓGICA Y ACCIONES ---

  /// Se llama cada vez que el texto en el `_searchController` cambia.
  /// Provoca una reconstrucción del widget para aplicar el filtro de búsqueda.
  void _onSearchChanged() {
    setState(() {});
  }

  /// Se llama cuando el `_searchFocusNode` gana o pierde el foco.
  /// Se utiliza para expandir automáticamente la barra de búsqueda cuando el usuario toca en ella.
  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus && !_isSearchExpanded) {
      _expandSearch();
    }
  }

  /// Inicia la animación para expandir la barra de búsqueda.
  void _expandSearch() {
    setState(() => _isSearchExpanded = true);
    _searchAnimationController.forward();
    HapticFeedback.lightImpact(); // Feedback táctil sutil.
  }

  /// Inicia la animación para contraer la barra de búsqueda.
  /// Solo se contrae si el campo de texto está vacío.
  void _collapseSearch() {
    if (_searchController.text.isEmpty) {
      setState(() => _isSearchExpanded = false);
      _searchAnimationController.reverse();
      _searchFocusNode.unfocus(); // Quita el foco del campo de texto.
    }
  }

  /// Realiza la acción de "pull-to-refresh" para recargar los datos de las sedes.
  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    await Provider.of<SedeController>(context, listen: false).getSedes();
  }
  
  /// Muestra un `SnackBar` para dar feedback al usuario (éxito o error).
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return; // Comprobación de seguridad para evitar errores si el widget no está en pantalla.
    
    HapticFeedback.mediumImpact(); // Feedback táctil más notorio.
    
    ScaffoldMessenger.of(context).clearSnackBars(); // Limpia SnackBars anteriores.
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
        behavior: SnackBarBehavior.floating, // Estilo flotante.
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Cambia el estado (activo/inactivo) de una sede.
  Future<void> _toggleSedeStatus(Sede sede) async {
    final controller = Provider.of<SedeController>(context, listen: false);
    // Crea una copia de la sede con el estado 'activa' invertido.
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

  /// Elimina una sede, previa validación.
  Future<void> _deleteSede(Sede sede) async {
    final empleadoController = Provider.of<EmpleadoController>(context, listen: false);
    // Comprueba si hay empleados asignados a esta sede.
    final empleadosEnSede = await empleadoController.getEmpleadosPorSede(sede.id);

    if (empleadosEnSede.isNotEmpty) {
      // Si hay empleados, no permite la eliminación y muestra un error.
      _showFeedback(
        'No se puede eliminar: La sede tiene ${empleadosEnSede.length} empleado(s) asignado(s).',
        isError: true
      );
      return;
    }

    // Si no hay empleados, procede con la eliminación.
    if (!mounted) return;
    final sedeController = Provider.of<SedeController>(context, listen: false);
    final success = await sedeController.deleteSede(sede.id);
    if (!mounted) return;
    if (success) {
      _showFeedback('${sede.nombre} ha sido eliminada.');
    } else {
      _showFeedback('Error al eliminar la sede.', isError: true);
    }
  }
  
  /// Genera las iniciales a partir del nombre de una sede para mostrar en el avatar.
  String _getSedeInitials(String nombreSede) {
    if (nombreSede.isEmpty) return "S";
    final words = nombreSede.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return "S";
    if (words.length == 1) return words[0][0].toUpperCase();
    // Toma la primera letra de la primera y última palabra.
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
  
  /// Filtra la lista de sedes basándose en el estado seleccionado y el texto de búsqueda.
  List<Sede> _filterSedes(List<Sede> sedes) {
    final query = _searchController.text.toLowerCase();
    
    // 1. Filtrado por estado (Todas, Activas, Inactivas).
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
    
    // 2. Filtrado por texto de búsqueda sobre el resultado anterior.
    if (query.isEmpty) return filteredByStatus;
    return filteredByStatus.where((s) {
      // La búsqueda se aplica al nombre y la dirección.
      return s.nombre.toLowerCase().contains(query) ||
             s.direccion.toLowerCase().contains(query);
    }).toList();
  }

  // --- MÉTODOS DE NAVEGACIÓN ---

  /// Navega a la página de formulario para crear o editar una sede.
  void _navigateToForm({Sede? sede}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        // Construye la página de destino.
        pageBuilder: (context, animation, secondaryAnimation) => 
            SedeFormPage(sede: sede), // Se pasa la sede si se está editando.
        // Construye la transición de animación (deslizamiento desde la derecha).
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
    ).then((_) => _refreshData()); // Al volver de la página, refresca los datos.
  }

  // --- WIDGETS DE CONSTRUCCIÓN DE UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SedeController>(
        // `Consumer` se reconstruye automáticamente cuando `SedeController` notifica cambios.
        builder: (context, controller, _) {
          Widget content;
          // Decide qué widget mostrar según el estado del controlador.
          if (controller.loading && controller.sedes.isEmpty) {
            content = _buildLoadingState(); // Muestra spinner si está cargando y no hay datos.
          } else if (controller.errorMessage != null) {
            content = _buildErrorState(controller.errorMessage!); // Muestra error si lo hay.
          } else {
            // Si hay datos, construye la UI principal.
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
                            ? _buildNoResultsState() // Muestra si no hay resultados para el filtro.
                            : _buildEmptyState())    // Muestra si la lista general está vacía.
                        : _buildSedesList(filteredList), // Muestra la lista de sedes.
                  ),
                ),
              ],
            );
          }
          
          // `AnimatedSwitcher` proporciona una transición suave (fade) entre los diferentes
          // estados de la UI (loading, error, content).
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: content,
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation, // Aplica la animación de escala al FAB.
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(),
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Nueva Sede'),
          heroTag: "sede_fab", // Tag único para la animación Hero.
        ),
      ),
    );
  }

  /// Widget que se muestra durante el estado de carga inicial.
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

  /// Construye la cabecera de la página con el título y el contador total de sedes.
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
  
  /// Contenedor para la barra de búsqueda y los chips de filtro.
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

  /// Construye la barra de búsqueda animada.
  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    // `AnimatedBuilder` reconstruye el widget cuando la animación `_searchAnimation` cambia de valor.
    return AnimatedBuilder(
      animation: _searchAnimation,
      builder: (context, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // El color y grosor del borde cambian si la barra está expandida.
            border: Border.all(
              color: _isSearchExpanded 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withValues(alpha:0.3),
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
              // Muestra un botón de limpiar solo si hay texto.
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

  /// Construye los chips de filtro (Todas, Activas, Inactivas).
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
                  // Actualiza el estado del filtro seleccionado.
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
                color: isSelected ? Colors.transparent : theme.colorScheme.outline.withValues(alpha:0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Construye la lista de sedes utilizando `ListView.builder` para un rendimiento óptimo.
  Widget _buildSedesList(List<Sede> sedes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Espacio inferior para el FAB.
      itemCount: sedes.length,
      itemBuilder: (context, index) {
        return _buildSedeCard(sedes[index]);
      },
    );
  }
  
  /// Construye una tarjeta individual para una sede.
  Widget _buildSedeCard(Sede sede) {
    final theme = Theme.of(context);
    final colorEstado = sede.activa ? Colors.green.shade600 : theme.colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha:0.1)),
        ),
        child: InkWell(
          onTap: () => _showSedeOptions(context, sede), // Muestra opciones al tocar.
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // `Hero` widget para una animación de transición suave del avatar.
                Hero(
                  tag: 'sede-avatar-${sede.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.primaryContainer.withValues(alpha:0.7),
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
                      // `Hero` para la animación del nombre.
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
                      // "Píldora" de estado (Activa/Inactiva).
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorEstado.withValues(alpha:0.1),
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

  // --- WIDGETS DE ESTADOS (VACÍO, SIN RESULTADOS, ERROR) ---

  /// Widget que se muestra cuando no hay ninguna sede registrada.
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

  /// Widget que se muestra cuando la búsqueda o el filtro no arrojan resultados.
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

  /// Widget que se muestra cuando ocurre un error al cargar los datos.
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

  // --- BOTTOM SHEET DE OPCIONES ---

  /// Muestra un `ModalBottomSheet` con estilo para las opciones de una sede.
  void _showSedeOptions(BuildContext context, Sede sede) {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el contenido determine la altura.
      backgroundColor: Colors.transparent, // Fondo transparente para aplicar bordes redondeados.
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // El BottomSheet ocupa solo el espacio necesario.
              children: [
                // "Handle" decorativo.
                Container(height: 4, width: 40, decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha:0.4), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                
                // Cabecera del BottomSheet con info de la sede.
                Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withValues(alpha:0.7)]),
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
                
                // Opción para editar.
                _buildOptionTile(Icons.edit_note_rounded, 'Editar Sede', 'Modificar información y ubicación', () {
                  Navigator.pop(context); // Cierra el BottomSheet.
                  _navigateToForm(sede: sede);
                }),
                
                // Widget interactivo para cambiar el estado.
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha:0.2)),
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
                
                // Opción para eliminar (con estilo destructivo).
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

  /// Widget reutilizable para construir cada una de las opciones en el BottomSheet.
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
            border: Border.all(color: isDestructive ? theme.colorScheme.error.withValues(alpha:0.2) : theme.colorScheme.outline.withValues(alpha:0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: isDestructive ? theme.colorScheme.error.withValues(alpha:0.1) : theme.colorScheme.primaryContainer.withValues(alpha:0.3), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: isDestructive ? theme.colorScheme.error.withValues(alpha:0.7) : theme.colorScheme.onSurfaceVariant)),
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

  /// Muestra un diálogo de confirmación antes de eliminar una sede.
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
              Navigator.pop(context); // Cierra el diálogo.
              _deleteSede(sede);      // Llama a la función de eliminación.
            },
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}