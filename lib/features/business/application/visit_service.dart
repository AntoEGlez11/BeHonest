import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/business.dart';
import '../../map/application/map_controller.dart';

class VisitService {
  // Threshold in meters (PoV requirement)
  static const double kVerificationThreshold = 50.0;

  bool isWithinRange(LatLng userLocation, Business business) {
    final businessLoc = LatLng(business.latitude, business.longitude);
    final distance = const Distance().as(LengthUnit.Meter, userLocation, businessLoc);
    return distance <= kVerificationThreshold;
  }

  double getDistance(LatLng userLocation, Business business) {
    final businessLoc = LatLng(business.latitude, business.longitude);
    return const Distance().as(LengthUnit.Meter, userLocation, businessLoc);
  }
}

final visitServiceProvider = Provider<VisitService>((ref) {
  return VisitService();
});

// Helper provider to check range for a specific business
final isWithinRangeProvider = Provider.family<bool, Business>((ref, business) {
  final userLoc = ref.watch(mapControllerProvider).userLocation;
  if (userLoc == null) return false;
  return ref.read(visitServiceProvider).isWithinRange(userLoc, business);
});
