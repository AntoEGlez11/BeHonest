import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../business/data/business_repository.dart';
import '../../business/domain/business.dart';

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
  
  String _getKey(LatLngBounds bounds) {
    // Round to 3 decimals to group very similar views (approx 100m)
    final n = bounds.north.toStringAsFixed(3);
    final s = bounds.south.toStringAsFixed(3);
    final e = bounds.east.toStringAsFixed(3);
    final w = bounds.west.toStringAsFixed(3);
    return '$n|$s|$e|$w';
  }

  List<Business>? get(LatLngBounds bounds) {
    final key = _getKey(bounds);
    final entry = _storage[key];
    if (entry == null) return null;
    
    // TTL: 30 seconds
    if (DateTime.now().difference(entry.time).inSeconds > 30) {
      _storage.remove(key);
      return null;
    }
    return entry.data;
  }

  void set(LatLngBounds bounds, List<Business> data) {
    if (data.isEmpty) return; // Don't cache empty if it might be error
    _storage[_getKey(bounds)] = (time: DateTime.now(), data: data);
  }
}

final nearbyBusinessesProvider = FutureProvider.autoDispose<List<Business>>((ref) async {
  final repo = ref.watch(businessRepositoryProvider);
  final cache = ref.watch(businessCacheProvider);
  
  // Listen to the DEBOUNCED map position/bounds
  final mapPos = ref.watch(debouncedMapPositionProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  if (mapPos == null) {
    return [];
  }

  // Cache Check (only if search is empty, to avoiding caching filtered results as the main source)
  if (searchQuery.isEmpty && mapPos.bounds != null) {
    final cached = cache.get(mapPos.bounds!);
    if (cached != null) {
      print('nearbyBusinessesProvider: Measured Hit! Serving ${cached.length} businesses from Cache.');
      return cached;
    }
  }

  print('nearbyBusinessesProvider: Fetching businesses for bounds center: ${mapPos.center}');
  
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

  // Save to Cache (if search empty)
  if (searchQuery.isEmpty && mapPos.bounds != null) {
    cache.set(mapPos.bounds!, businesses);
  }

  // Filter by search query if present
  if (searchQuery.isNotEmpty) {
    businesses = businesses.where((b) {
      return b.name.toLowerCase().contains(searchQuery) || 
             b.category.toLowerCase().contains(searchQuery) ||
             (b.description?.toLowerCase().contains(searchQuery) ?? false);
    }).toList();
  }

  return businesses;
});
