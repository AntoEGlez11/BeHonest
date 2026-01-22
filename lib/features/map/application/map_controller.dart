import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';

class MapState {
  final LatLng? userLocation;
  final bool isLoading;

  MapState({this.userLocation, this.isLoading = true});

  MapState copyWith({LatLng? userLocation, bool? isLoading}) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MapController extends StateNotifier<MapState> {
  final LocationService _locationService;

  MapController(this._locationService) : super(MapState()) {
    print('MapController created. Initializing location...');
    _initLocation();
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
