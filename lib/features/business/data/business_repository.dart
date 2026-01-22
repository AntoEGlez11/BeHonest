
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/business.dart';

class BusinessRepository {
  final SupabaseClient _client;

  BusinessRepository(this._client);

  /// Fetches businesses within a given map viewport.
  /// Currently uses a direct SELECT query. 
  /// @TODO: Switch to PostGIS RPC 'get_businesses_in_bounds' for performance.
  Future<List<Business>> getBusinesses({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    try {
      // Best Way: Server-side filtering using the RPC you just created.
      // This sends the screen boundaries to the DB, and the DB returns ONLY what's inside.
      final response = await _client.rpc('get_businesses_in_bounds', params: {
        'min_lat': minLat,
        'min_lng': minLng,
        'max_lat': maxLat,
        'max_lng': maxLng,
      });

      final List<dynamic> data = response as List<dynamic>;
      print('getBusinesses (RPC): Fetched ${data.length} businesses in view.');
      
      return data.map((json) {
         try {
           return Business.fromJson(json);
         } catch (e) {
           print('Error parsing business: $e');
           rethrow;
         }
      }).toList();
    } catch (e) {
      print('RPC Error (falling back to legacy): $e');
      // Fallback: If RPC fails (e.g. typo in SQL), try the old way temporarily
      // so the app doesn't crash.
       final response = await _client
          .from('businesses')
          .select('id, name, description, category, score, location::text')
          .limit(1000); // Updated limit as requested
          
       return (response as List<dynamic>).map((j) => Business.fromJson(j)).toList();
    }
  }

  /// Real-time listener for businesses
  Stream<List<Business>> watchBusinesses() {
    return _client
        .from('businesses')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Business.fromJson(json)).toList());
  }

  /// Fetches nearby businesses (Radial) - Legacy Support / Map Center
  Future<List<Business>> getNearbyBusinesses(double lat, double lng, {double radiusKm = 10}) async {
    try {
      // Try RPC if available
      // final response = await _client.rpc('nearby_businesses', params: {'lat': lat, 'long': lng, 'radius_meters': radiusKm * 1000});
      
      // Fallback: Just get Top 100 for now until RPC is confirmed
      // We could filter by distance client-side if we downloaded enough.
      // Cast location to text (WKT) so fromJson can parse 'POINT(...)'
      final response = await _client
          .from('businesses')
          .select('id, name, description, category, score, location::text')
          .limit(1000);
      final data = response as List<dynamic>;
      print('getNearbyBusinesses: Fetched ${data.length} businesses from DB');
      if (data.isNotEmpty) {
        print('First business raw: ${data.first}');
      }
      return data.map((json) => Business.fromJson(json)).toList();
    } catch (e, stack) {
      print('Error fetching nearby businesses: $e\n$stack');
      rethrow;
    }
  }

  /// Rate a business
  Future<void> rateBusiness(String businessId, bool isHonest) async {
    try {
      // await _client.rpc('rate_business', params: {'business_id': businessId, 'is_honest': isHonest});
      // Fallback: Client side update (requires simple update policy)
      // Assuming 'score' is what we update? Or honest_rating?
      // The current Business model has 'score'. Legacy had honest/dishonest.
      // Let's assume we update 'score' + 1 for now or nothing if not supported.
      print('Rating not yet fully implemented in backend.');
    } catch (e) {
      print('Error rating business: $e');
    }
  }

  /// Create a new business
  Future<void> createBusiness(Business business) async {
      await _client.from('businesses').insert({
        'id': business.id,
        'name': business.name,
        'description': business.description,
        // PostGIS format: POINT(lng lat)
        'location': 'POINT(${business.longitude} ${business.latitude})',
        'category': business.category,
      });
  }
}

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(Supabase.instance.client);
});
