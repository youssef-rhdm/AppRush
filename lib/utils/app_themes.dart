import 'package:flutter/material.dart';

class AppThemes {
  static const Color accentGreen = Color(0xff305945);
  static const Color cardGrey = Color.fromARGB(255, 14, 13, 12);
  static const Color lightCardGrey = Color(0xFFF5F5F5);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentGreen, // Add this line
      primarySwatch: MaterialColor(0xFF39A60A, {
        50: accentGreen.withOpacity(0.1),
        100: accentGreen.withOpacity(0.2),
        200: accentGreen.withOpacity(0.3),
        300: accentGreen.withOpacity(0.4),
        400: accentGreen.withOpacity(0.5),
        500: accentGreen,
        600: accentGreen.withOpacity(0.8),
        700: accentGreen.withOpacity(0.7),
        800: accentGreen.withOpacity(0.6),
        900: accentGreen.withOpacity(0.5),
      }),
      scaffoldBackgroundColor: Colors.black,
      dividerColor: Colors.white24,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardGrey,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: accentGreen,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white), // Section titles
        titleLarge: TextStyle(color: Colors.white), // Dialog titles
        titleMedium: TextStyle(color: Colors.white), // List tile titles
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white), // Dialog content
        bodySmall: TextStyle(color: Colors.white), // List tile subtitles
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
      ), // Add this for general icons
      colorScheme: ColorScheme.dark(
        primary: accentGreen,
        secondary: accentGreen,
        surface: cardGrey,
        background: Colors.white,
        onSurface: Colors.white, // Text on surfaces
        onBackground: Colors.white, // Text on background
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentGreen, // Add this line
      primarySwatch: MaterialColor(0xFF39A60A, {
        50: accentGreen.withOpacity(0.1),
        100: accentGreen.withOpacity(0.2),
        200: accentGreen.withOpacity(0.3),
        300: accentGreen.withOpacity(0.4),
        400: accentGreen.withOpacity(0.5),
        500: accentGreen,
        600: accentGreen.withOpacity(0.8),
        700: accentGreen.withOpacity(0.7),
        800: accentGreen.withOpacity(0.6),
        900: accentGreen.withOpacity(0.5),
      }),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: Colors.black12, // Add this for dividers
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: lightCardGrey,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accentGreen,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Colors.black87),
        displayMedium: TextStyle(color: Colors.black87),
        displaySmall: TextStyle(color: Colors.black87),
        headlineLarge: TextStyle(color: Colors.black87),
        headlineMedium: TextStyle(color: Colors.black87),
        headlineSmall: TextStyle(color: Colors.black87), // Section titles
        titleLarge: TextStyle(color: Colors.black87), // Dialog titles
        titleMedium: TextStyle(color: Colors.black87), // List tile titles
        titleSmall: TextStyle(color: Colors.black87),
        bodyLarge: TextStyle(color: Colors.black54),
        bodyMedium: TextStyle(color: Colors.black54), // Dialog content
        bodySmall: TextStyle(color: Colors.black45), // List tile subtitles
      ),
      iconTheme: IconThemeData(
        color: Colors.black87,
      ), // Add this for general icons
      colorScheme: ColorScheme.light(
        primary: accentGreen,
        secondary: accentGreen,
        surface: lightCardGrey,
        background: Colors.white,
        onSurface: Colors.black87, // Text on surfaces
        onBackground: Colors.black87, // Text on background
      ),
    );
  }
}
