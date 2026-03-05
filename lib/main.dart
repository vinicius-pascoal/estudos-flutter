import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

void main() => runApp(const TodoApp());

/// Widget raiz do app.
/// Agora o estilo vem do AppTheme (centralizado).
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Minimal',
      debugShowCheckedModeBanner: false,

      // Define tema claro/escuro e segue o sistema operacional
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      home: const TodoPage(),
    );
  }
}

/// Model de tarefa + serialização (para salvar local)
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

  Future<void> _saveTodosToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
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
        padding: AppTheme.pagePadding, // vem do tema central
        child: Column(
          children: [
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

/// Barra de adicionar tarefas.
/// Observe que o TextField já herda borda/padding do InputDecorationTheme.
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
            decoration: const InputDecoration(hintText: 'Digite uma tarefa...'),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 52,
          child: FilledButton(onPressed: onAdd, child: const Text('Add')),
        ),
      ],
    );
  }
}

/// Card de tarefa.
/// Agora usamos CardTheme + ListTileTheme do tema global.
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

    // Pegamos um estilo base do Theme e só ajustamos o que muda (done/pendente).
    final baseStyle = theme.textTheme.titleMedium;
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
