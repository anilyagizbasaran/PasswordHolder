import 'package:flutter/material.dart';

class AppTheme {
  // Extension'daki renkler
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkTextMuted = Color(0xFF888888);
  static const Color darkBorder = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.1)
  static const Color primaryBlue = Color(0xFF0061FE);
  static const Color primaryBlueDark = Color(0xFF0052D4);
  static const Color errorRed = Color(0xFFFF4444);

  // Açık tema renkleri
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF111111);
  static const Color lightTextMuted = Color(0xFF666666);
  static const Color lightBorder = Color(0x1A000000); // rgba(0, 0, 0, 0.1)

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryBlue,
        primaryContainer: primaryBlueDark,
        secondary: darkText,
        surface: darkCardBackground,
        background: darkBackground,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: darkText,
        onSurface: darkText,
        onBackground: darkText,
        onError: Colors.white,
        outline: darkBorder,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkText,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkText),
        displayMedium: TextStyle(color: darkText),
        displaySmall: TextStyle(color: darkText),
        headlineLarge: TextStyle(color: darkText),
        headlineMedium: TextStyle(color: darkText),
        headlineSmall: TextStyle(color: darkText),
        titleLarge: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText),
        bodySmall: TextStyle(color: darkTextMuted),
        labelLarge: TextStyle(color: darkText),
        labelMedium: TextStyle(color: darkText),
        labelSmall: TextStyle(color: darkTextMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCardBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
      ),
      dividerColor: darkBorder,
      iconTheme: const IconThemeData(color: darkText),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: primaryBlueDark,
        secondary: lightText,
        surface: lightCardBackground,
        background: lightBackground,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: lightText,
        onSurface: lightText,
        onBackground: lightText,
        onError: Colors.white,
        outline: lightBorder,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardTheme: CardThemeData(
        color: lightCardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightText,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightText),
        displayMedium: TextStyle(color: lightText),
        displaySmall: TextStyle(color: lightText),
        headlineLarge: TextStyle(color: lightText),
        headlineMedium: TextStyle(color: lightText),
        headlineSmall: TextStyle(color: lightText),
        titleLarge: TextStyle(color: lightText, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: lightText, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: lightText, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: lightText),
        bodyMedium: TextStyle(color: lightText),
        bodySmall: TextStyle(color: lightTextMuted),
        labelLarge: TextStyle(color: lightText),
        labelMedium: TextStyle(color: lightText),
        labelSmall: TextStyle(color: lightTextMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCardBackground,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
      ),
      dividerColor: lightBorder,
      iconTheme: const IconThemeData(color: lightText),
    );
  }
}

