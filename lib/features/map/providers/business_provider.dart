import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart';
import '../../business/data/business_repository.dart';
import '../../business/domain/business.dart';
import '../../discovery/domain/taxonomy.dart';
import '../../discovery/application/search_service.dart';

import '../application/map_controller.dart';



// State provider for current map bounds/center
final mapBoundsProvider = StateProvider<MapPosition?>((ref) => null);

// Debounced provider that only updates when mapBoundsProvider is stable for 500ms
final debouncedBoundsProvider = FutureProvider<MapPosition?>((ref) async {
  // Watch the raw bounds
  final bounds = ref.watch(mapBoundsProvider);
  
  // Debounce: Yield value only after 500ms of silence
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Check if it's still the same value (simple check, or reliance on riverpod cancelling)
  // Actually, Riverpod 'future' provider doesn't strictly debounce by itself in this syntax effectively
  // without a timer cancellation mechanism if we were just using a stream.
  // But standard pattern: use a StreamProvider w/ debounce transformer OR 
  // simply rely on the fact that if this provider rebuilds, the previous one is cancelled/ignored?
  // Use a Timer in a StateNotifier is better.
  return bounds;
});

// Implementation using a proper Stream/Notifier for Debouncing
class DebouncedMapPosition extends StateNotifier<MapPosition?> {
  DebouncedMapPosition() : super(null);
  Timer? _timer;

  void updatePosition(MapPosition newPos) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 350), () {
      state = newPos;
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final debouncedMapPositionProvider = StateNotifierProvider<DebouncedMapPosition, MapPosition?>((ref) {
  return DebouncedMapPosition();
});


class MapPosition {
  final LatLng? center;
  final LatLngBounds? bounds;
  final double? zoom;

  MapPosition({this.center, this.bounds, this.zoom});
}

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Cache Store: Key -> (Timestamp, Data)
final businessCacheProvider = Provider<_BusinessCache>((ref) => _BusinessCache());

class _BusinessCache {
  final Map<String, ({DateTime time, List<Business> data})> _storage = {};
  
  String _getKey(LatLngBounds bounds, Vibe? vibe) {
    // Round to 3 decimals to group very similar views (approx 100m)
    final n = bounds.north.toStringAsFixed(3);
    final s = bounds.south.toStringAsFixed(3);
    final e = bounds.east.toStringAsFixed(3);
    final w = bounds.west.toStringAsFixed(3);
    final v = vibe?.name ?? 'all';
    return '$n|$s|$e|$w|$v';
  }

  List<Business>? get(LatLngBounds bounds, Vibe? vibe) {
    final key = _getKey(bounds, vibe);
    final entry = _storage[key];
    if (entry == null) return null;
    
    // TTL: 30 seconds
    if (DateTime.now().difference(entry.time).inSeconds > 30) {
      _storage.remove(key);
      return null;
    }
    return entry.data;
  }

  void set(LatLngBounds bounds, Vibe? vibe, List<Business> data) {
    if (data.isEmpty) return; // Don't cache empty if it might be error
    _storage[_getKey(bounds, vibe)] = (time: DateTime.now(), data: data);
  }
}

final nearbyBusinessesProvider = FutureProvider.autoDispose<List<Business>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final cache = ref.watch(businessCacheProvider);
  
  // Listen to the DEBOUNCED map position/bounds
  final mapPos = ref.watch(debouncedMapPositionProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
 
  // Watch Active Vibe (Honest Roulette)
  final activeVibe = ref.watch(mapControllerProvider).activeVibe;

  if (mapPos == null) {
    return [];
  }

  // Cache Check (including Vibe key)
  if (searchQuery.isEmpty && mapPos.bounds != null) {
    final cached = cache.get(mapPos.bounds!, activeVibe);
    if (cached != null) {
      print('nearbyBusinessesProvider: Measured Hit! Serving ${cached.length} businesses from Cache (Vibe: ${activeVibe?.name}).');
      return cached;
    }
  }

  print('nearbyBusinessesProvider: Fetching businesses for bounds center: ${mapPos.center} | activeVibe: ${activeVibe?.name}');
  
  List<Business> businesses = [];

  // Use the viewport based fetch
  if (mapPos.bounds != null) {
    businesses = await repo.getBusinesses(
      minLat: mapPos.bounds!.south,
      maxLat: mapPos.bounds!.north,
      minLng: mapPos.bounds!.west,
      maxLng: mapPos.bounds!.east,
    );
  } else {
    // Fallback to simple radius
    businesses = await repo.getNearbyBusinesses(
      mapPos.center!.latitude,
      mapPos.center!.longitude,
      radiusKm: 20, 
    );
  }

  // Determine effective Vibe
  // If search is active, it overrides the "Roulette" vibe unless the search itself specifies a vibe.
  final filters = SearchService.parse(searchQuery);
  final effectiveVibe = (searchQuery.isNotEmpty) ? filters.vibe : activeVibe;
  
  if (effectiveVibe != null) {
      businesses = businesses.where((b) => b.vibe == effectiveVibe).toList();
  }

  // Save to Cache (if search empty)
  if (searchQuery.isEmpty && mapPos.bounds != null) {
    cache.set(mapPos.bounds!, activeVibe, businesses);
  }

  // Filter by Search Filters (NLP)
  if (searchQuery.isNotEmpty) {
      businesses = businesses.where((b) {
          // 1. Text Match
          bool textMatch = true;
          if (filters.text != null) {
             final q = filters.text!.toLowerCase(); // Actually, raw query
             // We use the raw query for name/desc match, but refined filters for other things
             // To avoid over-filtering, if we found specific filters (like 'wifi'), we might relax the name match?
             // For now, Strict AND.
             
             // If the query was purely a vibe/amenity (e.g. "wifi"), then don't enforce name match?
             // Simple approach: Match name/desc against raw query standard way
             textMatch = b.name.toLowerCase().contains(q) || 
                         b.category.toLowerCase().contains(q) ||
                         (b.description?.toLowerCase().contains(q) ?? false);
                         
             // NLP Overrides: If we detected 'tacos' as subcategory, allow match even if name doesn't say 'tacos'
             if (filters.subcategory != null) {
                if ((b.subcategory?.toLowerCase().contains(filters.subcategory!) ?? false) || 
                    b.category.toLowerCase().contains(filters.subcategory!)) {
                    textMatch = true;
                }
             }
          }
          
          // 2. Amenities
          bool amenityMatch = true;
          for (var a in filters.amenities) {
             if (!b.amenities.contains(a)) {
                amenityMatch = false; 
                break;
             }
          }

          return textMatch && amenityMatch;
      }).toList();
  }

  return businesses;
});

// GHOST HUNTING PROVIDER (Bounty Hunter)
// Fetches unrated businesses very close to the user, regardless of Vibe filter.
final ghostBusinessesProvider = FutureProvider.autoDispose<List<Business>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final mapPos = ref.watch(debouncedMapPositionProvider);
  
  if (mapPos?.center == null) return [];

  // Fetch strictly nearby (500m - 1km)
  final nearby = await repo.getNearbyBusinesses(
    mapPos!.center!.latitude,
    mapPos.center!.longitude,
    radiusKm: 1.0, // Small radius
  );

  final ghosts = nearby.where((b) => b.score == null || b.score == 0).take(5).toList();
  
  return ghosts;
});

// DENSITY PROVIDER (Flag Planting)
// Checks if the user is in an unexplored void (< 3 businesses in 200m)
final densityProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final mapPos = ref.watch(debouncedMapPositionProvider);
  
  if (mapPos?.center == null) return 10; 

  return await repo.countNearby(mapPos!.center!.latitude, mapPos.center!.longitude, 0.2);
});
