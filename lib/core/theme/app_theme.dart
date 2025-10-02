// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // ALTERADO: Nova cor primária inspirada na imagem de referência
  static const Color primary = Color.fromARGB(255, 10, 23, 36); 
  static const Color secondary = Color(0xFF36D97D);
  static const Color background = Color(0xFFF8F9FA);
  // NOVO: Cor para o fundo do item selecionado no menu
  static const Color accentBlue = Color(0xFF334E68);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      background: background,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0, // AppBar sem sombra para um look mais clean
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Bordas um pouco menos arredondadas
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    
    // ALTERADO: Tema do NavigationRail atualizado
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: primary,
      indicatorColor: accentBlue, // Cor de fundo do item selecionado
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.7)),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    ),
  );
}