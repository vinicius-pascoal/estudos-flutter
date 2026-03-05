import 'dart:convert'; // Converte objetos Dart <-> JSON (String)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// main é o ponto de entrada do app.
/// runApp injeta o widget raiz na árvore de widgets do Flutter.
void main() => runApp(const TodoApp());

/// Widget raiz do app.
/// Aqui definimos o tema global e a tela inicial.
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Minimal',
      debugShowCheckedModeBanner: false,

      /// THEMES
      /// - theme: tema claro
      /// - darkTheme: tema escuro
      /// - themeMode: define qual usar (system segue o SO)
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      /// home é a tela inicial do app
      home: const TodoPage(),
    );
  }
}

/// MODEL: representa uma tarefa.
/// Ter um Model facilita:
/// - organizar o código
/// - converter para JSON (salvar local)
/// - futuramente adicionar campos (prioridade, tags, etc.)
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

  /// Converte objeto em Map (facilmente serializável para JSON).
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'done': done,
  };

  /// Cria objeto a partir de Map (vindo do JSON).
  factory TodoItem.fromJson(Map<String, dynamic> map) => TodoItem(
    id: map['id'] as String,
    title: map['title'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    done: map['done'] as bool,
  );
}

/// Página principal: precisa ser Stateful porque a lista muda.
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  /// Controla o texto digitado no TextField.
  /// Você lê controller.text e pode limpar com controller.clear()
  final _controller = TextEditingController();

  /// Lista que vive em memória e alimenta a UI.
  final List<TodoItem> _items = [];

  /// Chave usada para salvar/ler a lista do SharedPreferences.
  static const String _storageKey = 'todo_items_v1';

  @override
  void initState() {
    super.initState();

    /// initState roda UMA vez quando o widget nasce.
    /// Lugar ideal para carregar dados do armazenamento local.
    _loadTodosFromLocalStorage();
  }

  @override
  void dispose() {
    /// Dispose é importante para evitar vazamento de memória.
    _controller.dispose();
    super.dispose();
  }

  /// ====== PERSISTÊNCIA LOCAL ======
  ///
  /// SharedPreferences guarda dados simples no dispositivo:
  /// - String, int, double, bool, List<String>
  ///
  /// Como precisamos salvar uma lista de tarefas, usamos JSON:
  /// 1) _items (List<TodoItem>) -> List<Map> (toJson)
  /// 2) List<Map> -> String JSON (jsonEncode)
  /// 3) Salva a String JSON no prefs.
  Future<void> _saveTodosToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Carrega do SharedPreferences:
  /// 1) lê a String JSON
  /// 2) jsonDecode -> List dinâmica
  /// 3) cada item vira TodoItem.fromJson
  /// 4) setState para redesenhar a tela
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
      /// Se o JSON estiver inválido, evitamos crash.
      debugPrint('Erro ao carregar tarefas: $e');
    }
  }

  /// ====== AÇÕES DO APP ======

  /// Adiciona tarefa usando o texto do input.
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

    /// Persistimos após alterar a lista.
    _saveTodosToLocalStorage();
  }

  /// Alterna done/pendente.
  void _toggleDone(String id) {
    setState(() {
      final item = _items.firstWhere((e) => e.id == id);
      item.done = !item.done;
    });

    _saveTodosToLocalStorage();
  }

  /// Remove tarefa por id.
  void _removeTodo(String id) {
    setState(() => _items.removeWhere((e) => e.id == id));
    _saveTodosToLocalStorage();
  }

  @override
  Widget build(BuildContext context) {
    /// Theme.of(context) permite acessar o tema global.
    /// Ele é usado para pegar cores e estilos definidos em AppTheme.
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final doneCount = _items.where((e) => e.done).length;
    final pendingCount = _items.length - doneCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        actions: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'Pendentes: $pendingCount • Feitas: $doneCount',

                  /// Aqui usamos o TextTheme global e só mudamos cor.
                  /// Isso mantém consistência de fonte/tamanho.
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        /// Usa padding padrão centralizado no tema.
        padding: AppTheme.pagePadding,
        child: Column(
          children: [
            /// Barra para adicionar tarefas.
            _AddTodoBar(controller: _controller, onAdd: _addTodo),
            const SizedBox(height: 12),

            Expanded(
              child: _items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _items[index];

                        /// Cada tarefa é um Card estilizado pelo CardThemeData.
                        return _TodoCard(
                          title: item.title,
                          done: item.done,
                          onToggle: () => _toggleDone(item.id),
                          onDelete: () => _removeTodo(item.id),
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

/// Widget da barra superior: input + botão.
/// Ele herda estilo de input e botão do tema (InputDecorationTheme e FilledButtonTheme).
class _AddTodoBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddTodoBar({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,

            /// Aqui não definimos border/padding manualmente.
            /// O visual vem do InputDecorationTheme (no AppTheme).
            decoration: const InputDecoration(hintText: 'Digite uma tarefa...'),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 52,
          child: FilledButton(
            /// O estilo do FilledButton (shape/padding/textStyle)
            /// vem do filledButtonTheme em AppTheme.
            onPressed: onAdd,
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}

/// Card visual de uma tarefa.
/// Usa Card (estilizado pelo CardThemeData) + ListTile (estilizado pelo ListTileTheme).
class _TodoCard extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoCard({
    required this.title,
    required this.done,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    /// Pega um estilo base do tema para manter consistência.
    final baseStyle = theme.textTheme.titleMedium;

    /// Estilo final do título depende do estado "done".
    /// Aqui é um bom exemplo de estilo local (dinâmico):
    /// - se concluída: risca e muda cor
    /// - se pendente: normal
    final titleStyle = (baseStyle ?? const TextStyle()).copyWith(
      decoration: done ? TextDecoration.lineThrough : null,
      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
    );

    return Card(
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
    );
  }
}

/// Estado vazio quando não há tarefas.
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
