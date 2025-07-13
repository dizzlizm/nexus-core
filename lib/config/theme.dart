import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    primaryColor: const Color(0xFF58A6FF),
    textTheme: GoogleFonts.robotoMonoTextTheme(
      ThemeData.dark().textTheme.copyWith(
        bodyMedium: const TextStyle(color: Color(0xFFC9D1D9)),
        headlineSmall: const TextStyle(color: Color(0xFFF0F6FC), fontWeight: FontWeight.bold, fontSize: 16),
        titleLarge: const TextStyle(color: Color(0xFFF0F6FC), fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF58A6FF),
      secondary: Color(0xFF388BFD),
      surface: Color(0xFF161B22),
    ),
  );

  static const gridColor = Color(0x338B949E);
  static const synapseColor = Color(0x998B949E);

  // --- Node Colors ---
  static const powerTapColor = Color(0xFF58A6FF);
  static const powerTapGlow = Color(0x9958A6FF);

  static const multiplierColor = Color(0xFFF87171); // Red
  static const multiplierGlow = Color(0x99F87171);

  static const overclockerColor = Color(0xFFFBBF24); // Yellow
  static const overclockerGlow = Color(0x99FBBF24);

  static const reducerColor = Color(0xFF4ADE80); // Green
  static const reducerGlow = Color(0x994ADE80);

  static const efficiencyColor = Color(0xFFa855f7); // Purple
  static const efficiencyGlow = Color(0x99a855f7);

  static const cacheMultiplierColor = Color(0xFFf97316); // Orange
  static const cacheMultiplierGlow = Color(0x99f97316);
}
