import 'package:flutter/material.dart';

class ThemeModes {
  static final ThemeData lightMode = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFFfb6f92), // Soft pink for primary actions
      onPrimary: Colors.white,
      secondary: const Color(0xFFffb3c6), // Lighter pink for secondary actions
      onSecondary: Colors.black87,
      tertiary: const Color(0xFFffcad4), // Soft pink for highlights
      onTertiary: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
      surface: const Color(0xFFffe5ec), // Light pink surface
      onSurface: const Color(0xFFfb6f92),
      outline: Colors.grey[400]!,
      shadow: Colors.black12,
      surfaceContainerHighest: const Color(0xFFFCE4EC),
      onSurfaceVariant: Colors.black54,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFff8fab),
      foregroundColor: Colors.black87,
      elevation: 4,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFff8fab),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFff8fab), width: 2),
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFFFDE2E4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static final ThemeData darkMode = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.white, // White for primary actions
      onPrimary: Colors.black, // Black for contrast on primary
      secondary: Colors.white70, // Slightly dimmed white for secondary actions
      onSecondary: Colors.black87, // Dark gray for readability
      tertiary: Colors.black54, // Dark gray for highlights
      onTertiary: Colors.white, // White for contrast
      error: Colors.redAccent, // Kept for standard error visibility
      onError: Colors.white,
      surface: Colors.black87, // Dark surface for background
      onSurface: Colors.white, // White for text/icons on surface
      outline: Colors.grey[700]!,
      shadow: Colors.black38,
      surfaceContainerHighest: Colors.black54, // Slightly lighter for cards
      onSurfaceVariant: Colors.white70, // Dimmed white for secondary text
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // Pure black for app bar
      foregroundColor: Colors.white, // White for icons/text
      elevation: 4,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // White for buttons
        foregroundColor: Colors.black, // Black for button text/icons
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black54, // Dark gray for input fields
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.white,
          width: 2,
        ), // White for focus
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.black54, // Dark gray for cards
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
