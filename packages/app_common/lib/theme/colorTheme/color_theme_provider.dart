import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart'; // Opcional
import 'dart:convert';
// initial_color_theme.dart será usado no main para passar os esquemas iniciais

// Gerencia o tema de cores do aplicativo, permitindo persistência e atualizações para modos claro e escuro.
class ColorThemeProvider with ChangeNotifier {
  late ColorScheme _lightColorScheme;
  late ColorScheme _darkColorScheme;
  late Brightness _currentBrightness;

  final ColorScheme _initialLightColorScheme;
  final ColorScheme _initialDarkColorScheme;

  bool _isLoading = true;
  bool _isInitialLoading = true;

  bool get isLoading => _isLoading;
  bool get isInitialLoading => _isInitialLoading;

  // Retorna o esquema de cores ativo com base no brilho atual
  ColorScheme get colorScheme => _currentBrightness == Brightness.light ? _lightColorScheme : _darkColorScheme;
  Brightness get currentBrightness => _currentBrightness;

  static const String _prefsKeyLight = 'app_color_scheme_light';
  static const String _prefsKeyDark = 'app_color_scheme_dark';
  static const String _prefsKeyBrightness = 'app_theme_brightness';

  // Chaves para Firebase (se usado, devem ser diferentes para light/dark)
  static const String _remoteConfigKeyLight = 'color_scheme_config_light';
  static const String _remoteConfigKeyDark = 'color_scheme_config_dark';

  static const List<String> colorKeys = [
    'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer',
    'secondary', 'onSecondary', 'secondaryContainer', 'onSecondaryContainer',
    'tertiary', 'onTertiary', 'tertiaryContainer', 'onTertiaryContainer',
    'error', 'onError', 'errorContainer', 'onErrorContainer',
    'background', 'onBackground',
    'surface', 'onSurface', 'surfaceVariant', 'onSurfaceVariant',
    'outline', 'outlineVariant',
    'shadow', 'scrim',
    'inverseSurface', 'onInverseSurface', 'inversePrimary', 'surfaceTint',
  ];

  ColorThemeProvider({
    required ColorScheme initialLightColorScheme,
    required ColorScheme initialDarkColorScheme,
  })  : _initialLightColorScheme = initialLightColorScheme,
        _initialDarkColorScheme = initialDarkColorScheme {
    // Define os esquemas iniciais como padrão e o brilho inicial como claro
    _lightColorScheme = _initialLightColorScheme;
    _darkColorScheme = _initialDarkColorScheme;
    _currentBrightness = Brightness.light; // Padrão inicial
  }

  Future<void> initializeTheme() async {
    _isLoading = true;
    _isInitialLoading = true;
    notifyListeners();

    // 1. Carregar o brilho salvo (ou usar o padrão)
    final prefs = await SharedPreferences.getInstance();
    final String? savedBrightness = prefs.getString(_prefsKeyBrightness);
    if (savedBrightness == 'dark') {
      _currentBrightness = Brightness.dark;
    } else {
      _currentBrightness = Brightness.light; // Padrão é light
    }

    // 2. Carregar os esquemas de cores (claro e escuro) do SharedPreferences
    ColorScheme? prefsLight = await _loadColorSchemeFromPrefs(Brightness.light);
    _lightColorScheme = prefsLight ?? _initialLightColorScheme;

    ColorScheme? prefsDark = await _loadColorSchemeFromPrefs(Brightness.dark);
    _darkColorScheme = prefsDark ?? _initialDarkColorScheme;

    _isInitialLoading = false;
    notifyListeners(); // Notifica após carregar brilho e esquemas base

    // 3. Configurar e buscar do Firebase Remote Config (OPCIONAL)
    // Esta parte pode ser expandida para buscar ambos os temas
    try {
      await _setupRemoteConfig();
      await _fetchAndApplyFirebaseConfig(_currentBrightness); // Busca para o tema ativo
    } catch (e) {
      debugPrint('Erro ao inicializar ou buscar Firebase Remote Config para cores: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    _isLoading = true;
    notifyListeners();

    _currentBrightness = _currentBrightness == Brightness.light ? Brightness.dark : Brightness.light;

    // Salva o novo brilho
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyBrightness, _currentBrightness == Brightness.dark ? 'dark' : 'light');

    // Tenta carregar o esquema correspondente do Firebase se não for o inicial
    // ou se a lógica de atualização do Firebase for mais complexa.
    // Por ora, apenas alterna e notifica. O editor usará o esquema já carregado.
    // Se o esquema não estiver carregado/salvo, ele usará o inicial.
    // Uma lógica mais robusta poderia ser recarregar do Firebase aqui também.
    // await _fetchAndApplyFirebaseConfig(_currentBrightness);

    _isLoading = false;
    notifyListeners();
  }

  Color? getColor(String colorKey) {
    final scheme = colorScheme; // Usa o getter que retorna o esquema ativo
    switch (colorKey) {
      case 'primary': return scheme.primary;
      case 'onPrimary': return scheme.onPrimary;
      case 'primaryContainer': return scheme.primaryContainer;
      case 'onPrimaryContainer': return scheme.onPrimaryContainer;
      case 'secondary': return scheme.secondary;
      case 'onSecondary': return scheme.onSecondary;
      case 'secondaryContainer': return scheme.secondaryContainer;
      case 'onSecondaryContainer': return scheme.onSecondaryContainer;
      case 'tertiary': return scheme.tertiary;
      case 'onTertiary': return scheme.onTertiary;
      case 'tertiaryContainer': return scheme.tertiaryContainer;
      case 'onTertiaryContainer': return scheme.onTertiaryContainer;
      case 'error': return scheme.error;
      case 'onError': return scheme.onError;
      case 'errorContainer': return scheme.errorContainer;
      case 'onErrorContainer': return scheme.onErrorContainer;
      case 'background': return scheme.background;
      case 'onBackground': return scheme.onBackground;
      case 'surface': return scheme.surface;
      case 'onSurface': return scheme.onSurface;
      case 'surfaceVariant': return scheme.surfaceVariant;
      case 'onSurfaceVariant': return scheme.onSurfaceVariant;
      case 'outline': return scheme.outline;
      case 'outlineVariant': return scheme.outlineVariant;
      case 'shadow': return scheme.shadow;
      case 'scrim': return scheme.scrim;
      case 'inverseSurface': return scheme.inverseSurface;
      case 'onInverseSurface': return scheme.onInverseSurface;
      case 'inversePrimary': return scheme.inversePrimary;
      case 'surfaceTint': return scheme.surfaceTint;
      default: return null;
    }
  }

  Future<void> _saveColorSchemeToPrefs(ColorScheme schemeToSave, Brightness brightness) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> serializedColors = _colorSchemeToMapInt(schemeToSave);
    final key = brightness == Brightness.light ? _prefsKeyLight : _prefsKeyDark;
    await prefs.setString(key, jsonEncode(serializedColors));
    debugPrint('Esquema de cores ($brightness) salvo no SharedPreferences.');
  }

  Future<ColorScheme?> _loadColorSchemeFromPrefs(Brightness brightness) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = brightness == Brightness.light ? _prefsKeyLight : _prefsKeyDark;
      final String? serializedColorsString = prefs.getString(key);
      if (serializedColorsString == null) return null;

      final Map<String, dynamic> decodedMap = jsonDecode(serializedColorsString);
      final Map<String, int> colorIntMap = decodedMap.map((key, value) => MapEntry(key, value as int));
      debugPrint('Esquema de cores ($brightness) carregado do SharedPreferences.');
      // Ao carregar, usa o brilho correspondente e os valores iniciais como fallback
      return _colorSchemeFromMapInt(colorIntMap, brightness, brightness == Brightness.light ? _initialLightColorScheme : _initialDarkColorScheme);
    } catch (e) {
      debugPrint('Erro ao carregar esquema de cores ($brightness) do SharedPreferences: $e');
      return null;
    }
  }

  Future<void> _setupRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    // Define valores padrão para ambos os temas no Firebase
    final Map<String, dynamic> defaultRemoteConfigValues = {
      _remoteConfigKeyLight: jsonEncode(_colorSchemeToMapInt(_initialLightColorScheme)),
      _remoteConfigKeyDark: jsonEncode(_colorSchemeToMapInt(_initialDarkColorScheme)),
    };
    await remoteConfig.setDefaults(defaultRemoteConfigValues);
    debugPrint('Firebase Remote Config (cores) configurado com padrões para light e dark.');
  }

  Future<void> _fetchAndApplyFirebaseConfig(Brightness brightnessToFetch) async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.fetchAndActivate();
      final remoteConfigKey = brightnessToFetch == Brightness.light ? _remoteConfigKeyLight : _remoteConfigKeyDark;
      final String? configString = remoteConfig.getString(remoteConfigKey);

      if (configString != null && configString.isNotEmpty) {
        final Map<String, dynamic> decodedJson = jsonDecode(configString);
        final Map<String, int> firebaseColorIntMap = decodedJson.map((key, value) => MapEntry(key, value as int));
        final initialSchemeForFallback = brightnessToFetch == Brightness.light ? _initialLightColorScheme : _initialDarkColorScheme;
        final ColorScheme firebaseColorScheme = _colorSchemeFromMapInt(firebaseColorIntMap, brightnessToFetch, initialSchemeForFallback);

        bool changed = false;
        if (brightnessToFetch == Brightness.light) {
          if (jsonEncode(_colorSchemeToMapInt(_lightColorScheme)) != jsonEncode(_colorSchemeToMapInt(firebaseColorScheme))) {
            _lightColorScheme = firebaseColorScheme;
            changed = true;
          }
        } else {
          if (jsonEncode(_colorSchemeToMapInt(_darkColorScheme)) != jsonEncode(_colorSchemeToMapInt(firebaseColorScheme))) {
            _darkColorScheme = firebaseColorScheme;
            changed = true;
          }
        }

        if (changed) {
          await _saveColorSchemeToPrefs(firebaseColorScheme, brightnessToFetch);
          notifyListeners();
          debugPrint('Esquema de cores ($brightnessToFetch) atualizado pelo Firebase e salvo.');
        } else {
          debugPrint('Esquema de cores ($brightnessToFetch) do Firebase é o mesmo que o atual.');
        }
      } else {
        debugPrint('Nenhuma config de esquema de cores ($brightnessToFetch) encontrada no Firebase.');
      }
    } catch (e) {
      debugPrint('Erro ao buscar Firebase Remote Config ($brightnessToFetch): $e');
    }
  }

  Future<void> updateColor(String colorKey, Color newColor) async {
    ColorScheme activeScheme = _currentBrightness == Brightness.light ? _lightColorScheme : _darkColorScheme;
    Map<String, Color> currentColors = _colorSchemeToMapColor(activeScheme);

    if (!currentColors.containsKey(colorKey)) {
      debugPrint("Chave de cor '$colorKey' não encontrada no esquema ativo.");
      return;
    }

    currentColors[colorKey] = newColor;
    ColorScheme updatedScheme = _colorSchemeFromMapColor(currentColors, _currentBrightness, activeScheme); // Passa o esquema base para manter outras props

    if (_currentBrightness == Brightness.light) {
      _lightColorScheme = updatedScheme;
    } else {
      _darkColorScheme = updatedScheme;
    }

    await _saveColorSchemeToPrefs(updatedScheme, _currentBrightness);
    notifyListeners();
    debugPrint("Cor '$colorKey' atualizada para ${newColor.value.toRadixString(16)} no tema $_currentBrightness");
  }

  Future<void> resetToDefault() async {
    if (_currentBrightness == Brightness.light) {
      _lightColorScheme = _initialLightColorScheme;
      await _saveColorSchemeToPrefs(_lightColorScheme, Brightness.light);
    } else {
      _darkColorScheme = _initialDarkColorScheme;
      await _saveColorSchemeToPrefs(_darkColorScheme, Brightness.dark);
    }
    notifyListeners();
    debugPrint('Esquema de cores ($_currentBrightness) resetado para o padrão e salvo.');
  }

  Map<String, int> _colorSchemeToMapInt(ColorScheme scheme) {
    return {
      'primary': scheme.primary.value, 'onPrimary': scheme.onPrimary.value,
      'primaryContainer': scheme.primaryContainer.value, 'onPrimaryContainer': scheme.onPrimaryContainer.value,
      'secondary': scheme.secondary.value, 'onSecondary': scheme.onSecondary.value,
      'secondaryContainer': scheme.secondaryContainer.value, 'onSecondaryContainer': scheme.onSecondaryContainer.value,
      'tertiary': scheme.tertiary.value, 'onTertiary': scheme.onTertiary.value,
      'tertiaryContainer': scheme.tertiaryContainer.value, 'onTertiaryContainer': scheme.onTertiaryContainer.value,
      'error': scheme.error.value, 'onError': scheme.onError.value,
      'errorContainer': scheme.errorContainer.value, 'onErrorContainer': scheme.onErrorContainer.value,
      'background': scheme.background.value, 'onBackground': scheme.onBackground.value,
      'surface': scheme.surface.value, 'onSurface': scheme.onSurface.value,
      'surfaceVariant': scheme.surfaceVariant.value, 'onSurfaceVariant': scheme.onSurfaceVariant.value,
      'outline': scheme.outline.value, 'outlineVariant': scheme.outlineVariant.value,
      'shadow': scheme.shadow.value, 'scrim': scheme.scrim.value,
      'inverseSurface': scheme.inverseSurface.value, 'onInverseSurface': scheme.onInverseSurface.value,
      'inversePrimary': scheme.inversePrimary.value, 'surfaceTint': scheme.surfaceTint.value,
    };
  }

  ColorScheme _colorSchemeFromMapInt(Map<String, int> colorMap, Brightness brightness, ColorScheme fallbackScheme) {
    return ColorScheme(
      brightness: brightness,
      primary: Color(colorMap['primary'] ?? fallbackScheme.primary.value),
      onPrimary: Color(colorMap['onPrimary'] ?? fallbackScheme.onPrimary.value),
      primaryContainer: Color(colorMap['primaryContainer'] ?? fallbackScheme.primaryContainer.value),
      onPrimaryContainer: Color(colorMap['onPrimaryContainer'] ?? fallbackScheme.onPrimaryContainer.value),
      secondary: Color(colorMap['secondary'] ?? fallbackScheme.secondary.value),
      onSecondary: Color(colorMap['onSecondary'] ?? fallbackScheme.onSecondary.value),
      secondaryContainer: Color(colorMap['secondaryContainer'] ?? fallbackScheme.secondaryContainer.value),
      onSecondaryContainer: Color(colorMap['onSecondaryContainer'] ?? fallbackScheme.onSecondaryContainer.value),
      tertiary: Color(colorMap['tertiary'] ?? fallbackScheme.tertiary.value),
      onTertiary: Color(colorMap['onTertiary'] ?? fallbackScheme.onTertiary.value),
      tertiaryContainer: Color(colorMap['tertiaryContainer'] ?? fallbackScheme.tertiaryContainer.value),
      onTertiaryContainer: Color(colorMap['onTertiaryContainer'] ?? fallbackScheme.onTertiaryContainer.value),
      error: Color(colorMap['error'] ?? fallbackScheme.error.value),
      onError: Color(colorMap['onError'] ?? fallbackScheme.onError.value),
      errorContainer: Color(colorMap['errorContainer'] ?? fallbackScheme.errorContainer.value),
      onErrorContainer: Color(colorMap['onErrorContainer'] ?? fallbackScheme.onErrorContainer.value),
      background: Color(colorMap['background'] ?? fallbackScheme.background.value),
      onBackground: Color(colorMap['onBackground'] ?? fallbackScheme.onBackground.value),
      surface: Color(colorMap['surface'] ?? fallbackScheme.surface.value),
      onSurface: Color(colorMap['onSurface'] ?? fallbackScheme.onSurface.value),
      surfaceVariant: Color(colorMap['surfaceVariant'] ?? fallbackScheme.surfaceVariant.value),
      onSurfaceVariant: Color(colorMap['onSurfaceVariant'] ?? fallbackScheme.onSurfaceVariant.value),
      outline: Color(colorMap['outline'] ?? fallbackScheme.outline.value),
      outlineVariant: Color(colorMap['outlineVariant'] ?? fallbackScheme.outlineVariant.value),
      shadow: Color(colorMap['shadow'] ?? fallbackScheme.shadow.value),
      scrim: Color(colorMap['scrim'] ?? fallbackScheme.scrim.value),
      inverseSurface: Color(colorMap['inverseSurface'] ?? fallbackScheme.inverseSurface.value),
      onInverseSurface: Color(colorMap['onInverseSurface'] ?? fallbackScheme.onInverseSurface.value),
      inversePrimary: Color(colorMap['inversePrimary'] ?? fallbackScheme.inversePrimary.value),
      surfaceTint: Color(colorMap['surfaceTint'] ?? fallbackScheme.surfaceTint.value),
    );
  }

  Map<String, Color> _colorSchemeToMapColor(ColorScheme scheme) {
    // Simplesmente retorna todas as cores do esquema.
    return {
      'primary': scheme.primary, 'onPrimary': scheme.onPrimary,
      'primaryContainer': scheme.primaryContainer, 'onPrimaryContainer': scheme.onPrimaryContainer,
      'secondary': scheme.secondary, 'onSecondary': scheme.onSecondary,
      'secondaryContainer': scheme.secondaryContainer, 'onSecondaryContainer': scheme.onSecondaryContainer,
      'tertiary': scheme.tertiary, 'onTertiary': scheme.onTertiary,
      'tertiaryContainer': scheme.tertiaryContainer, 'onTertiaryContainer': scheme.onTertiaryContainer,
      'error': scheme.error, 'onError': scheme.onError,
      'errorContainer': scheme.errorContainer, 'onErrorContainer': scheme.onErrorContainer,
      'background': scheme.background, 'onBackground': scheme.onBackground,
      'surface': scheme.surface, 'onSurface': scheme.onSurface,
      'surfaceVariant': scheme.surfaceVariant, 'onSurfaceVariant': scheme.onSurfaceVariant,
      'outline': scheme.outline, 'outlineVariant': scheme.outlineVariant,
      'shadow': scheme.shadow, 'scrim': scheme.scrim,
      'inverseSurface': scheme.inverseSurface, 'onInverseSurface': scheme.onInverseSurface,
      'inversePrimary': scheme.inversePrimary, 'surfaceTint': scheme.surfaceTint,
    };
  }

  ColorScheme _colorSchemeFromMapColor(Map<String, Color> colorMap, Brightness brightness, ColorScheme baseScheme) {
    // Cria um novo ColorScheme usando as cores do mapa, mantendo outras propriedades do baseScheme se não estiverem no mapa.
    // Isso é importante para preservar propriedades como `brightness` e quaisquer outras que não sejam cores diretas.
    return baseScheme.copyWith(
      brightness: brightness, // Garante que o brilho seja o correto
      primary: colorMap['primary'] ?? baseScheme.primary,
      onPrimary: colorMap['onPrimary'] ?? baseScheme.onPrimary,
      primaryContainer: colorMap['primaryContainer'] ?? baseScheme.primaryContainer,
      onPrimaryContainer: colorMap['onPrimaryContainer'] ?? baseScheme.onPrimaryContainer,
      secondary: colorMap['secondary'] ?? baseScheme.secondary,
      onSecondary: colorMap['onSecondary'] ?? baseScheme.onSecondary,
      secondaryContainer: colorMap['secondaryContainer'] ?? baseScheme.secondaryContainer,
      onSecondaryContainer: colorMap['onSecondaryContainer'] ?? baseScheme.onSecondaryContainer,
      tertiary: colorMap['tertiary'] ?? baseScheme.tertiary,
      onTertiary: colorMap['onTertiary'] ?? baseScheme.onTertiary,
      tertiaryContainer: colorMap['tertiaryContainer'] ?? baseScheme.tertiaryContainer,
      onTertiaryContainer: colorMap['onTertiaryContainer'] ?? baseScheme.onTertiaryContainer,
      error: colorMap['error'] ?? baseScheme.error,
      onError: colorMap['onError'] ?? baseScheme.onError,
      errorContainer: colorMap['errorContainer'] ?? baseScheme.errorContainer,
      onErrorContainer: colorMap['onErrorContainer'] ?? baseScheme.onErrorContainer,
      background: colorMap['background'] ?? baseScheme.background,
      onBackground: colorMap['onBackground'] ?? baseScheme.onBackground,
      surface: colorMap['surface'] ?? baseScheme.surface,
      onSurface: colorMap['onSurface'] ?? baseScheme.onSurface,
      surfaceVariant: colorMap['surfaceVariant'] ?? baseScheme.surfaceVariant,
      onSurfaceVariant: colorMap['onSurfaceVariant'] ?? baseScheme.onSurfaceVariant,
      outline: colorMap['outline'] ?? baseScheme.outline,
      outlineVariant: colorMap['outlineVariant'] ?? baseScheme.outlineVariant,
      shadow: colorMap['shadow'] ?? baseScheme.shadow,
      scrim: colorMap['scrim'] ?? baseScheme.scrim,
      inverseSurface: colorMap['inverseSurface'] ?? baseScheme.inverseSurface,
      onInverseSurface: colorMap['onInverseSurface'] ?? baseScheme.onInverseSurface,
      inversePrimary: colorMap['inversePrimary'] ?? baseScheme.inversePrimary,
      surfaceTint: colorMap['surfaceTint'] ?? baseScheme.surfaceTint,
    );
  }
}
