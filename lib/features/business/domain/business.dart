
import 'dart:typed_data';

class Business {
  final String id;
  final String name;
  final String category;
  final String? description;
  final double latitude;
  final double longitude;
  final double? score;

  Business({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.score,
    String? category,
  }) : category = category ?? description ?? 'Place';

  factory Business.fromJson(Map<String, dynamic> json) {
    // Handle PostGIS point if returned as GeoJSON or similar, 
    // but for now assuming we extract lat/lng from a location column or separate fields.
    // Ideally Supabase returns it as a compatible JSON or strictly lat/lng columns if we view it that way.
    // If 'location' is a string like 'POINT(-99.1 19.4)', we need to parse it.
    
    // For simplicity in MVP, let's assume we might select lat/lng directly or parse.
    // For simplicity in MVP, let's assume we might select lat/lng directly or parse.
    final loc = json['location'];
    print('Business.fromJson location raw: $loc'); // DEBUG INFO
    double lat = 0;
    double lng = 0;
    
    // Quick parse for standard PostGIS text representation if necessary
    // "POINT(-99.163 19.354)"
    if (loc is String) {
      if (loc.startsWith('POINT')) {
        // Remove 'POINT', '(', ')' and trim
        final clean = loc.replaceAll(RegExp(r'POINT|[()]'), '').trim();
        // Split by any whitespace
        final parts = clean.split(RegExp(r'\s+'));
        
          if (parts.length >= 2) {
          lng = double.tryParse(parts[0]) ?? 0;
          lat = double.tryParse(parts[1]) ?? 0;
          print('Business.fromJson parsed text: lat=$lat, lng=$lng'); // DEBUG
        }
      } else if (loc.length >= 50 && loc.startsWith('01')) {
         // Parsing WKB Hex String manually (Little Endian for this specific case)
         // Header: 01 (1 byte) + Type: 01000020 (4 bytes) + SRID: E6100000 (4 bytes) = 9 bytes = 18 hex chars
         // Coords: 8 bytes lng + 8 bytes lat = 16 hex + 16 hex
         try {
           final hexLng = loc.substring(18, 34);
           final hexLat = loc.substring(34, 50);
           
           // Convert hex to double (IEEE 754)
           // In Dart, we can use a typed data buffer
           double hexToDouble(String hex) {
             // Hex string must be little-endian based on '01'
             // But strings like AF85... usually are printed byte-by-byte. 
             // We need to decode byte by byte.
             List<int> bytes = [];
             for (int i = 0; i < hex.length; i += 2) {
               bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
             }
             // Convert to ByteData
             final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
             return byteData.getFloat64(0, Endian.little);
           }
           
           lng = hexToDouble(hexLng);
           lat = hexToDouble(hexLat);
           print('Business.fromJson parsed HEX: lat=$lat, lng=$lng'); 
         } catch (e) {
           print('Error parsing WKB Hex: $e');
         }
      }
    }

    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: lat,
      longitude: lng,
      score: (json['score'] as num?)?.toDouble(),
      category: json['category'] as String?, // Can be null, will fallback to description
    );
  }
}
