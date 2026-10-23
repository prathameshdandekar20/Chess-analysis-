import 'package:flutter/material.dart';

class ChessTheme {
  static const Color background = Color(0xFF1E1712);
  static const Color surface = Color(0xFF261E18);
  static const Color surfaceCard = Color(0xFF2E241D);
  static const Color surfaceElevated = Color(0xFF382D25);

  // Chess.com Brand Green
  static const Color brandGreen = Color(0xFF81B64C);
  static const Color brandGreenDark = Color(0xFF588235);
  static const Color brandGreenLight = Color(0xFFA3D160);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9D9B);
  static const Color textMuted = Color(0xFF6B6A67);

  // Board Themes (Exact Chess.com Wood Board)
  static const Color boardLightSquare = Color(0xFFD8B382);
  static const Color boardDarkSquare = Color(0xFF8A5A36);

  static const Color woodLightSquare = Color(0xFFD8B382);
  static const Color woodDarkSquare = Color(0xFF8A5A36);

  // Highlight & Marker Colors
  static const Color lastMoveHighlight = Color(0x70F7EC59);
  static const Color selectedSquareHighlight = Color(0x90BACA44);
  static const Color checkHighlight = Color(0x99FF3B30);
  static const Color legalMoveDot = Color(0x35000000);
  static const Color legalCaptureRing = Color(0x50000000);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: brandGreen,
      cardColor: surfaceCard,
      colorScheme: const ColorScheme.dark(
        primary: brandGreen,
        secondary: brandGreenLight,
        surface: surface,
        surfaceContainerHighest: surfaceElevated,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: brandGreen,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
