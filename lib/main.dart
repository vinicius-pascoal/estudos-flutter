import 'dart:convert'; // Para converter Map/List <-> JSON String

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Ponto de entrada do app.
  // runApp "desenha" o widget raiz (TodoApp) na tela.
  runApp(const TodoApp());
}

/// Widget raiz do aplicativo.
/// Aqui normalmente ficam: tema, rotas, config geral.
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Minimal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Material 3 e um esquema de cores base.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TodoPage(),
    );
  }
}

/// Modelo (classe) que representa uma tarefa.
///
/// Por que criar um "model"?
/// - Deixa o código organizado.
/// - Facilita converter para JSON (para salvar no armazenamento local).
class TodoItem {
  final String id; // Identificador único (usado pra encontrar/remover).
  final String title; // Texto da tarefa.
  final DateTime createdAt; // Data/hora de criação.
  bool done; // Se está concluída (true) ou pendente (false).

  TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.done = false,
  });

  /// Converte o objeto em um Map simples (chave/valor),
  /// ideal para depois virar JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      // DateTime não é gravável diretamente em JSON, então salvamos como String ISO
      'createdAt': createdAt.toIso8601String(),
      'done': done,
    };
  }

  /// Cria um TodoItem a partir de um Map (que veio do JSON).
  factory TodoItem.fromJson(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      done: map['done'] as bool,
    );
  }
}

/// Página principal do app.
/// É Stateful porque a lista muda (adiciona/remove/marca como done).
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // Controla o texto digitado no TextField.
  final _controller = TextEditingController();

  // Lista em memória (o que aparece na tela).
  final List<TodoItem> _items = [];

  // Chave usada para armazenar a lista no SharedPreferences.
  // Boas práticas: manter como const e com nome bem específico.
  static const String _storageKey = 'todo_items_v1';

  @override
  void initState() {
    super.initState();

    // initState é chamado uma vez quando o widget é criado.
    // Aqui é o lugar perfeito para carregar dados salvos localmente.
    _loadTodosFromLocalStorage();
  }

  @override
  void dispose() {
    // dispose é chamado quando o widget sai da tela definitivamente.
    // Sempre dispose controllers para evitar vazamento de memória.
    _controller.dispose();
    super.dispose();
  }

  /// Carrega tarefas salvas no SharedPreferences (armazenamento local).
  ///
  /// Fluxo:
  /// 1) pega o SharedPreferences
  /// 2) tenta ler uma String (JSON) usando a _storageKey
  /// 3) se existir, converte JSON -> List -> TodoItem
  /// 4) atualiza a tela com setState
  Future<void> _loadTodosFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Lê a string JSON salva anteriormente (ou null se não existir).
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.trim().isEmpty) {
      // Não há nada salvo ainda. App começa vazio.
      return;
    }

    try {
      // Converte a string JSON em uma estrutura Dart:
      // jsonDecode pode retornar List ou Map dependendo do JSON.
      final decoded = jsonDecode(jsonString);

      // Esperamos que seja uma lista de maps: List<Map<String, dynamic>>
      final list = (decoded as List)
          .cast<Map<String, dynamic>>()
          .map(TodoItem.fromJson)
          .toList();

      // Atualiza a lista do estado e redesenha a tela.
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      // Se o JSON estiver corrompido ou mudou de formato,
      // evitamos quebrar o app.
      debugPrint('Erro ao carregar tarefas: $e');
    }
  }

  /// Salva a lista atual (_items) no SharedPreferences.
  ///
  /// Estratégia:
  /// - Converte cada TodoItem em Map (toJson)
  /// - Converte a lista inteira em JSON string
  /// - Grava no SharedPreferences
  Future<void> _saveTodosToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Converte List<TodoItem> -> List<Map> -> String JSON
    final listAsMap = _items.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(listAsMap);

    await prefs.setString(_storageKey, jsonString);
  }

  /// Adiciona uma tarefa nova com o texto digitado.
  void _addTodo() {
    final text = _controller.text.trim();

    // Proteção: se o texto estiver vazio, não cria tarefa.
    if (text.isEmpty) return;

    setState(() {
      // Insert(0, ...) coloca no topo (mais recente primeiro).
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

    // Sempre que mudar a lista, salvamos localmente.
    // Não precisa estar dentro do setState (setState é só para redesenhar).
    _saveTodosToLocalStorage();
  }

  /// Alterna o status done/pendente de uma tarefa.
  void _toggleDone(String id) {
    setState(() {
      final item = _items.firstWhere((e) => e.id == id);
      item.done = !item.done;
    });

    _saveTodosToLocalStorage();
  }

  /// Remove uma tarefa.
  void _removeTodo(String id) {
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });

    _saveTodosToLocalStorage();
  }

  @override
  Widget build(BuildContext context) {
    // Calcula contadores para mostrar no topo.
    final doneCount = _items.where((e) => e.done).length;
    final pendingCount = _items.length - doneCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        actions: [
          // Se não tiver tarefas, não mostramos o contador.
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'Pendentes: $pendingCount • Feitas: $doneCount',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra superior: campo de texto + botão Add
            _AddTodoBar(controller: _controller, onAdd: _addTodo),
            const SizedBox(height: 12),

            // Expanded faz a lista ocupar o espaço restante na coluna.
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      // Quantidade de itens na lista
                      itemCount: _items.length,
                      // Um separador simples entre os itens
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _TodoTile(
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

/// Widget da barra de adicionar tarefas.
/// Separar em widget reduz bagunça na tela principal e incentiva organização.
class _AddTodoBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddTodoBar({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Expanded faz o TextField ocupar o máximo possível.
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Digite uma tarefa...',
              border: OutlineInputBorder(),
            ),
            // Ao apertar enter no teclado, adiciona também.
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: FilledButton(onPressed: onAdd, child: const Text('Add')),
        ),
      ],
    );
  }
}

/// Tile (linha) de cada tarefa.
/// Mostra: checkbox, texto e botão de deletar.
class _TodoTile extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoTile({
    required this.title,
    required this.done,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Checkbox(
          value: done,
          // onChanged recebe o novo valor, mas aqui só alternamos com onToggle.
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          title,
          style: TextStyle(
            // Se done = true, risca o texto (feedback visual de concluído).
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? Colors.black54 : null,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Remover',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        // Toque no item também alterna (mais prático).
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
    return Center(
      child: Text(
        'Sem tarefas.\nAdicione a primeira acima 👆',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
