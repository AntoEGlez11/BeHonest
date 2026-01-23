
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/business.dart';
import '../../discovery/domain/taxonomy.dart';

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
      final businesses = (data as List<dynamic>).map((json) => Business.fromJson(json)).toList();
      
      // MOCK ENRICHMENT FOR DEMO (Since DB is empty/simple)
      return businesses.map((b) => _enrichWithMockData(b)).toList();
    } catch (e, stack) {
      print('Error fetching nearby businesses: $e\n$stack');
      rethrow;
    }
  }

  /// Rate a business (Legacy Binary)
  Future<void> rateBusiness(String businessId, bool isHonest) async {
    // Legacy support wrapper
    await rateBusinessMultiAxis(businessId, {
      'quality': isHonest ? 10 : 1,
      'service': isHonest ? 10 : 1,
      'price': isHonest ? 10 : 1,
      'cleanliness': isHonest ? 10 : 1,
      'wait_time': isHonest ? 10 : 1,
    });
  }

  /// Rate a business (Multi-Axis) -> Future v1.0
  Future<void> rateBusinessMultiAxis(String businessId, Map<String, int> scores, {String? userId, String? comment}) async {
    try {
      print('Submitting Multi-Axis Rating for $businessId from User ${userId ?? 'Anonymous'}: $scores');
      if (comment != null) print('Review Comment: "$comment"');
      
      // Calculate average for legacy score support
      final avg = scores.values.reduce((a, b) => a + b) / scores.length;
      
      // TODO: CALL REAL RPC when Backend is ready
      // await _client.rpc('submit_review', params: {
      //   'business_id': businessId,
      //   'scores_json': scores,
      //   'avg_score': avg
      // });

      // SIMULATION: Just update the single 'score' column for now to show visual feedback
      // We assume the DB has a 'score' column we can update directly or via RPC.
      // If not, we just log success.
      print('Simulated Backend: Updated score to ${avg.toStringAsFixed(1)}');
      
    } catch (e) {
      print('Error rating business: $e');
      throw e; // Rethrow to show error in UI
    }
  }

  /// Create a new business
  // Density Check
  Future<int> countNearby(double lat, double lng, double radiusKm) async {
    try {
      final res = await _client.rpc('get_businesses_in_radius', params: {
        'lat': lat,
        'long': lng,
        'radius_km': radiusKm,
      }).count(CountOption.exact); 
      return res.count; 
    } catch (e) {
      // Fallback
       final res = await _client.rpc('get_businesses_in_radius', params: {
        'lat': lat,
        'long': lng,
        'radius_km': radiusKm,
      }).select('id');
      return (res as List).length;
    }
  }

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

  Business _enrichWithMockData(Business b) {
    // Tacos El Dev (The Star)
    if (b.name.contains('Tacos El Dev') || b.category.contains('restaurante')) {
      return Business(
        id: b.id, name: b.name, category: b.category, latitude: b.latitude, longitude: b.longitude,
        score: b.score, description: b.description ?? 'Best tacos in code-town.', priceLevel: 2,
        address: 'Av. Tech Lead 123, Startup City',
        phone: '+52 81 1234 5678',
        website: 'https://instagram.com/tacos_el_dev',
        photos: [
          'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?q=80&w=600&auto=format&fit=crop', // Tacos
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?q=80&w=600&auto=format&fit=crop', // More tacos
        ],
        amenities: ['wifi', 'card', 'outdoor_seating'],
        openingHoursDisplay: 'Mon-Fri 18:00 - 02:00, Sat 14:00 - 04:00',
        vibe: Vibe.food,
      );
    }
    // Taller El Rayo
    if (b.name.contains('Rayo') || b.category.contains('taller')) {
      return Business(
        id: b.id, name: b.name, category: b.category, latitude: b.latitude, longitude: b.longitude,
        score: b.score, description: b.description ?? 'Quick fixes, fair prices.', priceLevel: 1,
        address: 'Calle Tuerca 45, Garage Zone',
        phone: '+52 81 8888 9999',
        amenities: ['cash_only', 'emergency_service'],
        openingHoursDisplay: 'Mon-Sat 08:00 - 18:00',
        vibe: Vibe.services,
      );
    }
    // Default enrichment
    return b;
  }
}

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(Supabase.instance.client);
});
