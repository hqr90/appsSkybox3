import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';
import 'initial_font_theme.dart';

class FontThemeProvider with ChangeNotifier {
  late Map<String, TextStyle> _styles;
  final TextTheme _initialTextTheme;

  bool _isLoading = true;
  bool _isInitialLoading = true; // Para o carregamento inicial antes do Firebase

  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading; // Expor o estado de carregamento inicial


  static const String _prefsKey = 'app_text_theme_styles';
  static const String _remoteConfigKey = 'text_theme_config'; // Chave no Firebase Remote Config

  static const List<String> styleKeys = [
    'displayLarge', 'displayMedium', 'displaySmall',
    'headlineLarge', 'headlineMedium', 'headlineSmall',
    'titleLarge', 'titleMedium', 'titleSmall',
    'bodyLarge', 'bodyMedium', 'bodySmall',
    'labelLarge', 'labelMedium', 'labelSmall',
    'overline'
  ];

  FontThemeProvider({required TextTheme initialTextTheme})
      : _initialTextTheme = initialTextTheme {
    // Define o tema inicial como padrão enquanto carrega de outras fontes
    _styles = _extractStylesFromTextTheme(_initialTextTheme);
  }

  // Método de inicialização a ser chamado após a criação do provider
  Future<void> initializeTheme() async {
    _isLoading = true;
    _isInitialLoading = true;
    notifyListeners();

    // 1. Carregar do SharedPreferences
    Map<String, TextStyle>? prefsStyles = await _loadStylesFromPrefs();
    if (prefsStyles != null) {
      _styles = prefsStyles;
    } else {
      // Se não estiver nas prefs, usa o tema inicial (já definido no construtor)
      _styles = _extractStylesFromTextTheme(_initialTextTheme);
    }
    _isInitialLoading = false; // Carregamento inicial (prefs/default) concluído
    notifyListeners();

    // 2. Configurar e buscar do Firebase Remote Config
    try {
      await _setupRemoteConfig();
      await _fetchAndApplyFirebaseConfig();
    } catch (e) {
      debugPrint('Erro ao inicializar ou buscar Firebase Remote Config: $e');
      // Continua com o tema carregado (prefs ou inicial)
    }

    _isLoading = false;
    notifyListeners();
  }


  TextTheme get textTheme {
    return TextTheme(
      displayLarge: _styles['displayLarge'],
      displayMedium: _styles['displayMedium'],
      displaySmall: _styles['displaySmall'],
      headlineLarge: _styles['headlineLarge'],
      headlineMedium: _styles['headlineMedium'],
      headlineSmall: _styles['headlineSmall'],
      titleLarge: _styles['titleLarge'],
      titleMedium: _styles['titleMedium'],
      titleSmall: _styles['titleSmall'],
      bodyLarge: _styles['bodyLarge'],
      bodyMedium: _styles['bodyMedium'],
      bodySmall: _styles['bodySmall'],
      labelLarge: _styles['labelLarge'],
      labelMedium: _styles['labelMedium'],
      labelSmall: _styles['labelSmall'],
    );
  }

  Map<String, TextStyle> _extractStylesFromTextTheme(TextTheme theme) {
    // Garante que todos os estilos tenham um valor padrão se não estiverem no tema inicial
    return {
      'displayLarge': theme.displayLarge ?? GoogleFonts.poppins(fontSize: 96, fontWeight: FontWeight.w300),
      'displayMedium': theme.displayMedium ?? GoogleFonts.poppins(fontSize: 60, fontWeight: FontWeight.w300),
      'displaySmall': theme.displaySmall ?? GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w400),
      'headlineLarge': theme.headlineLarge ?? GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w400),
      'headlineMedium': theme.headlineMedium ?? GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w400),
      'headlineSmall': theme.headlineSmall ?? GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w400),
      'titleLarge': theme.titleLarge ?? GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
      'titleMedium': theme.titleMedium ?? GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
      'titleSmall': theme.titleSmall ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      'bodyLarge': theme.bodyLarge ?? GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
      'bodyMedium': theme.bodyMedium ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
      'bodySmall': theme.bodySmall ?? GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
      'labelLarge': theme.labelLarge ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      'labelMedium': theme.labelMedium ?? GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      'labelSmall': theme.labelSmall ?? GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
    };
  }

  TextStyle? getStyle(String styleKey) => _styles[styleKey];

  // --- Métodos de SharedPreferences ---
  Future<void> _saveStylesToPrefs(Map<String, TextStyle> stylesToSave) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> serializedStyles = stylesToSave.map(
          (key, style) => MapEntry(key, jsonEncode(_textStyleToJson(style))),
    );
    await prefs.setString(_prefsKey, jsonEncode(serializedStyles));
    debugPrint('Tema salvo no SharedPreferences.');
  }

  Future<Map<String, TextStyle>?> _loadStylesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? serializedStylesString = prefs.getString(_prefsKey);
      if (serializedStylesString == null) return null;

      final Map<String, dynamic> decodedMap = jsonDecode(serializedStylesString);
      final Map<String, TextStyle> loadedStyles = decodedMap.map(
            (key, value) => MapEntry(key, _textStyleFromJson(jsonDecode(value as String))),
      );
      debugPrint('Tema carregado do SharedPreferences.');
      return loadedStyles;
    } catch (e) {
      debugPrint('Erro ao carregar tema do SharedPreferences: $e');
      return null;
    }
  }

  // --- Métodos do Firebase Remote Config ---
  Future<void> _setupRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1), // Define a frequência de busca
    ));

    // Define valores padrão (pode ser o tema inicial serializado)
    // Isso é útil se o backend estiver inacessível ou os parâmetros não estiverem definidos
    final Map<String, dynamic> defaultRemoteConfigValues = {
      _remoteConfigKey: jsonEncode(
          _extractStylesFromTextTheme(_initialTextTheme).map(
                  (key, value) => MapEntry(key, _textStyleToJson(value))
          )
      )
    };
    await remoteConfig.setDefaults(defaultRemoteConfigValues);
    debugPrint('Firebase Remote Config configurado com padrões.');
  }

  Future<void> _fetchAndApplyFirebaseConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.fetchAndActivate();
      final String? configString = remoteConfig.getString(_remoteConfigKey);

      if (configString != null && configString.isNotEmpty) {
        final Map<String, dynamic> decodedJson = jsonDecode(configString);
        final Map<String, TextStyle> firebaseStyles = decodedJson.map(
              (key, value) => MapEntry(key, _textStyleFromJson(value as Map<String, dynamic>)),
        );

        // Verifica se houve mudança real para evitar escritas desnecessárias
        if (jsonEncode(_styles.map((k,v) => MapEntry(k, _textStyleToJson(v)))) != jsonEncode(firebaseStyles.map((k,v) => MapEntry(k, _textStyleToJson(v))))) {
          _styles = firebaseStyles;
          await _saveStylesToPrefs(_styles); // Salva o tema do Firebase nas prefs
          notifyListeners();
          debugPrint('Tema atualizado pelo Firebase Remote Config e salvo nas SharedPreferences.');
        } else {
          debugPrint('Tema do Firebase é o mesmo que o atual. Nenhuma alteração aplicada.');
        }
      } else {
        debugPrint('Nenhuma configuração de tema encontrada no Firebase Remote Config ou está vazia.');
      }
    } catch (e) {
      debugPrint('Erro ao buscar ou aplicar Firebase Remote Config: $e');
      // Em caso de erro, o app continua com o tema carregado (prefs ou inicial)
    }
  }


  // --- Métodos de atualização e reset ---
  Future<void> updateStyleProperty(
      String styleKey, {
        String? fontFamily,
        double? fontSize,
        FontWeight? fontWeight,
        double? letterSpacing,
      }) async {
    if (!_styles.containsKey(styleKey)) return;

    TextStyle currentStyle = _styles[styleKey]!;
    TextStyle newStyle;

    String targetFontFamily = fontFamily ?? currentStyle.fontFamily?.split('_').first ?? 'Poppins'; // Fallback para Poppins

    newStyle = GoogleFonts.getFont(
      targetFontFamily,
      fontSize: fontSize ?? currentStyle.fontSize,
      fontWeight: fontWeight ?? currentStyle.fontWeight,
      letterSpacing: letterSpacing ?? currentStyle.letterSpacing,
      color: currentStyle.color,
      fontStyle: currentStyle.fontStyle,
    );

    _styles[styleKey] = newStyle;
    await _saveStylesToPrefs(_styles); // Salva após modificação local
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    _styles = _extractStylesFromTextTheme(_initialTextTheme);
    await _saveStylesToPrefs(_styles); // Salva o tema padrão nas prefs
    notifyListeners();
    debugPrint('Tema resetado para o padrão e salvo nas SharedPreferences.');
  }

  // --- Helpers de Serialização/Deserialização de TextStyle ---
  Map<String, dynamic> _textStyleToJson(TextStyle style) {
    return {
      'fontFamily': style.fontFamily?.split('_').first, // Salva apenas o nome base da família
      'fontSize': style.fontSize,
      'fontWeightIndex': style.fontWeight?.index, // Salva o índice do FontWeight
      'letterSpacing': style.letterSpacing,
      // Adicione outras propriedades se necessário (ex: color, fontStyle)
      // 'color': style.color?.value,
      // 'fontStyle': style.fontStyle?.index,
    };
  }

  TextStyle _textStyleFromJson(Map<String, dynamic> json) {
    String fontFamily = json['fontFamily'] as String? ?? 'Poppins'; // Fallback
    double? fontSize = (json['fontSize'] as num?)?.toDouble();

    // MODIFIED SECTION START
    final num? fontWeightIndexNum = json['fontWeightIndex'] as num?; // Cast to num? for flexibility (int or double)
    FontWeight? fontWeight;

    if (fontWeightIndexNum != null) { // This is a boolean condition
      final int fontWeightIntValue = fontWeightIndexNum.toInt(); // Convert num to int
      // Check if the integer value is a valid index for FontWeight.values
      if (fontWeightIntValue >= 0 && fontWeightIntValue < FontWeight.values.length) {
        fontWeight = FontWeight.values[fontWeightIntValue];
      } else {
        // Log an error if the index is out of bounds
        fontWeight = null; // Or assign a default FontWeight
        debugPrint('Error in _textStyleFromJson: fontWeightIndex $fontWeightIntValue is out of bounds for FontWeight.values. Original value: $fontWeightIndexNum');
      }
    } else {
      // fontWeightIndexNum is null
      fontWeight = null;
    }
    // MODIFIED SECTION END

    double? letterSpacing = (json['letterSpacing'] as num?)?.toDouble();
    // Color? color = (json['color'] as int? != null) ? Color(json['color'] as int) : null;
    // FontStyle? fontStyle = (json['fontStyle'] as int? != null) ? FontStyle.values[json['fontStyle'] as int] : null;

    return GoogleFonts.getFont(
      fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      // color: color,
      // fontStyle: fontStyle,
    );
  }
}