import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/core/constants.dart'; // Relative path from test/ to lib/
import '../lib/features/discovery/domain/taxonomy.dart';

// HARDCODED PATH
const String kDataPath = r'C:\Users\aneg\.gemini\antigravity\scratch\be-honest-osm\output\Mexico\Ciudad_de_Mexico';

void main() {
  test('Ingest CDMX Data', () async {
    // 1. Initialize Supabase Client directly (Avoids SharedPrefs/Flutter Plugins)
    final supabase = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
    );
    
    print("🚀 Starting Data Ingestion via Pure Dart Client...");

    final directory = Directory(kDataPath);
    if (!directory.existsSync()) {
      print("❌ Error: Directory not found at $kDataPath");
      return;
    }

    final files = directory.listSync()
        .where((e) => e.path.endsWith('.json') && e.path.contains('businesses_'))
        .toList();

    print("📂 Found ${files.length} JSON files.");

    int totalUploaded = 0;

    for (var entity in files) {
      if (entity is File) {
        print("📄 Processing ${entity.uri.pathSegments.last}...");
        
        try {
          final content = await entity.readAsString();
          final List<dynamic> data = jsonDecode(content);
          print("   ↳ Found ${data.length} records. Uploading...");

          // Batch insert
          final batchSize = 50; // Smaller batch for test stability
          for (var i = 0; i < data.length; i += batchSize) {
            final end = (i + batchSize < data.length) ? i + batchSize : data.length;
            final batch = data.sublist(i, end).map((item) => _mapToSchema(item)).toList();
            
            try {
              // We need to suppress the 'id' if we want Postgres to generate it, 
              // UNLESS we want to use OSM ID. 
              // 'prep_ingestion.sql' has 'id UUID DEFAULT gen_random_uuid()'.
              // We are NOT sending 'id' in the map, so it's fine.
              await supabase.from('businesses').insert(batch);
              totalUploaded += batch.length;
            } catch (e) {
              print("   ⚠️ Batch fail: $e");
            }
            // No sleep needed in test, but good for rate limits
            await Future.delayed(const Duration(milliseconds: 20));
          }
        } catch (e) {
          print("   ⚠️ Error reading file: $e");
        }
      }
    }

    print("✅ Ingestion Complete! Total uploaded: $totalUploaded");
  }, timeout: const Timeout(Duration(minutes: 30))); // Long timeout
}

Map<String, dynamic> _mapToSchema(dynamic item) {
  final meta = item['metadata'] ?? {};
  bool parseBool(String? val) => val == 'yes' || val == 'only';

  final cat = item['type'] == 'shop' ? 'retail' : (item['type'] ?? 'service');
  final sub = item['subtype'] ?? meta['cuisine'];
  final name = item['name'] ?? '';

  // Calculate Vibe logic (Copied from ingest_runner)
  final vibe = Vibe.fromRawData(cat, sub, name);

  return {
    'name': name,
    'latitude': item['latitude'],
    'longitude': item['longitude'],
    'category': cat,
    'subcategory': sub,
    'vibe': vibe.name,
    'brand': meta['brand'],
    'opening_hours': meta['opening_hours'],
    'phone': meta['phone'],
    'website': meta['website'] ?? item['website'],
    'wifi': meta['internet_access'] == 'wlan' || meta['wifi'] == 'yes',
    'takeaway': parseBool(meta['takeaway']),
    'outdoor_seating': parseBool(meta['outdoor_seating']),
    'wheelchair_accessible': parseBool(meta['wheelchair']),
    'description': meta['description'] ?? (meta['cuisine'] != null ? "Cuisine: ${meta['cuisine']}" : null),
  };
}
