// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Cores da Paleta
  static const Color primary = Color(0xFF003366); // Azul Escuro Profundo
  static const Color secondary = Color(0xFF36D97D); // Verde Água Vibrante
  static const Color background = Color(0xFFF8F9FA); // Cinza Claro (Fundo)
  static const Color accentBlue = Color(0xFF334E68); // Azul Acinzentado (Item Selecionado)

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto', // Garante que a fonte Roboto seja usada em todo o app
    scaffoldBackgroundColor: background,
    
    // Esquema de Cores
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      background: background,
      brightness: Brightness.light,
    ),

    // Tema da AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: background, // Deixa a AppBar da mesma cor do fundo da tela (clean)
      foregroundColor: primary, // Ícones e Texto em Azul Escuro
      elevation: 0,
      iconTheme: IconThemeData(color: primary),
    ),

    // Tema dos Cards
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Tema dos Botões (FilledButton)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: secondary, // Botões Verdes
        foregroundColor: Colors.white, // Texto Branco
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    
    // Tema do NavigationRail (Menu Lateral)
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: primary, // Fundo Azul Escuro
      
      // Indicador de seleção (bolinha atrás do ícone)
      indicatorColor: accentBlue, 
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      
      // Ícones
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.7)),
      
      // Textos
      selectedLabelTextStyle: const TextStyle(
        color: Colors.white, 
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto'
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontFamily: 'Roboto'
      ),
    ),
  );
}