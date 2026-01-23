import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../../discovery/domain/taxonomy.dart';

class MapState {
  final LatLng? userLocation;
  final bool isLoading;
  final Vibe? activeVibe;

  MapState({this.userLocation, this.isLoading = true, this.activeVibe});

  MapState copyWith({LatLng? userLocation, bool? isLoading, Vibe? activeVibe}) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      isLoading: isLoading ?? this.isLoading,
      activeVibe: activeVibe ?? this.activeVibe,
    );
  }
}

class MapController extends StateNotifier<MapState> {
  final LocationService _locationService;

  MapController(this._locationService) : super(MapState()) {
    print('MapController created. Initializing location...');
    _randomizeVibe();
    _initLocation();
  }

  void _randomizeVibe() {
    final validVibes = Vibe.values.where((v) => v != Vibe.unknown).toList();
    final random = Random();
    final selected = validVibes[random.nextInt(validVibes.length)];
    state = state.copyWith(activeVibe: selected);
    print('Honest Roulette: Selected Vibe -> ${selected.name}');
  }
  
  void clearVibe() {
     state = state.copyWith(activeVibe: null); // User cleared filter
  }

  Future<void> _initLocation() async {
    try {
      // Try last known first for speed
      final lastKnown = await _locationService.getLastKnownLocation();
      if (lastKnown != null) {
        state = state.copyWith(userLocation: lastKnown, isLoading: false);
        return;
      }

      final location = await _locationService.getCurrentLocation().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('MapController: Location timed out. Using default fallback.');
          return const LatLng(19.390354, -99.189916); // CDMX default
        },
      );
      state = state.copyWith(userLocation: location, isLoading: false);
      
      // Listen to stream updates
      _locationService.getPositionStream().listen((location) {
        state = state.copyWith(userLocation: location);
      });
      print('MapController: Location initialized: $location');
    } catch (e) {
      print('MapController: Error initializing location: $e');
      // Fallback to CDMX
      state = state.copyWith(
        isLoading: false,
        userLocation: const LatLng(19.390354, -99.189916)
      );
    }
  }
}

final locationServiceProvider = Provider((ref) => LocationService());

final mapControllerProvider = StateNotifierProvider<MapController, MapState>((ref) {
  return MapController(ref.watch(locationServiceProvider));
});
