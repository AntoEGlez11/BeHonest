import 'package:flutter/material.dart';

enum Vibe {
  social,
  food,
  nightlife,
  shopping,
  active,
  services,
  unknown;

  String get label {
    switch (this) {
      case Vibe.social: return 'Social & Chill';
      case Vibe.food: return 'Food & Dining';
      case Vibe.nightlife: return 'Nightlife';
      case Vibe.shopping: return 'Shopping';
      case Vibe.active: return 'Active & Wellness';
      case Vibe.services: return 'Services';
      case Vibe.unknown: return 'Place';
    }
  }

  Color get color {
    switch (this) {
      case Vibe.social: return Colors.amber; // Coffee, Ice cream
      case Vibe.food: return const Color(0xFFFF6B6B); // Coral Red
      case Vibe.nightlife: return const Color(0xFF7B2CBF); // Deep Purple
      case Vibe.shopping: return Colors.blueAccent;
      case Vibe.active: return Colors.green;
      case Vibe.services: return Colors.blueGrey;
      case Vibe.unknown: return Colors.grey;
    }
  }

  static Vibe fromRawData(String category, String? subcategory, String name) {
    final cat = category.toLowerCase();
    final sub = subcategory?.toLowerCase() ?? '';
    final n = name.toLowerCase();

    // 1. Nightlife
    if (sub.contains('bar') || sub.contains('pub') || sub.contains('club') || sub.contains('night')) return Vibe.nightlife;
    if (n.contains('bar ') || n.contains('cerveza') || n.contains('cantina')) return Vibe.nightlife;

    // 2. Social (Coffee & Sweets)
    if (sub.contains('cafe') || sub.contains('coffee') || sub.contains('tea')) return Vibe.social;
    if (sub.contains('ice_cream') || sub.contains('dessert')) return Vibe.social;

    // 3. Food
    if (cat == 'restaurant' || sub.contains('restaurant') || sub.contains('food')) return Vibe.food;
    if (sub.contains('taco') || sub.contains('pizza') || sub.contains('burger') || sub.contains('sushi')) return Vibe.food;
    if (n.contains('taso') || n.contains('comida') || n.contains('restaurante')) return Vibe.food;

    // 4. Active
    if (sub.contains('park') || sub.contains('gym') || sub.contains('fitness') || sub.contains('sport')) return Vibe.active;
    if (sub.contains('yoga') || sub.contains('pilates')) return Vibe.active;

    // 5. Shopping
    if (cat == 'shop' || cat == 'retail') return Vibe.shopping;
    if (sub.contains('mall') || sub.contains('store') || sub.contains('market')) return Vibe.shopping;

    // 6. Unknown / Service fallback
    return Vibe.services;
  }
}
