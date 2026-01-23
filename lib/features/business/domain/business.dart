import 'dart:typed_data';

import '../../discovery/domain/taxonomy.dart';

class Business {
  final String id;
  final String name;
  final String category;
  final String? description;
  final double latitude;
  final double longitude;
  final double? score;
  final String? subcategory;
  final String? brand;
  final String? openingHoursDisplay;
  final int? priceLevel;
  final Vibe vibe;
  
  // Rich Data
  final String? address;
  final String? phone;
  final String? website; // Changed from instagram to generic website
  final List<String> photos;
  final List<String> amenities; // Assembled from booleans

  Business({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.score,
    String? category,
    this.priceLevel,
    this.subcategory,
    this.brand,
    this.openingHoursDisplay,
    this.address,
    this.phone,
    this.website,
    this.photos = const [],
    this.amenities = const [],
    this.vibe = Vibe.unknown,
  }) : category = category ?? description ?? 'Place';

  factory Business.fromJson(Map<String, dynamic> json) {
    
    // Parsing Location (GeoJSON or WKB Hex)
    final loc = json['location'];
    double lat = 0;
    double lng = 0;
    
    if (loc is String) {
      if (loc.startsWith('POINT')) {
        try {
          final clean = loc.replaceAll(RegExp(r'POINT|[()]'), '').trim();
          final parts = clean.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            lng = double.tryParse(parts[0]) ?? 0;
            lat = double.tryParse(parts[1]) ?? 0;
          }
        } catch (e) {
          print('Error parsing POINT: $e');
        }
      }
      // WKB parsing omitted for brevity in this step, relying on PostGIS text output usually
    }
    
    // Assemble amenities from columns
    List<String> computedAmenities = [];
    if (json['wifi'] == true) computedAmenities.add('wifi');
    if (json['takeaway'] == true) computedAmenities.add('takeaway');
    if (json['outdoor_seating'] == true) computedAmenities.add('outdoor_seating');
    if (json['wheelchair_accessible'] == true) computedAmenities.add('wheelchair_accessible');
    
    // Combine with legacy array if present
    if (json['amenities'] != null) {
       computedAmenities.addAll((json['amenities'] as List).map((e) => e.toString()));
    }

    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      latitude: lat != 0 ? lat : (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: lng != 0 ? lng : (json['longitude'] as num?)?.toDouble() ?? 0,
      score: (json['average_score'] != null) ? (json['average_score'] as num).toDouble() : (json['score'] as num?)?.toDouble(),
      priceLevel: json['price_level'] as int?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHoursDisplay: json['opening_hours'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
      amenities: computedAmenities.toSet().toList(), // Remove duplicates
      vibe: json['vibe'] != null 
        ? Vibe.values.firstWhere((e) => e.name == json['vibe'], orElse: () => Vibe.unknown)
        : Vibe.fromRawData(json['category'] ?? '', json['subcategory'], json['name'] ?? ''),
    );
  }
}
