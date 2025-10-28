// lib/features/alunos/screens/aluno_create_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlunoCreateScreen extends StatefulWidget {
  const AlunoCreateScreen({Key? key}) : super(key: key);

  @override
  State<AlunoCreateScreen> createState() => _AlunoCreateScreenState();
}

class _AlunoCreateScreenState extends State<AlunoCreateScreen> {
  // Chave global para identificar e validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controladores para ler os dados dos campos de texto
  final _nomeController = TextEditingController();
  final _raController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    // Limpa os controladores quando a tela é fechada
    _nomeController.dispose();
    _raController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Função chamada quando o botão "Salvar" é pressionado
  Future<void> _salvarAluno() async {
    // 1. Valida o formulário
    if (!_formKey.currentState!.validate()) {
      // Se a validação falhar (ex: nome vazio), não faz nada
      return;
    }

    // 2. Mostra o loading
    setState(() => _isLoading = true);

    // 3. Pega os dados dos controladores
    final nomeCompleto = _nomeController.text.trim();
    final ra = _raController.text.trim();
    final email = _emailController.text.trim();

    try {
      // 4. Envia os dados para o Supabase
      await Supabase.instance.client.from('alunos').insert({
        'nome_completo': nomeCompleto,
        'ra': ra.isNotEmpty ? ra : null, // Salva null se o campo estiver vazio
        'email': email.isNotEmpty ? email : null, // Salva null se o campo estiver vazio
      });

      // 5. Feedback de Sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aluno cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpa o formulário após o sucesso
        _formKey.currentState!.reset();
        _nomeController.clear();
        _raController.clear();
        _emailController.clear();
      }

    } on PostgrestException catch (e) {
      // Trata erros específicos do Supabase
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Trata erros genéricos
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ocorreu um erro inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. Esconde o loading, independentemente de sucesso ou falha
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Novo Aluno'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Limita a largura em telas grandes
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Campo Nome Completo (Obrigatório) ---
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      hintText: 'Nome completo do estagiário',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    // Validação
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O nome é obrigatório.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Campo RA (Opcional) ---
                  TextFormField(
                    controller: _raController,
                    decoration: const InputDecoration(
                      labelText: 'RA (Registro Acadêmico)',
                      hintText: 'Ex: 123456',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Campo E-mail (Opcional) ---
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'email.aluno@fecaf.com.br',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),

                  // --- Botão Salvar ---
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _salvarAluno, // Desativa o botão durante o loading
                    icon: _isLoading
                        ? const SizedBox( // Mostra o spinner
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save), // Mostra o ícone
                    label: Text(_isLoading ? 'Salvando...' : 'Salvar Aluno'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}