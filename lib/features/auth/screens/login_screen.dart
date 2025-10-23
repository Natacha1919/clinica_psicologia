// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_scaffold.dart'; // Certifique-se de que este caminho está correto

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        if (response.user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AppScaffold()),
          );
        } else {
          setState(() {
            _errorMessage = 'Falha no login. Verifique suas credenciais.';
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocorreu um erro inesperado: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1000 : MediaQuery.of(context).size.width,
              maxHeight: isDesktop ? 600 : double.infinity,
            ),
            child: Card(
              elevation: isDesktop ? 8 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isDesktop ? 16 : 0)),
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  // Lado Esquerdo: Ilustração (visível apenas em telas maiores)
                  if (isDesktop)
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  child: Image.asset(
                                    'assets/images/logo.png', // Este caminho está correto!
                                    height: 250,
                                    fit: BoxFit.contain,
                                    // color: theme.colorScheme.onPrimary, // <<< LINHA REMOVIDA/COMENTADA
                                  ),
                                ),
                             const SizedBox(height: 20),
                              Text(
                                'Bem-vindo(a) à Clínica Escola de Psicologia!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Faça login para acessar o sistema.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Lado Direito: Formulário de Login (sempre visível)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Acesso ao Sistema', // Título mais adequado para a clínica
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            // Campo de Email
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'E-mail', // Label mais direto
                                hintText: 'seu.email@exemplo.com',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Preenchimento obrigatório.';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Por favor, insira um e-mail válido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Campo de Senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: '******', // Hint text mais seguro
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                isDense: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Preenchimento obrigatório.';
                                }
                                if (value.length < 6) {
                                  return 'A senha deve ter no mínimo 6 caracteres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Link "Esqueceu a Senha?"
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Lógica para "Esqueceu a Senha?". Pode ser um AlertDialog ou uma nova tela.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Por favor, contate o administrador para redefinir sua senha.')),
                                  );
                                },
                                child: Text(
                                  'Esqueceu a Senha?',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Mensagem de Erro Geral da Autenticação
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            // Botão Acessar
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Acessar',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 30),
                            // Versão do App      
                            Text(
                              'Versão 1.0.0 (Beta) - Construção 18.09.2025',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
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