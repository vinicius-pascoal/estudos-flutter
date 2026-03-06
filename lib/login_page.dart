import 'package:flutter/material.dart';

import 'main.dart'; // Importa a TodoPage (que está no main.dart)

/// Tela de login mockada (fake).
///
/// Objetivo didático:
/// - Mostrar como construir uma tela com inputs + validação simples
/// - Demonstrar navegação: Login -> TodoPage
///
/// IMPORTANTE:
/// - Não existe backend aqui.
/// - A validação é apenas comparar com credenciais fixas (mock).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Credenciais mockadas (troque como quiser)
  static const String _mockUser = 'admin';
  static const String _mockPass = '1234';

  // Controllers para ler o texto digitado nos TextFields
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  // Estado visual de erro e loading (boa prática mesmo em mock)
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    // Sempre dar dispose em controllers para evitar vazamento
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// Faz o "login" verificando se usuário/senha batem com os mocks.
  ///
  /// pushReplacement:
  /// - Remove a tela atual (login) da pilha de navegação
  /// - Evita voltar para o login ao apertar "voltar"
  Future<void> _login() async {
    final user = _userController.text.trim();
    final pass = _passController.text;

    // Limpa mensagem de erro anterior
    setState(() {
      _error = null;
      _loading = true;
    });

    // Simula uma pequena latência (como se fosse rede)
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final ok = (user == _mockUser && pass == _mockPass);

    if (!mounted) return;

    if (!ok) {
      // Falhou: mostra erro e reabilita o botão
      setState(() {
        _error = 'Usuário ou senha inválidos. Tente: admin / 1234';
        _loading = false;
      });
      return;
    }

    // Sucesso: navega para a lista de tarefas e substitui a tela
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TodoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          // Mantém o card de login com largura “bonita” no desktop/web
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Entrar', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),

                    // Usuário
                    TextField(
                      controller: _userController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        hintText: 'Ex: admin',
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Senha
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        hintText: 'Ex: 1234',
                      ),
                      onSubmitted: (_) => _loading ? null : _login(),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Mensagem de erro (quando existir)
                    if (_error != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _loading ? null : _login,
                        child: Text(_loading ? 'Entrando...' : 'Entrar'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Dica didática / credenciais de teste
                    Text(
                      'Teste: admin / 1234',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}