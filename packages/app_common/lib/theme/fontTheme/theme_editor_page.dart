
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'font_theme_provider.dart';
import 'initial_font_theme.dart';

class ThemeEditorPage extends StatefulWidget {
  const ThemeEditorPage({super.key});

  @override
  State<ThemeEditorPage> createState() => _ThemeEditorPageState();
}

class _ThemeEditorPageState extends State<ThemeEditorPage> {
  String? _selectedStyleKey;

  final _fontSizeController = TextEditingController();
  final _letterSpacingController = TextEditingController();
  FontWeight? _selectedFontWeight;
  String? _selectedFontFamily;

  final List<String> _fontFamilies = ['Poppins', 'Roboto', 'Lato', 'Montserrat', 'Open Sans', 'Nunito'];
  final List<FontWeight> _fontWeights = [
    FontWeight.w100, FontWeight.w200, FontWeight.w300, FontWeight.w400,
    FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.w900,
  ];

  @override
  void initState() {
    super.initState();
    if (FontThemeProvider.styleKeys.isNotEmpty) {
      _selectedStyleKey = FontThemeProvider.styleKeys.first;
      // Adiado para após o primeiro frame para garantir que o context esteja disponível
      // e o provider tenha tido a chance de carregar os dados iniciais.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Verifica se o widget ainda está montado
          _updateControlsForSelectedStyle();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chamado quando o provider muda (ex: após carregamento do Firebase)
    // ou quando o widget é reconstruído.
    // Garante que os controles sejam atualizados se o _selectedStyleKey já estiver definido.
    // Isso é útil se a página é carregada e o tema do provider é atualizado logo depois.
    if (_selectedStyleKey != null) {
      // Adia a atualização para o próximo frame para evitar chamar setState durante o build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Verifica se o widget ainda está montado
          _updateControlsForSelectedStyle();
        }
      });
    }
  }

  void _updateControlsForSelectedStyle() {
    if (_selectedStyleKey == null || !mounted) return;

    final themeProvider = Provider.of<FontThemeProvider>(context, listen: false);
    final style = themeProvider.getStyle(_selectedStyleKey!);

    if (style != null) {
      _fontSizeController.text = style.fontSize?.toStringAsFixed(1) ?? '';
      _letterSpacingController.text = style.letterSpacing?.toStringAsFixed(2) ?? '';
      _selectedFontWeight = style.fontWeight;

      String? currentFontFamilyName = style.fontFamily?.split('_').first; // Obter nome base
      if (currentFontFamilyName != null && _fontFamilies.any((f) => f.toLowerCase() == currentFontFamilyName!.toLowerCase())) {
        _selectedFontFamily = _fontFamilies.firstWhere((f) => f.toLowerCase() == currentFontFamilyName!.toLowerCase());
      } else {
        _selectedFontFamily = null;
      }
      // setState é necessário para atualizar os dropdowns com os valores corretos
      // se eles mudaram devido a uma atualização do provider (ex: Firebase)
      if(mounted) setState(() {});
    }
  }

  Future<void> _applyChanges() async { // Marcado como async
    if (_selectedStyleKey == null) return;

    final themeProvider = Provider.of<FontThemeProvider>(context, listen: false);

    double? fontSize;
    if (_fontSizeController.text.isNotEmpty) {
      fontSize = double.tryParse(_fontSizeController.text);
      if (fontSize == null) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tamanho da Fonte Inválido.')));
        return;
      }
    }

    double? letterSpacing;
    if (_letterSpacingController.text.isNotEmpty) {
      letterSpacing = double.tryParse(_letterSpacingController.text);
      if (letterSpacing == null) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Espaçamento Inválido.')));
        return;
      }
    }

    // Mostra um indicador de carregamento
    if(mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    await themeProvider.updateStyleProperty( // await a operação
      _selectedStyleKey!,
      fontFamily: _selectedFontFamily,
      fontSize: fontSize,
      fontWeight: _selectedFontWeight,
      letterSpacing: letterSpacing,
    );

    if(mounted) {
      Navigator.of(context).pop(); // Fecha o indicador de carregamento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_selectedStyleKey atualizado!')),
      );
    }
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    _letterSpacingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<FontThemeProvider>(context);

    // A lógica de isLoading e isInitialLoading foi movida para dentro do ListView.builder
    // para o loader da preview, e para os botões/campos desabilitados.
    // Não é necessário um loader de tela cheia aqui se o MaterialApp já lida com o carregamento inicial do provider.
    double height = MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de TextTheme'),
        actions: [
          IconButton(
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: 'Buscar do Firebase',
              onPressed: themeProvider.isLoading ? null : () async {
                if(mounted) {
                  showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  });
                }
                await themeProvider.initializeTheme();
                if(mounted) {
                  Navigator.of(context).pop();
                  _updateControlsForSelectedStyle();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuração do Firebase buscada.')),
                  );
                }
              }
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Resetar para Padrão',
            onPressed: themeProvider.isLoading ? null : () async {
              if(mounted) {
                showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                });
              }
              await themeProvider.resetToDefault();
              if(mounted) {
                Navigator.of(context).pop();
                _updateControlsForSelectedStyle();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema resetado para o padrão.')),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        height: height,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column( // Este é o Column que foi ajustado
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção do Editor
              Container(
                  margin: EdgeInsets.all(16),
                  height: height, // Ajuste a altura conforme necessário
                  width: MediaQuery.of(context).size.width,
                  child: Card(
                    elevation: 2,
                    child: Column( // Este Column interno está correto
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text("Pré-visualização ao Vivo", style: Theme.of(context).textTheme.titleLarge),
                        ),
                        const Divider(),
                        Expanded( // Este Expanded permite que o ListView preencha o Card
                          child: themeProvider.isLoading && !themeProvider.isInitialLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                            padding: const EdgeInsets.all(12.0),
                            itemCount: FontThemeProvider.styleKeys.length,
                            itemBuilder: (context, index) {
                              final key = FontThemeProvider.styleKeys[index];
                              TextStyle? style = themeProvider.getStyle(key);
                              if (style == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    SizedBox(width: 120, child: Text(key, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold))),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz',
                                        style: style.copyWith(color: style.color ?? Theme.of(context).textTheme.bodyMedium?.color),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
              ),
              Container(
                  padding: EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.height, // Ajuste a altura conforme necessário
                  width: MediaQuery.of(context).size.width,
                  child: Card(
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text("Editor de Estilo", style: Theme.of(context).textTheme.titleLarge),
                        ),
                        Padding(padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12), child: const Divider()),
                        Padding(padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12), child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Selecionar Estilo de Texto', border: OutlineInputBorder()),
                          value: _selectedStyleKey,
                          items: FontThemeProvider.styleKeys.map((key) {
                            return DropdownMenuItem<String>(value: key, child: Text(key));
                          }).toList(),
                          onChanged: themeProvider.isLoading ? null : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStyleKey = value;
                                _updateControlsForSelectedStyle();
                              });
                            }
                          },
                          disabledHint: _selectedStyleKey != null ? Text(_selectedStyleKey!) : null,
                        )),
                       if (_selectedStyleKey != null) ...[
                         Padding(padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12), child: DropdownButtonFormField<String>(
                           decoration: const InputDecoration(labelText: 'Família da Fonte', border: OutlineInputBorder()),
                           value: _selectedFontFamily,
                           items: _fontFamilies.map((family) {
                             return DropdownMenuItem<String>(
                               value: family,
                               child: Text(family, style: TextStyle(fontFamily: family)),
                             );
                           }).toList(),
                           onChanged: themeProvider.isLoading ? null : (value) => setState(() => _selectedFontFamily = value),
                           disabledHint: _selectedFontFamily != null ? Text(_selectedFontFamily!) : null,
                         )),
                         Padding(padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12), child: TextField(
                           controller: _fontSizeController,
                           decoration: const InputDecoration(labelText: 'Tamanho (ex: 16.0)', border: OutlineInputBorder()),
                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
                           enabled: !themeProvider.isLoading,
                         )),
                         Padding(padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12), child: DropdownButtonFormField<FontWeight>(
                           decoration: const InputDecoration(labelText: 'Peso da Fonte', border: OutlineInputBorder()),
                           value: _selectedFontWeight,
                           items: _fontWeights.map((weight) {
                             return DropdownMenuItem<FontWeight>(
                               value: weight,
                               child: Text(weight.toString().split('.').last),
                             );
                           }).toList(),
                           onChanged: themeProvider.isLoading ? null : (value) => setState(() => _selectedFontWeight = value),
                           disabledHint: _selectedFontWeight != null ? Text(_selectedFontWeight.toString().split('.').last) : null,
                         )),
                         Padding(padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12), child: TextField(
                           controller: _letterSpacingController,
                           decoration: const InputDecoration(labelText: 'Espaçamento (ex: 0.5)', border: OutlineInputBorder()),
                           keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                           enabled: !themeProvider.isLoading,
                         )),
                         Padding(padding: const EdgeInsets.all(24), child: Center(
                           child: ElevatedButton.icon(
                             icon: const Icon(Icons.check_circle_outline),
                             label: const Text('Aplicar Mudanças'),
                             style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                             onPressed: themeProvider.isLoading ? null : _applyChanges,
                           ),
                         )),
                       ],
                      ],
                    ),
                  )
              ),
            ],
          )
        ),
      ),
    );
  }
}
