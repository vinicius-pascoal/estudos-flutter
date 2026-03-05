import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

void main() => runApp(const TodoApp());

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Minimal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const TodoPage(),
    );
  }
}

class TodoItem {
  final String id;
  final String title;
  final DateTime createdAt;
  bool done;

  TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'done': done,
  };

  factory TodoItem.fromJson(Map<String, dynamic> map) => TodoItem(
    id: map['id'] as String,
    title: map['title'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    done: map['done'] as bool,
  );
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _controller = TextEditingController();
  final List<TodoItem> _items = [];

  static const String _storageKey = 'todo_items_v1';

  /// ✅ Flag do “Debug Visual”
  ///
  /// Quando true:
  /// - desenhamos bordas leves em áreas importantes (input, botão, cards)
  /// - isso ajuda a entender layout, paddings e limites de cada widget
  bool _debugVisual = false;

  @override
  void initState() {
    super.initState();
    _loadTodosFromLocalStorage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTodosToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> _loadTodosFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(jsonString);
      final list = (decoded as List)
          .cast<Map<String, dynamic>>()
          .map(TodoItem.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      debugPrint('Erro ao carregar tarefas: $e');
    }
  }

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _items.insert(
        0,
        TodoItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: text,
          createdAt: DateTime.now(),
        ),
      );
      _controller.clear();
    });

    _saveTodosToLocalStorage();
  }

  void _toggleDone(String id) {
    setState(() {
      final item = _items.firstWhere((e) => e.id == id);
      item.done = !item.done;
    });
    _saveTodosToLocalStorage();
  }

  void _removeTodo(String id) {
    setState(() => _items.removeWhere((e) => e.id == id));
    _saveTodosToLocalStorage();
  }

  /// ✅ Abre o “Debug Visual Sheet”
  ///
  /// showModalBottomSheet cria um painel que sobe por baixo.
  /// A vantagem é que ele é ótimo para “inspecionar” configurações sem sair da tela.
  void _openDebugSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        return _DebugThemeSheet(
          debugVisualEnabled: _debugVisual,
          onToggleDebugVisual: (value) {
            // Quando o usuário liga/desliga no switch,
            // atualizamos o state e a tela redesenha com/sem bordas.
            setState(() => _debugVisual = value);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final doneCount = _items.where((e) => e.done).length;
    final pendingCount = _items.length - doneCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        actions: [
          // ✅ Botão do Debug Visual (ícone de “bug”)
          IconButton(
            tooltip: 'Debug Visual',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _openDebugSheet,
          ),

          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'Pendentes: $pendingCount • Feitas: $doneCount',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: AppTheme.pagePadding,
        child: Column(
          children: [
            _AddTodoBar(
              controller: _controller,
              onAdd: _addTodo,

              // ✅ repassa a flag para desenhar bordas de debug
              debugVisual: _debugVisual,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _TodoCard(
                          title: item.title,
                          done: item.done,
                          onToggle: () => _toggleDone(item.id),
                          onDelete: () => _removeTodo(item.id),

                          // ✅ repassa a flag para desenhar bordas de debug
                          debugVisual: _debugVisual,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTodoBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  /// ✅ Se true, mostra bordas para “enxergar” o layout
  final bool debugVisual;

  const _AddTodoBar({
    required this.controller,
    required this.onAdd,
    required this.debugVisual,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Cor de borda de debug (bem discreta).
    final debugBorder = Border.all(
      width: 1,
      color: scheme.primary.withOpacity(0.35),
    );

    return DecoratedBox(
      // Bordão externa do bloco “Add bar”
      decoration: BoxDecoration(
        border: debugVisual ? debugBorder : null,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Padding(
        // Um padding leve só para a borda não “colar” no conteúdo
        padding: EdgeInsets.all(debugVisual ? 6 : 0),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                // Borda de debug do TextField
                decoration: BoxDecoration(
                  border: debugVisual ? debugBorder : null,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Digite uma tarefa...',
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              // Borda de debug do botão
              decoration: BoxDecoration(
                border: debugVisual ? debugBorder : null,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton(onPressed: onAdd, child: const Text('Add')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  /// ✅ Se true, mostra bordas para “enxergar” o layout
  final bool debugVisual;

  const _TodoCard({
    required this.title,
    required this.done,
    required this.onToggle,
    required this.onDelete,
    required this.debugVisual,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final baseStyle = theme.textTheme.titleMedium;

    // Estilo local (dinâmico) baseado em "done".
    // Esse é um exemplo de onde faz sentido sobrescrever o tema:
    // - riscar quando concluída
    // - alterar cor quando concluída
    final titleStyle = (baseStyle ?? const TextStyle()).copyWith(
      decoration: done ? TextDecoration.lineThrough : null,
      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
    );

    final debugBorder = Border.all(
      width: 1,
      color: scheme.secondary.withOpacity(0.35),
    );

    return DecoratedBox(
      // Borda de debug do Card inteiro
      decoration: BoxDecoration(
        border: debugVisual ? debugBorder : null,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Padding(
        padding: EdgeInsets.all(debugVisual ? 4 : 0),
        child: Card(
          child: ListTile(
            leading: Checkbox(value: done, onChanged: (_) => onToggle()),
            title: Text(title, style: titleStyle),
            trailing: IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
            onTap: onToggle,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        'Sem tarefas.\nAdicione a primeira acima 👆',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium,
      ),
    );
  }
}

/// ✅ Bottom sheet do Debug Visual
///
/// Ele tem duas funções:
/// 1) Explicar “o que vem do Theme” vs “o que é estilo local”
/// 2) Permitir ligar/desligar as bordas (debugVisual)
class _DebugThemeSheet extends StatelessWidget {
  final bool debugVisualEnabled;
  final ValueChanged<bool> onToggleDebugVisual;

  const _DebugThemeSheet({
    required this.debugVisualEnabled,
    required this.onToggleDebugVisual,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug Visual', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Aqui você inspeciona de onde vêm os estilos (Theme vs Local) e pode ligar bordas para enxergar o layout.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Switch que liga/desliga o modo visual
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar bordas de debug'),
              subtitle: const Text(
                'Desenha bordas nos blocos (input, botão, cards).',
              ),
              value: debugVisualEnabled,
              onChanged: onToggleDebugVisual,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              '1) Estilos Globais (ThemeData)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Vêm de lib/app_theme.dart e afetam o app inteiro:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _Bullet('Cores: ColorScheme.fromSeed(seedColor: indigo)'),
            _Bullet('Textos: textTheme (titleLarge/titleMedium/bodyMedium)'),
            _Bullet('Inputs: inputDecorationTheme (bordas/padding)'),
            _Bullet('Botões: filledButtonTheme (shape/padding/textStyle)'),
            _Bullet('Cards: cardTheme (shape/elevation)'),
            _Bullet('ListTile: listTileTheme (padding)'),
            const SizedBox(height: 12),

            Text('Cores (ColorScheme)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ColorSwatch(
                  label: 'primary',
                  color: scheme.primary,
                  onColor: scheme.onPrimary,
                ),
                _ColorSwatch(
                  label: 'secondary',
                  color: scheme.secondary,
                  onColor: scheme.onSecondary,
                ),
                _ColorSwatch(
                  label: 'surface',
                  color: scheme.surface,
                  onColor: scheme.onSurface,
                ),
                _ColorSwatch(
                  label: 'error',
                  color: scheme.error,
                  onColor: scheme.onError,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              '2) Estilos Locais (sobrescrevem o Theme)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No app, o principal estilo local é o título da tarefa, que muda com o estado done:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            // Demonstração visual do estilo local “done vs pending”
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Pendente: usa titleMedium do tema',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Exemplo de tarefa pendente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    decoration: null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Concluída: aplica lineThrough + cor onSurfaceVariant',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Exemplo de tarefa concluída',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              '3) “Onde isso aparece no código?”',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _Bullet('Theme global: AppTheme.light()/dark() em MaterialApp'),
            _Bullet(
              'Leitura do tema: Theme.of(context) e theme.colorScheme/textTheme',
            ),
            _Bullet(
              'Estilo local: titleStyle no _TodoCard (done risca o texto)',
            ),
            _Bullet('Debug visual: bordas controladas pela flag _debugVisual'),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: scheme.onSurfaceVariant)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final Color onColor;

  const _ColorSwatch({
    required this.label,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Text(
        label,
        style: TextStyle(color: onColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
