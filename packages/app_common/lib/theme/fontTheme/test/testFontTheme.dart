import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../colorTheme/color_theme_provider.dart';
import '../../colorTheme/initial_color_theme.dart';
import '../../fontTheme/font_theme_provider.dart';
import '../../fontTheme/initial_font_theme.dart';
import '../theme_editor_page.dart';


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
      child: const MyApp(), // Seu widget App principal
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontProvider = Provider.of<FontThemeProvider>(context);
    final colorProvider = Provider.of<ColorThemeProvider>(context);

    // Enquanto os temas estão carregando, você pode mostrar um loader
    if (fontProvider.isInitialLoading || colorProvider.isInitialLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Flutter Theme Editor Demo',
      theme: ThemeData(
        colorScheme: colorProvider.colorScheme, // Usa o ColorScheme do provider
        textTheme: fontProvider.textTheme,       // Usa o TextTheme do provider
        useMaterial3: true,
        // Você pode querer definir outras propriedades do tema aqui
        // que podem depender das cores ou fontes.
        appBarTheme: AppBarTheme(
          backgroundColor: colorProvider.colorScheme.primary,
          foregroundColor: colorProvider.colorScheme.onPrimary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorProvider.colorScheme.secondary,
          foregroundColor: colorProvider.colorScheme.onSecondary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorProvider.colorScheme.primary,
            foregroundColor: colorProvider.colorScheme.onPrimary,
          ),
        ),
      ),
      home: const ThemeEditorPage(), // Ou sua página inicial
      // Adicione a rota para a página do editor de fontes se ainda não tiver
      // routes: {
      //   '/fontEditor': (context) => const ThemeEditorPage(),
      //   '/colorEditor': (context) => const ColorThemeEditorPage(),
      // },
    );
  }
}