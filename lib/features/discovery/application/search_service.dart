import '../../discovery/domain/taxonomy.dart';

class SearchFilters {
  final String? text;
  final String? category;
  final String? subcategory;
  final Vibe? vibe;
  final List<String> amenities;
  final bool isOpenNow;
  final double? minScore;

  const SearchFilters({
    this.text,
    this.category,
    this.subcategory,
    this.vibe,
    this.amenities = const [],
    this.isOpenNow = false,
    this.minScore,
  });

  bool get isEmpty => 
    text == null && 
    category == null && 
    subcategory == null && 
    vibe == null && 
    amenities.isEmpty && 
    !isOpenNow && 
    minScore == null;
}

class SearchService {
  
  static SearchFilters parse(String query) {
    if (query.trim().isEmpty) return const SearchFilters();

    String raw = query.toLowerCase();
    
    // 1. Detect Vibe
    Vibe? vibe;
    if (raw.contains('fiesta') || raw.contains('party') || raw.contains('baila')) vibe = Vibe.nightlife;
    if (raw.contains('comida') || raw.contains('hambre') || raw.contains('cenar')) vibe = Vibe.food;
    if (raw.contains('tranqui') || raw.contains('chill') || raw.contains('caf') || raw.contains('leer')) vibe = Vibe.social;
    if (raw.contains('gym') || raw.contains('correr') || raw.contains('ejercicio')) vibe = Vibe.active;
    if (raw.contains('taller') || raw.contains('repara') || raw.contains('banco') || raw.contains('lavanderia')) vibe = Vibe.services;

    // 2. Detect Amenities
    List<String> amenities = [];
    if (raw.contains('wifi') || raw.contains('internet')) amenities.add('wifi');
    if (raw.contains('card') || raw.contains('tarjeta')) amenities.add('card');
    if (raw.contains('fuera') || raw.contains('terraza') || raw.contains('patio')) amenities.add('outdoor_seating');
    
    // 3. Detect Categories (Simple Keywords)
    String? subcat;
    if (raw.contains('taco') || raw.contains('pastor')) subcat = 'tacos';
    if (raw.contains('pizza')) subcat = 'pizza';
    if (raw.contains('sushi') || raw.contains('japones')) subcat = 'sushi';
    if (raw.contains('burger') || raw.contains('hambur')) subcat = 'burger';
    if (raw.contains('mecanico') || raw.contains('auto') || raw.contains('taller')) subcat = 'repair';
    if (raw.contains('cafe') || raw.contains('starbucks')) subcat = 'cafe';

    // 4. Open Now
    bool open = raw.contains('abierto') || raw.contains('ahora') || raw.contains('open');

    return SearchFilters(
      text: query.trim(), // Main text for fuzzy name match
      vibe: vibe,
      subcategory: subcat,
      amenities: amenities,
      isOpenNow: open,
    );
  }
}
