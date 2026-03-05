import 'package:flutter/material.dart';

/// AppTheme centraliza TODO o estilo do aplicativo.
///
/// Por que criar um arquivo só para o tema?
/// - Consistência visual: botões, inputs, cards e textos ficam com “a mesma cara”.
/// - Manutenção: trocar cor, borda, radius, fontes… muda em um lugar só.
/// - Escalabilidade: quando o app cresce, evita repetir estilos em 30 lugares.
///
/// Como o Flutter decide o estilo final de um widget?
/// 1) O ThemeData (global) define valores padrão.
/// 2) Os *ThemeData específicos de componentes* refinam (ex: FilledButtonTheme, InputDecorationTheme).
/// 3) O estilo local do widget (ex: TextStyle no Text()) SOBRESCREVE o tema.
///
/// Regra prática:
/// - Use o Theme para o padrão do app.
/// - Use estilo local apenas quando o visual depender de estado (ex: tarefa concluída riscada).
class AppTheme {
  /// Raio padrão usado em bordas (inputs, cards, botões).
  /// Ter isso aqui evita “números mágicos” repetidos pelo app.
  static const double radius = 12.0;

  /// Padding padrão das páginas (margem interna).
  static const EdgeInsets pagePadding = EdgeInsets.all(16);

  /// Tema claro (light theme).
  ///
  /// A ideia é: definir um ColorScheme base e deixar o Material 3
  /// derivar cores para componentes (botões, appbar, etc.).
  static ThemeData light() {
    // ColorScheme é o “núcleo” de cores do Material 3.
    // A partir da seedColor, o Flutter gera uma paleta coerente.
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return ThemeData(
      // Ativa o Material 3 (recomendado em Flutter moderno).
      useMaterial3: true,

      // Define as cores padrão do app.
      // Muitos widgets pegam cores daqui automaticamente.
      colorScheme: scheme,

      /// TIPOGRAFIA GLOBAL (TextTheme)
      ///
      /// TextTheme define estilos padrão para categorias de texto.
      /// Em vez de escrever TextStyle em todo Text(), você usa:
      /// Theme.of(context).textTheme.titleMedium, bodyMedium etc.
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14),
      ),

      /// ESTILO GLOBAL DO APPBAR
      ///
      /// AppBarTheme define padrão de aparência da AppBar.
      /// backgroundColor e foregroundColor vêm do ColorScheme,
      /// garantindo bom contraste e consistência.
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),

      /// TEMA DE INPUTS (TextField / TextFormField)
      ///
      /// InputDecorationTheme configura bordas, padding e comportamento visual
      /// de todos os TextFields que usam InputDecoration.
      /// Assim você não repete OutlineInputBorder em todo lugar.
      inputDecorationTheme: InputDecorationTheme(
        // Borda padrão
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        // Borda quando o campo está habilitado mas sem foco
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        // Borda quando o campo está com foco
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        // Espaçamento interno do input
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),

      /// TEMA DE FILLED BUTTON (Material 3)
      ///
      /// Define padding, shape e estilo padrão para FilledButton.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      /// TEMA DE ICON BUTTON
      ///
      /// IconButtonTheme define aparência padrão de IconButton.
      /// Aqui estamos definindo apenas shape (bordas arredondadas).
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),

      /// TEMA DE CARD (CardThemeData)
      ///
      /// CardThemeData controla padrão de Card:
      /// - elevation (sombra)
      /// - margin (margem)
      /// - shape (borda arredondada)
      ///
      /// Isso fará todas as tarefas (Cards) ficarem consistentes.
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),

      /// TEMA DE LIST TILE (ListTile)
      ///
      /// ListTileThemeData define padding de ListTile (itens da lista).
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      /// TEMA DE CHECKBOX
      ///
      /// Define formato padrão do checkbox.
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      /// TEMA DE DIVIDER
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  /// Tema escuro (dark theme).
  ///
  /// Estratégia:
  /// - Reusa o tema claro como “base”
  /// - Troca o ColorScheme para brightness dark
  /// - Ajusta detalhes (borda de input, etc.)
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    final base = light();

    return base.copyWith(
      colorScheme: scheme,

      // AppBar também pode ser ajustada no dark theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),

      dividerTheme: DividerThemeData(color: scheme.outlineVariant),

      // Ajusta bordas do input para o dark theme
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}
