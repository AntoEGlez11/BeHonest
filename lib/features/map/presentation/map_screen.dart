
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../business/domain/business.dart';
import '../providers/business_provider.dart';
import '../application/map_controller.dart' as logic;

// UI Imports
import '../../home/presentation/widgets/floating_search_bar.dart';
import '../../home/presentation/widgets/custom_drawer.dart';
import '../../business/presentation/registration_modal.dart';
import 'widgets/rating_modal.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _hasMovedToUser = false;
  bool _isSelectingLocation = false;
  bool _shouldAutoFollow = true; // "No se mueva" logic: toggle this
  LatLng? _draggedCenter;

  void _startSelectionMode() {
    setState(() {
      _isSelectingLocation = true;
      _shouldAutoFollow = false; // Disable auto-follow when selecting
    });
    
    // Initial center for selection
    final userLoc = ref.read(logic.mapControllerProvider).userLocation;
    if (userLoc != null) {
      _draggedCenter = userLoc;
      _mapController.move(userLoc, 17); // Zoom in for precision
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (_shouldAutoFollow) {
        setState(() => _shouldAutoFollow = false);
      }
    }
    
    // Update the debouncer
    ref.read(debouncedMapPositionProvider.notifier).updatePosition(
      MapPosition(center: camera.center, bounds: camera.visibleBounds, zoom: camera.zoom),
    );

    if (_isSelectingLocation) {
      setState(() {
        _draggedCenter = camera.center;
      });
    }
  }

  void _recenterMap() {
    final userLoc = ref.read(logic.mapControllerProvider).userLocation;
    if (userLoc != null) {
      _mapController.move(userLoc, 15);
      setState(() {
        _shouldAutoFollow = true; // Re-enable auto-follow
        // If selecting, reset center to user? Or just move map? 
        // Waze behavior: just moves map, selection pin stays center.
      });
    }
  }

  void _confirmSelection() {
    if (_draggedCenter == null) return;
    
    // Check geofence (Simple haversine or geolocator distance)
    final userLoc = ref.read(logic.mapControllerProvider).userLocation;
    if (userLoc == null) return;
    
    final distance = const Distance().as(LengthUnit.Meter, userLoc, _draggedCenter!);
    
    if (distance > 100) { // 100 meters limit
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be within 100m of the location! 🚫'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSelectingLocation = false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegistrationModal(selectedLocation: _draggedCenter),
    );
  }

  void _showBusinessInfoModal(Business business) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconData(business.category), color: Colors.blue, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        business.category.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (business.score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(business.score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (business.description != null) ...[
              Text(business.description!),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showRatingModal(business);
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('Calificar Servicio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingModal(Business business) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingModal(business: business),
    );
  }

  IconData _getIconData(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('restaurante') || cat.contains('restaurant') || cat.contains('food') || cat.contains('burger') || cat.contains('pizza')) {
      return Icons.restaurant;
    } else if (cat.contains('taller') || cat.contains('mechanic') || cat.contains('repair') || cat.contains('auto')) {
      return Icons.build_circle;
    } else if (cat.contains('tienda') || cat.contains('shop') || cat.contains('store') || cat.contains('convenience') || cat.contains('market')) {
      return Icons.shopping_bag;
    } else if (cat.contains('puesto') || cat.contains('stand') || cat.contains('kiosk')) {
      return Icons.storefront;
    } else if (cat.contains('cafe') || cat.contains('coffee')) {
      return Icons.local_cafe;
    } else if (cat.contains('bar') || cat.contains('pub')) {
      return Icons.local_bar; // or local_drink
    }
    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the Logic MapState
    final mapState = ref.watch(logic.mapControllerProvider);
    final businessesAsync = ref.watch(nearbyBusinessesProvider);

    // Removed auto-move to business. This causes the "reset zoom" bug.
    // ref.listen(nearbyBusinessesProvider, ...);

    // Listen to location changes to move the map ONLY if auto-follow is enabled
    ref.listen(logic.mapControllerProvider, (previous, next) {
      if (next.userLocation != null) {
        if (!_hasMovedToUser) {
           _mapController.move(next.userLocation!, 15);
           _hasMovedToUser = true;
           // Trigger initial fetch
           // We need to wait a frame for the move to complete and camera to update
           WidgetsBinding.instance.addPostFrameCallback((_) {
              final camera = _mapController.camera;
              ref.read(debouncedMapPositionProvider.notifier).updatePosition(
                MapPosition(center: camera.center, bounds: camera.visibleBounds, zoom: camera.zoom),
              );
           });
        } else if (_shouldAutoFollow) {
           _mapController.move(next.userLocation!, _mapController.camera.zoom);
           // Update businesses as we follow user? Maybe not necessary if we use debounce
        }
      }
    });

    final initialCenter = const LatLng(25.6866, -100.3161); // Monterrey

    // Calculate distance for UI feedback
    bool isWithinRange = true;
    if (_isSelectingLocation && mapState.userLocation != null && _draggedCenter != null) {
      final dist = const Distance().as(LengthUnit.Meter, mapState.userLocation!, _draggedCenter!);
      isWithinRange = dist <= 100;
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      // FAB only when NOT selecting
      floatingActionButton: _isSelectingLocation 
          ? null 
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Recenter Button
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: _recenterMap,
                  backgroundColor: Colors.grey[800],
                  child: Icon(Icons.my_location, color: _shouldAutoFollow ? Colors.blue : Colors.white),
                ),
                const SizedBox(height: 16),
                // Add Business Button
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: _startSelectionMode,
                  child: const Icon(Icons.add_location_alt_outlined),
                ),
                const SizedBox(height: 16),
                // Helper/Guidance Button
                FloatingActionButton.small(
                  heroTag: 'help',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('💡 Tips:\n• Tap pins for info\n• Use + to add spots\n• Rate places you visit!'),
                        duration: Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Icon(Icons.help_outline),
                ),
                // Adjust for bottom padding (e.g. navigation bar if present)
                const SizedBox(height: 20),
              ],
            ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 13.0,
              onPositionChanged: _onMapPositionChanged, // Track manual movement
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Disable rotation for stability?
              ),
            ),
            children: [
              TileLayer(
                // urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', // DARK MODE
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // STANDARD OSM (Light)
                userAgentPackageName: 'com.example.behonest',
                // retinaMode: true, // Disable retina for ensuring compatibility
                // subdomains: const ['a', 'b', 'c', 'd'], // OSM doesn't use subdomains usually, or uses a,b,c
                tileProvider: NetworkTileProvider(),
              ),
              
              // Geofence Circle (Only in Selection Mode)
              if (_isSelectingLocation && mapState.userLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: mapState.userLocation!,
                      radius: 100, // 100 meters
                      useRadiusInMeter: true,
                      color: Colors.cyan.withValues(alpha: 0.1),
                      borderColor: Colors.cyan.withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              if (mapState.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapState.userLocation!,
                      width: 60,
                      height: 60,
                      child: const _UserMarker(),
                    ),
                  ],
                ),
              // Business Markers Layer
              if (!_isSelectingLocation) // Hide others while selecting? Optional. Let's keep them.
              businessesAsync.when(
                data: (businesses) => MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80, // Tighter clusters
                    size: const Size(40, 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    disableClusteringAtZoom: 14, // LOD: Show points at zoom 15+
                    markers: businesses.asMap().entries.map((entry) {
                    if (entry.key == 0) print('UI Rendering ${businesses.length} markers'); // DEBUG UI
                    final index = entry.key;
                    final business = entry.value;
                    return Marker(
                      point: LatLng(business.latitude, business.longitude),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showBusinessInfoModal(business),
                        child: _BusinessMarker(business: business),
                      ),
                    );
                  }).toList(),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
                loading: () => const MarkerLayer(markers: []),
                error: (err, stack) {
                  debugPrint('Error loading businesses: $err\n$stack');
                  return const MarkerLayer(markers: []);
                },
              ),
            ],
          ),
          
          // Floating Search Bar (Top) - Hide when selecting
          if (!_isSelectingLocation)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: FloatingSearchBar(
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                )
                .animate()
                .slideY(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(),
              ),
            ),

          // Loading Indicator
          if (mapState.isLoading)
             Positioned(
               top: 100, 
               left: 0, 
               right: 0, 
               child: Center(
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: Colors.black54,
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: const Text('Locating...', style: TextStyle(color: Colors.white)),
                 )
               )
             ),

          // SELECTION INTERFACE overlays
          if (_isSelectingLocation) ...[
            // Dark overlay instructions
            Positioned(
              top: 50,
              left: 0, 
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Drag map to place pin', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ),
            
            // Center Pin
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40), // Offset for pin point
                child: Icon(
                  Icons.location_on, 
                  size: 50, 
                  color: isWithinRange ? Colors.cyan : Colors.red
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
              ),
            ),

            // Confirm Button Area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.black87,
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isSelectingLocation = false),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isWithinRange ? _confirmSelection : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isWithinRange ? Colors.cyan : Colors.grey[800],
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isWithinRange ? 'Select Here' : 'Too Far'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Icon(
          Icons.person_pin_circle,
          color: Colors.blueAccent,
          size: 32,
        ),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1500.ms);
  }
}

class _BusinessMarker extends StatelessWidget {
  final Business business;

  const _BusinessMarker({required this.business});

  IconData _getIconData(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('restaurante') || cat.contains('restaurant') || cat.contains('food') || cat.contains('burger') || cat.contains('pizza')) {
      return Icons.restaurant;
    } else if (cat.contains('taller') || cat.contains('mechanic') || cat.contains('repair') || cat.contains('auto')) {
      return Icons.build_circle;
    } else if (cat.contains('tienda') || cat.contains('shop') || cat.contains('store') || cat.contains('convenience') || cat.contains('market')) {
      return Icons.shopping_bag;
    } else if (cat.contains('puesto') || cat.contains('stand') || cat.contains('kiosk')) {
      return Icons.storefront;
    } else if (cat.contains('cafe') || cat.contains('coffee')) {
      return Icons.local_cafe;
    } else if (cat.contains('bar') || cat.contains('pub')) {
      return Icons.local_bar; // or local_drink
    }
    return Icons.place;
  }

  Color _getColor(String category) {
    switch (category.toLowerCase()) {
      case 'taller': return Colors.orange;
      case 'restaurante': return Colors.redAccent;
      case 'puesto': return Colors.green;
      case 'tienda': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(business.category);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            _getIconData(business.category),
            size: 20,
            color: color,
          ),
        ),
        // Triangle/Arrow
        Icon(Icons.arrow_drop_down, color: color, size: 24),
      ],
    );
  }
}

// _ArrowClipper removed to fix compilation/web issues
