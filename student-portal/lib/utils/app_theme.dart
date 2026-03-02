import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // 🎨 PALETTE
  // ---------------------------------------------------------------------------

  // Primary Brand Colors
  static const Color _primaryLight = Color(0xFF1E3C72); // Deep Navy
  static const Color _primaryDark = Color(
    0xFF64B5F6,
  ); // Soft Blue (better for dark mode)
  static const Color _secondaryLight = Color(0xFF2A5298);

  // Backgrounds
  static const Color _bgLight = Color(0xFFF8FAFC); // Cool Slate 50
  static const Color _bgDark = Color(0xFF121212); // Material Dark

  // Cards/Surfaces
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF1E1E1E); // Elevated Dark Surface

  // Text
  static const Color _textLight = Color(0xFF1E293B); // Slate 800
  static const Color _textGreyLight = Color(0xFF64748B); // Slate 500

  static const Color _textDark = Color(0xFFE2E8F0); // Slate 200
  static const Color _textGreyDark = Color(0xFF94A3B8); // Slate 400

  // ---------------------------------------------------------------------------
  // ☀️ LIGHT THEME
  // ---------------------------------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryLight,
    scaffoldBackgroundColor: _bgLight,
    cardColor: _cardLight,
    dividerColor: Colors.grey.shade200,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: _primaryLight,
      secondary: _secondaryLight,
      surface: _cardLight,
      error: Color(0xFFDC2626), // Red 600
      onPrimary: Colors.white,
      onSurface: _textLight,
    ),

    // App Bar
    appBarTheme: const AppBarTheme(
      backgroundColor: _cardLight,
      foregroundColor: _textLight,
      elevation: 0,
      scrolledUnderElevation: 2,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: _textLight),
    ),

    // Bottom Nav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _cardLight,
      selectedItemColor: _primaryLight,
      unselectedItemColor: _textGreyLight,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),

    // Text
    textTheme: const TextTheme(
      headlineSmall: TextStyle(color: _textLight, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(color: _textLight, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: _textLight), // Default Text
      bodySmall: TextStyle(color: _textGreyLight), // Subtitles/Grey text
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: _textGreyLight),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryLight, width: 2),
      ),
      hintStyle: const TextStyle(color: _textGreyLight),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryLight,
        side: const BorderSide(color: _primaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // 🌙 DARK THEME
  // ---------------------------------------------------------------------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryDark,
    scaffoldBackgroundColor: _bgDark,
    cardColor: _cardDark,
    dividerColor: Colors.grey.shade800,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: _primaryDark,
      secondary: Color(0xFF64B5F6),
      surface: _cardDark,
      error: Color(0xFFCF6679),
      onPrimary: _bgDark, // Black text on blue buttons for contrast
      onSurface: _textDark,
    ),

    // App Bar
    appBarTheme: const AppBarTheme(
      backgroundColor: _bgDark, // Blend appbar with bg
      foregroundColor: _textDark,
      elevation: 0,
      scrolledUnderElevation: 4,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: _textDark),
    ),

    // Bottom Nav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _cardDark,
      selectedItemColor: _primaryDark,
      unselectedItemColor: _textGreyDark,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),

    // Text
    textTheme: const TextTheme(
      headlineSmall: TextStyle(color: _textDark, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: _textDark),
      bodySmall: TextStyle(color: _textGreyDark),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: _textGreyDark),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C), // Slightly lighter than card
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // No borders looks cleaner in dark mode
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryDark, width: 1),
      ),
      hintStyle: const TextStyle(color: _textGreyDark),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryDark,
        foregroundColor: _bgDark, // Black text on light blue button
        elevation: 0, // Flat looks better in dark mode
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryDark,
        side: const BorderSide(color: _primaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
  );
}
