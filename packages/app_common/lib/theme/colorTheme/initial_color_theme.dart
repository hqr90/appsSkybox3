import 'package:flutter/material.dart';

// Esquemas de cores iniciais para o aplicativo.
// Define as cores padrão para os temas claro e escuro.
class InitialColorTheme {
  // Esquema de Cores para o Tema Claro
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, // Cor base para gerar o esquema claro
    brightness: Brightness.light, // Define o tema como claro

    // Cores primárias (geralmente usadas para elementos principais da UI)
    primary: Colors.deepPurple,
    onPrimary: Colors.white, // Cor do texto/icones em cima da cor primária
    primaryContainer: Colors.deepPurple.shade100,
    onPrimaryContainer: Colors.deepPurple.shade900,

    // Cores secundárias (geralmente usadas para elementos flutuantes, botões de ação)
    secondary: Colors.teal,
    onSecondary: Colors.white,
    secondaryContainer: Colors.teal.shade100,
    onSecondaryContainer: Colors.teal.shade900,

    // Cores terciárias (usadas para acentos e destaques menos proeminentes)
    tertiary: Colors.orange,
    onTertiary: Colors.white,
    tertiaryContainer: Colors.orange.shade100,
    onTertiaryContainer: Colors.orange.shade900,

    // Cor de erro (usada para indicar erros)
    error: Colors.red.shade700,
    onError: Colors.white,
    errorContainer: Colors.red.shade100,
    onErrorContainer: Colors.red.shade900,

    // Cores de fundo
    background: Colors.grey.shade50, // Cor de fundo principal da maioria das telas
    onBackground: Colors.black87, // Cor do texto/icones em cima da cor de fundo

    // Cores de superfície (usadas para Cards, Sheets, Menus)
    surface: Colors.white,
    onSurface: Colors.black87,
    surfaceVariant: Colors.grey.shade200, // Variante da cor de superfície
    onSurfaceVariant: Colors.black54, // Cor do texto/icones em cima da variante de superfície

    // Cor do contorno (usada para bordas, divisores)
    outline: Colors.grey.shade400,
    outlineVariant: Colors.grey.shade300,

    // Outras cores
    shadow: Colors.black.withOpacity(0.2),
    scrim: Colors.black.withOpacity(0.5), // Usado para escurecer o fundo atrás de modais/drawers
    inverseSurface: Colors.grey.shade900, // Cor de superfície para elementos invertidos
    onInverseSurface: Colors.white, // Cor do texto/icones em cima da superfície invertida
    inversePrimary: Colors.lightBlue.shade300, // Cor primária para contextos invertidos
    surfaceTint: Colors.deepPurple.shade50, // Uma leve sobreposição de cor na superfície
  );

  // Esquema de Cores para o Tema Escuro
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, // Cor base para gerar o esquema escuro
    brightness: Brightness.dark, // Define o tema como escuro

    // Cores primárias
    primary: Colors.deepPurple.shade300, // Um tom mais claro de deepPurple para contraste no escuro
    onPrimary: Colors.black, // Texto escuro sobre a cor primária clara
    primaryContainer: Colors.deepPurple.shade700,
    onPrimaryContainer: Colors.deepPurple.shade100,

    // Cores secundárias
    secondary: Colors.teal.shade300,
    onSecondary: Colors.black,
    secondaryContainer: Colors.teal.shade700,
    onSecondaryContainer: Colors.teal.shade100,

    // Cores terciárias
    tertiary: Colors.orange.shade300,
    onTertiary: Colors.black,
    tertiaryContainer: Colors.orange.shade700,
    onTertiaryContainer: Colors.orange.shade100,

    // Cor de erro
    error: Colors.red.shade400,
    onError: Colors.black,
    errorContainer: Colors.red.shade800, // Um container de erro mais escuro
    onErrorContainer: Colors.red.shade100,

    // Cores de fundo
    background: Colors.grey.shade900, // Fundo bem escuro
    onBackground: Colors.white70, // Texto claro sobre o fundo escuro

    // Cores de superfície
    surface: Colors.grey.shade800, // Superfície escura, mas mais clara que o fundo
    onSurface: Colors.white70,
    surfaceVariant: Colors.grey.shade700, // Variante de superfície
    onSurfaceVariant: Colors.white60,

    // Cor do contorno
    outline: Colors.grey.shade600,
    outlineVariant: Colors.grey.shade700,

    // Outras cores
    shadow: Colors.black.withOpacity(0.4), // Sombra pode ser um pouco mais pronunciada
    scrim: Colors.black.withOpacity(0.6),
    inverseSurface: Colors.grey.shade100, // Superfície invertida clara
    onInverseSurface: Colors.black, // Texto escuro na superfície invertida
    inversePrimary: Colors.deepPurple.shade700, // Primária invertida mais escura
    surfaceTint: Colors.deepPurple.shade700, // Sobreposição de cor na superfície
  );

// Você também pode definir cores personalizadas específicas aqui, se necessário,
// e talvez queira versões diferentes para temas claros e escuros.
// static const Color customLightColor1 = Color(0xFFABCDEF);
// static const Color customDarkColor1 = Color(0xFF123456);
}
