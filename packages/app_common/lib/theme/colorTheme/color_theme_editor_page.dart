import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'color_theme_provider.dart';

// Página para editar as cores do tema do aplicativo.
class ColorThemeEditorPage extends StatefulWidget {
  const ColorThemeEditorPage({super.key});

  @override
  State<ColorThemeEditorPage> createState() => _ColorThemeEditorPageState();
}

class _ColorThemeEditorPageState extends State<ColorThemeEditorPage> {
  String? _selectedColorKey; // Chave da cor selecionada para edição (ex: 'primary')
  Color? _currentColorForPicker; // Cor atual para o seletor de cores
  late TextEditingController _hexColorController; // Controlador para o campo de texto hexadecimal
  final FocusNode _hexFocusNode = FocusNode(); // Nó de foco para o campo hexadecimal

  @override
  void initState() {
    super.initState();
    _hexColorController = TextEditingController();

    // Adia a configuração inicial para após o primeiro frame,
    // quando o provider já deve ter sido inicializado e o contexto está pronto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Inicializa com o primeiro item da lista de chaves de cores, se disponível.
        if (ColorThemeProvider.colorKeys.isNotEmpty) {
          _selectedColorKey = ColorThemeProvider.colorKeys.first;
        }
        // Busca o provider sem ouvir, pois a atualização inicial será feita aqui.
        final colorProvider = Provider.of<ColorThemeProvider>(context, listen: false);
        // Atualiza os controles com base no tema carregado pelo provider.
        _updateColorForPickerAndHexField(colorProvider);
      }
    });

    _hexColorController.addListener(_onHexColorChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chamado quando o provider muda (ex: após toggleThemeMode ou carregamento inicial completo)
    // ou quando o widget é reconstruído por outras razões.
    // Usamos addPostFrameCallback para garantir que o build atual esteja completo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Garante que o widget ainda está na árvore.
        final colorProvider = Provider.of<ColorThemeProvider>(context, listen: false);
        // Atualiza os controles (picker e campo hex) se o foco não estiver no campo hexadecimal,
        // para evitar sobrescrever a digitação do usuário.
        if (!_hexFocusNode.hasFocus) {
          _updateColorForPickerAndHexField(colorProvider);
        }
      }
    });
  }

  // Atualiza _currentColorForPicker e o campo de texto hexadecimal com base no provider.
  void _updateColorForPickerAndHexField(ColorThemeProvider provider) {
    if (!mounted) return; // Não faz nada se o widget não estiver montado.

    if (_selectedColorKey == null) {
      // Se nenhuma chave de cor estiver selecionada, limpa os campos.
      if (_currentColorForPicker != null || _hexColorController.text.isNotEmpty) {
        setState(() {
          _currentColorForPicker = null;
        });
        _hexColorController.removeListener(_onHexColorChanged);
        _hexColorController.clear();
        _hexColorController.addListener(_onHexColorChanged);
      }
      return;
    }

    // Obtém a nova cor do provider para a chave selecionada.
    final newColor = provider.getColor(_selectedColorKey!);

    // Atualiza o estado do _currentColorForPicker se a cor mudou.
    if (newColor != _currentColorForPicker) {
      setState(() {
        _currentColorForPicker = newColor;
      });
    }

    // Atualiza o campo de texto hexadecimal se a cor for válida e diferente do texto atual.
    if (_currentColorForPicker != null) {
      final String currentHex = _colorToHex(_currentColorForPicker!);
      // Compara em minúsculas para evitar atualizações desnecessárias por causa de case.
      if (_hexColorController.text.toLowerCase() != currentHex.toLowerCase()) {
        // Remove o listener temporariamente para evitar um loop de atualização.
        _hexColorController.removeListener(_onHexColorChanged);
        _hexColorController.text = currentHex; // Define o novo valor hexadecimal.
        _hexColorController.addListener(_onHexColorChanged);
      }
    } else { // Se _currentColorForPicker for nulo (ex: chave inválida ou cor não definida)
      _hexColorController.removeListener(_onHexColorChanged);
      _hexColorController.clear(); // Limpa o campo hexadecimal.
      _hexColorController.addListener(_onHexColorChanged);
    }
  }

  // Converte um objeto Color para sua representação em String Hexadecimal (ex: #AARRGGBB).
  String _colorToHex(Color color, {bool leadingHashSign = true}) {
    return '${leadingHashSign ? '#' : ''}'
        '${color.alpha.toRadixString(16).padLeft(2, '0')}' // Canal Alfa
        '${color.red.toRadixString(16).padLeft(2, '0')}'   // Canal Vermelho
        '${color.green.toRadixString(16).padLeft(2, '0')}' // Canal Verde
        '${color.blue.toRadixString(16).padLeft(2, '0')}';  // Canal Azul
  }

  // Tenta converter uma String Hexadecimal para um objeto Color.
  Color? _hexToColor(String hexString) {
    final buffer = StringBuffer();
    // Se o código não tiver alfa (6 caracteres + #, ou 6 caracteres), adiciona 'ff' (opacidade total).
    if (hexString.length == 6 || (hexString.startsWith('#') && hexString.length == 7)) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', '')); // Remove o '#' se presente.

    final String finalHex = buffer.toString();
    // O código hexadecimal final deve ter 8 caracteres (AARRGGBB).
    if (finalHex.length == 8) {
      try {
        return Color(int.parse(finalHex, radix: 16)); // Converte de hexadecimal para inteiro.
      } catch (e) {
        // Retorna nulo se a conversão falhar (ex: caracteres inválidos).
        debugPrint("Erro ao converter hex para cor: $e");
        return null;
      }
    }
    return null; // Retorna nulo se o comprimento não for adequado.
  }

  // Chamado quando o texto no campo hexadecimal muda.
  void _onHexColorChanged() {
    // Processa apenas se o campo hexadecimal estiver focado, para evitar atualizações
    // quando o texto é alterado programaticamente.
    if (!_hexFocusNode.hasFocus && _hexColorController.text.isNotEmpty) return;

    final String text = _hexColorController.text;
    final Color? newColor = _hexToColor(text); // Tenta converter o texto para cor.

    // Se uma nova cor válida for obtida e for diferente da cor atual no picker, atualiza o estado.
    if (newColor != null && newColor != _currentColorForPicker) {
      setState(() {
        _currentColorForPicker = newColor; // Atualiza a cor para o seletor/preview.
      });
    }
  }

  // Mostra o diálogo do seletor de cores (ColorPicker).
  void _showColorPicker(BuildContext dialogContext, ColorThemeProvider themeProvider) {
    if (_selectedColorKey == null || _currentColorForPicker == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Nenhuma cor selecionada ou cor inválida para editar.')),
      );
      return;
    }

    Color pickerColor = _currentColorForPicker!; // Cor inicial para o seletor.

    showDialog(
      context: dialogContext, // Usa o contexto da página para o diálogo.
      builder: (BuildContext context) { // Contexto interno do AlertDialog.
        return AlertDialog(
          title: Text('Selecionar Cor para $_selectedColorKey'),
          content: SingleChildScrollView(
            child: ColorPicker(
              color: pickerColor, // Cor atual do seletor.
              onColorChanged: (color) { // Chamado quando o usuário muda a cor no seletor.
                pickerColor = color; // Atualiza a cor que será aplicada.
              },
              enableOpacity: true, // Permite o ajuste da opacidade.
              pickersEnabled: const <ColorPickerType, bool>{ // Define quais seletores estarão disponíveis.
                ColorPickerType.both: false, ColorPickerType.primary: true,
                ColorPickerType.accent: true, ColorPickerType.bw: false,
                ColorPickerType.custom: true, ColorPickerType.wheel: true,
              },
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Aplicar'),
              onPressed: () async {
                // Mostra um indicador de carregamento sobre o AlertDialog do seletor.
                showDialog(
                  context: context, // Usa o contexto do AlertDialog do seletor.
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) => const Center(child: CircularProgressIndicator()),
                );

                // Atualiza a cor no provider.
                await themeProvider.updateColor(_selectedColorKey!, pickerColor);

                if (mounted) { // Verifica se o widget ainda está montado.
                  // Não é estritamente necessário chamar setState aqui para _currentColorForPicker
                  // ou atualizar _hexColorController.text, pois didChangeDependencies()
                  // será acionado pela notificação do provider e chamará _updateColorForPickerAndHexField.
                  // No entanto, para uma resposta visual imediata no campo hex, podemos fazer:
                  // _hexColorController.removeListener(_onHexColorChanged);
                  // _hexColorController.text = _colorToHex(pickerColor);
                  // _hexColorController.addListener(_onHexColorChanged);
                  // setState(() { _currentColorForPicker = pickerColor; });

                  Navigator.of(context).pop(); // Fecha o indicador de carregamento.
                  Navigator.of(context).pop(); // Fecha o diálogo do seletor de cores.

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Cor $_selectedColorKey atualizada!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Aplica a cor do campo hexadecimal ao tema.
  void _applyHexColorToTheme(ColorThemeProvider themeProvider) {
    if (_selectedColorKey == null) return; // Nenhuma chave de cor selecionada.

    final Color? colorFromHex = _hexToColor(_hexColorController.text); // Converte o texto para cor.

    if (colorFromHex != null) { // Se a conversão for bem-sucedida.
      // Mostra um indicador de carregamento na página.
      showDialog(
        context: context, // Usa o contexto da página.
        barrierDismissible: false,
        builder: (BuildContext loadingContext) => const Center(child: CircularProgressIndicator()),
      );

      // Atualiza a cor no provider.
      themeProvider.updateColor(_selectedColorKey!, colorFromHex).then((_) {
        if (mounted) { // Se o widget ainda estiver montado.
          Navigator.of(context).pop(); // Fecha o indicador de carregamento.
          // didChangeDependencies cuidará de atualizar os campos.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cor $_selectedColorKey atualizada via Hex!')),
          );
        }
      }).catchError((error) { // Em caso de erro na atualização.
        if (mounted) {
          Navigator.of(context).pop(); // Fecha o indicador de carregamento.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao aplicar cor: $error')),
          );
        }
      });
    } else { // Se o código hexadecimal for inválido.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código hexadecimal inválido.')),
      );
    }
  }

  @override
  void dispose() {
    _hexColorController.removeListener(_onHexColorChanged);
    _hexColorController.dispose();
    _hexFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ouve o provider para reconstruir a UI quando o tema (brilho) ou as cores mudam.
    final colorProvider = Provider.of<ColorThemeProvider>(context);
    // A chamada _updateColorForPickerAndHexField é gerenciada por initState e didChangeDependencies.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Tema de Cores'),
        actions: [
          // Switch para alternar o tema claro/escuro.
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(colorProvider.currentBrightness == Brightness.light ? Icons.wb_sunny : Icons.nightlight_round),
                const SizedBox(width: 4),
                Switch(
                  value: colorProvider.currentBrightness == Brightness.dark, // Define o estado do switch.
                  onChanged: colorProvider.isLoading ? null : (bool value) { // Desabilita durante o carregamento.
                    colorProvider.toggleThemeMode(); // Chama o método do provider para alternar o tema.
                  },
                  activeColor: Theme.of(context).colorScheme.onPrimary, // Cor do switch quando ativo.
                ),
              ],
            ),
          ),
          // Botão para buscar configurações do Firebase.
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Buscar do Firebase',
            onPressed: colorProvider.isLoading ? null : () async {
              final brightnessToFetch = colorProvider.currentBrightness;
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              // Re-inicializa para buscar do Firebase (já considera o brilho salvo e busca ambos os temas).
              // Ou poderia chamar _fetchAndApplyFirebaseConfig(brightnessToFetch) se quisesse buscar só o ativo.
              await colorProvider.initializeTheme();
              if(mounted) {
                Navigator.of(context).pop(); // Fecha o loading.
                // _updateColorForPickerAndHexField(colorProvider); // didChangeDependencies fará isso.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Configurações de cores ($brightnessToFetch) do Firebase buscadas/atualizadas.')),
                );
              }
            },
          ),
          // Botão para resetar o tema ativo para o padrão.
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Resetar para Padrão',
            onPressed: colorProvider.isLoading ? null : () async {
              showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
              await colorProvider.resetToDefault(); // Reseta o tema ativo (claro ou escuro).
              if(mounted) {
                Navigator.of(context).pop(); // Fecha o loading.
                // _updateColorForPickerAndHexField(colorProvider); // didChangeDependencies fará isso.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema de cores atual resetado para o padrão.')),
                );
              }
            },
          ),
        ],
      ),
      body: Builder( // Usa Builder para obter um contexto abaixo do Scaffold, se necessário.
        builder: (BuildContext scaffoldContext) {
          // Obtém o esquema de cores atual (sensível ao tema claro/escuro) do provider.
          final currentColorScheme = colorProvider.colorScheme;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seção de Pré-visualização do Tema.
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pré-visualização (${colorProvider.currentBrightness == Brightness.light ? 'Tema Claro' : 'Tema Escuro'})",
                          style: Theme.of(scaffoldContext).textTheme.titleLarge?.copyWith(color: currentColorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        // Gera seções de preview para cada cor principal.
                        _buildPreviewSection(scaffoldContext, "Primário", currentColorScheme.primary, currentColorScheme.onPrimary),
                        _buildPreviewSection(scaffoldContext, "Container Primário", currentColorScheme.primaryContainer, currentColorScheme.onPrimaryContainer),
                        _buildPreviewSection(scaffoldContext, "Secundário", currentColorScheme.secondary, currentColorScheme.onSecondary),
                        _buildPreviewSection(scaffoldContext, "Container Secundário", currentColorScheme.secondaryContainer, currentColorScheme.onSecondaryContainer),
                        _buildPreviewSection(scaffoldContext, "Terciário", currentColorScheme.tertiary, currentColorScheme.onTertiary),
                        _buildPreviewSection(scaffoldContext, "Erro", currentColorScheme.error, currentColorScheme.onError),
                        _buildPreviewSection(scaffoldContext, "Fundo", currentColorScheme.background, currentColorScheme.onBackground),
                        _buildPreviewSection(scaffoldContext, "Superfície", currentColorScheme.surface, currentColorScheme.onSurface),
                        const SizedBox(height: 10),
                        // Exemplos de widgets usando as cores do tema.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(onPressed: () {}, child: Text('Botão Primário', style: TextStyle(color: currentColorScheme.onPrimary)), style: ElevatedButton.styleFrom(backgroundColor: currentColorScheme.primary)),
                            FloatingActionButton(onPressed: () {}, backgroundColor: currentColorScheme.secondary, child: Icon(Icons.add, color: currentColorScheme.onSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Card(
                            color: currentColorScheme.surfaceVariant,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Texto em Surface Variant", style: TextStyle(color: currentColorScheme.onSurfaceVariant)),
                            )
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Seção do Editor de Cores.
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Editor de Cores (${colorProvider.currentBrightness == Brightness.light ? 'Tema Claro' : 'Tema Escuro'})",
                          style: Theme.of(scaffoldContext).textTheme.titleLarge?.copyWith(color: currentColorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        // Dropdown para selecionar a chave da cor a ser editada.
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Selecionar Chave da Cor',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: currentColorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                          value: _selectedColorKey,
                          items: ColorThemeProvider.colorKeys.map((key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Text(key, style: TextStyle(color: currentColorScheme.onSurfaceVariant)),
                            );
                          }).toList(),
                          onChanged: colorProvider.isLoading ? null : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedColorKey = value;
                                // Atualiza o picker e o campo hex ao mudar a chave.
                                _updateColorForPickerAndHexField(colorProvider);
                              });
                            }
                          },
                          disabledHint: _selectedColorKey != null ? Text(_selectedColorKey!) : null,
                        ),
                        const SizedBox(height: 20),
                        // Controles de edição (preview da cor, campo hex, botões).
                        if (_selectedColorKey != null) ...[
                          Row( // Preview da cor selecionada.
                            children: [
                              Expanded(
                                child: Text(
                                  'Cor selecionada ($_selectedColorKey):',
                                  style: Theme.of(scaffoldContext).textTheme.titleMedium?.copyWith(color: currentColorScheme.onSurface),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _currentColorForPicker ?? Colors.transparent, // Mostra transparente se nulo.
                                  border: Border.all(color: currentColorScheme.outline),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Campo de texto para entrada do código hexadecimal.
                          TextField(
                            controller: _hexColorController,
                            focusNode: _hexFocusNode,
                            decoration: InputDecoration(
                                labelText: 'Código Hex (ex: #AARRGGBB)',
                                hintText: '#RRGGBB ou #AARRGGBB',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () { // Limpa o campo e reseta a cor para a do tema.
                                    _hexColorController.clear();
                                    _updateColorForPickerAndHexField(colorProvider);
                                  },
                                )
                            ),
                            enabled: !colorProvider.isLoading && _selectedColorKey != null,
                            onEditingComplete: () { // Ao finalizar a edição (ex: Enter).
                              _onHexColorChanged(); // Processa a mudança.
                              if (_hexFocusNode.hasFocus) _hexFocusNode.unfocus(); // Remove o foco.
                            },
                          ),
                          const SizedBox(height: 20),
                          // Botões de ação.
                          Column(
                            children: [
                              Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(children:[Expanded(child: ElevatedButton.icon(
                                    icon: const Icon(Icons.colorize),
                                    label: const Text('Alterar no Seletor'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentColorScheme.primary, foregroundColor: currentColorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    onPressed: (colorProvider.isLoading || _selectedColorKey == null) ? null : () {
                                      _showColorPicker(scaffoldContext, colorProvider);
                                    },
                                  ))])
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(children: [Expanded(child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Aplicar Hex ao Tema'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentColorScheme.secondary, foregroundColor: currentColorScheme.onSecondary,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                  onPressed: (colorProvider.isLoading || _selectedColorKey == null || _hexColorController.text.isEmpty) ? null : () {
                                    _applyHexColorToTheme(colorProvider);
                                  },
                                ))]),
                              )
                            ],
                          ),
                        ] else if (_selectedColorKey != null) ...[ // Fallback se _selectedColorKey não for nulo mas _currentColorForPicker ainda não carregou.
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Center(child: Text("Carregando cor...")),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget auxiliar para construir seções de pré-visualização de cores.
  Widget _buildPreviewSection(BuildContext previewContext, String label, Color backgroundColor, Color textColor, {Color? textColorOnBackground}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(previewContext).colorScheme.outline.withOpacity(0.5))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            Text( // Exibe o código hexadecimal da cor.
              _colorToHex(backgroundColor).toUpperCase(),
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
