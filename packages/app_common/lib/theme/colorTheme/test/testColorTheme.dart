import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../fontTheme/font_theme_provider.dart';
import '../../fontTheme/initial_font_theme.dart';
import '../color_theme_editor_page.dart';
import '../color_theme_provider.dart';
import '../initial_color_theme.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FontThemeProvider(initialTextTheme: FontTheme.textTheme)..initializeTheme(),
        ),
        ChangeNotifierProvider(
          create: (_) => ColorThemeProvider(
            initialLightColorScheme: InitialColorTheme.lightColorScheme, // Passa o esquema claro
            initialDarkColorScheme: InitialColorTheme.darkColorScheme,   // Passa o esquema escuro
          )..initializeTheme(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ouve as mudanças no FontThemeProvider e ColorThemeProvider
    final fontProvider = Provider.of<FontThemeProvider>(context);
    final colorProvider = Provider.of<ColorThemeProvider>(context);

    // Enquanto os temas estão carregando (estado inicial antes do SharedPreferences/Firebase)
    if (fontProvider.isInitialLoading || colorProvider.isInitialLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Determina o ThemeMode com base no ColorThemeProvider
    ThemeMode themeMode;
    if (colorProvider.currentBrightness == Brightness.light) {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.dark;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Theme Editor Demo',
      themeMode: themeMode, // Controla qual tema (light/dark) é usado
      theme: ThemeData( // Tema claro
        colorScheme: colorProvider.currentBrightness == Brightness.light
            ? colorProvider.colorScheme // Usa o colorScheme do provider (que será o light)
            : InitialColorTheme.lightColorScheme, // Fallback, mas o provider deve fornecer o correto
        textTheme: fontProvider.textTheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorProvider.currentBrightness == Brightness.light
              ? colorProvider.colorScheme.primary
              : InitialColorTheme.lightColorScheme.primary,
          foregroundColor: colorProvider.currentBrightness == Brightness.light
              ? colorProvider.colorScheme.onPrimary
              : InitialColorTheme.lightColorScheme.onPrimary,
        ),
        // Outras customizações do tema claro podem vir aqui
      ),
      darkTheme: ThemeData( // Tema escuro
        colorScheme: colorProvider.currentBrightness == Brightness.dark
            ? colorProvider.colorScheme // Usa o colorScheme do provider (que será o dark)
            : InitialColorTheme.darkColorScheme, // Fallback
        textTheme: fontProvider.textTheme, // Pode-se ter um textTheme específico para o tema escuro se necessário
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorProvider.currentBrightness == Brightness.dark
              ? colorProvider.colorScheme.primary
              : InitialColorTheme.darkColorScheme.primary,
          foregroundColor: colorProvider.currentBrightness == Brightness.dark
              ? colorProvider.colorScheme.onPrimary
              : InitialColorTheme.darkColorScheme.onPrimary,
        ),
        // Outras customizações do tema escuro podem vir aqui
      ),
      home: const ColorThemeEditorPage(),
    );
  }
}
