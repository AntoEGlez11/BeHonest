import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111827), // gray-900 like
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6), // Blue 500
      secondary: Color(0xFF10B981), // Emerald 500
      surface: Color(0xFF1F2937), // gray-800
      // background is deprecated
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white, 
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    
    // Floating Action Button Theme (Waze style: chunky, rounded)
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    ),

    // Card/Sheet Theme
    cardTheme: CardThemeData(
      color: const Color(0xFF1F2937).withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
    ),


    // Input Decoration (Rounded, filled)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF374151), // gray-700
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      hintStyle: const TextStyle(color: Colors.white60),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
