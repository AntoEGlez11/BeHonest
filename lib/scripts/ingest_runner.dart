import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../features/discovery/domain/taxonomy.dart';

// HARDCODED PATH TO DATA
const String kDataPath = r'C:\Users\aneg\.gemini\antigravity\scratch\be-honest-osm\output\Mexico\Ciudad_de_Mexico';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  runApp(const IngestionApp());
}

class IngestionApp extends StatelessWidget {
  const IngestionApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: IngestionScreen());
}

class IngestionScreen extends StatefulWidget {
  const IngestionScreen({super.key});
  @override
  State<IngestionScreen> createState() => _IngestionScreenState();
}

class _IngestionScreenState extends State<IngestionScreen> {
  final supabase = Supabase.instance.client;
  List<String> _log = [];
  double _progress = 0.0;
  bool _isIngesting = false;

  @override
  void initState() {
    super.initState();
    _startIngestion();
  }

  void _logMsg(String msg) {
    setState(() {
      _log.add(msg);
      // Keep log short for verify performance
      if (_log.length > 50) _log.removeAt(0); 
    });
    print(msg);
  }

  Future<void> _startIngestion() async {
    setState(() => _isIngesting = true);
    _logMsg("🚀 Starting Data Ingestion...");

    try {
      // 0. PRE-FLIGHT MIGRATION
      // _logMsg("🛠️ Running DB Migration...");
      // await _runMigration(); // Cannot run DDL with anon key
      
      final directory = Directory(kDataPath);
      if (!await directory.exists()) {
        _logMsg("❌ Error: Directory not found at $kDataPath");
        return;
      }

      final files = directory.listSync()
          .where((e) => e.path.endsWith('.json') && e.path.contains('businesses_'))
          .toList();

      _logMsg("📂 Found ${files.length} JSON files.");

      int totalRecords = 0;
      int processedFiles = 0;

      for (var entity in files) {
        if (entity is File) {
          _logMsg("📄 Processing ${entity.uri.pathSegments.last}...");
          await _processFile(entity);
          processedFiles++;
          setState(() {
            _progress = processedFiles / files.length;
          });
        }
      }

      _logMsg("✅ Ingestion Complete! Processed $processedFiles files.");
    } catch (e) {
      _logMsg("❌ CRITICAL ERROR: $e");
    } finally {
      setState(() => _isIngesting = false);
    }
  }

  Future<void> _processFile(File file) async {
    try {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      
      _logMsg("   ↳ Found ${data.length} records. Uploading...");

      // Batch insert 100 at a time
      final batchSize = 100;
      for (var i = 0; i < data.length; i += batchSize) {
        final end = (i + batchSize < data.length) ? i + batchSize : data.length;
        final batch = data.sublist(i, end).map((item) => _mapToSchema(item)).toList();
        
        try {
          await supabase.from('businesses').insert(batch);
        } catch (e) {
          _logMsg("   ⚠️ Batch fail: $e");
        }
        await Future.delayed(const Duration(milliseconds: 50)); // Rate limit safety
      }
    } catch (e) {
      _logMsg("   ⚠️ Error reading file: $e");
    }
  }

  Map<String, dynamic> _mapToSchema(dynamic item) {
    // raw metadata
    final meta = item['metadata'] ?? {};
    
    // Parse booleans
    // Common tags: "yes", "only", "no"
    bool parseBool(String? val) => val == 'yes' || val == 'only';

    final cat = item['type'] == 'shop' ? 'retail' : (item['type'] ?? 'service');
    final sub = item['subtype'] ?? meta['cuisine'];
    final name = item['name'] ?? '';

    // Calculate Vibe
    final vibe = Vibe.fromRawData(cat, sub, name);

    return {
      'name': name,
      'latitude': item['latitude'],
      'longitude': item['longitude'],
      'category': cat,
      'subcategory': sub,
      'vibe': vibe.name, // Save as text
      
      // New Columns
      'brand': meta['brand'],
      'opening_hours': meta['opening_hours'],
      'phone': meta['phone'],
      'website': meta['website'] ?? item['website'],
      
      // Booleans
      'wifi': meta['internet_access'] == 'wlan' || meta['wifi'] == 'yes',
      'takeaway': parseBool(meta['takeaway']),
      'outdoor_seating': parseBool(meta['outdoor_seating']),
      'wheelchair_accessible': parseBool(meta['wheelchair']),
      
      // Fallback description
      'description': meta['description'] ?? (meta['cuisine'] != null ? "Cuisine: ${meta['cuisine']}" : null),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Text("Ingesting CDMX Data 🇲🇽", style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress, color: Colors.green),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (c, i) => Text(_log[i], style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
