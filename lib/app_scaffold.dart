// lib/app_scaffold.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/dashboard/screens/dashboard_metrics_screen.dart';
import 'features/triagem/screens/triagem_screen.dart';
import 'features/agendamento/screens/agendamento_screen.dart';
import 'features/pacientes/screens/lista_pacientes_screen.dart';

import 'package:clinica_psicologi/features/alunos/screens/alunos_screen.dart';
import 'package:clinica_psicologi/features/financeiro/screens/financeiro_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  bool _isLoading = true;
  String _userRole = 'Usuário';
  String _fullName = '';
  
  // ===== NOVA VARIÁVEL: Lista de permissões do aluno =====
  List<String> _alunoPermissoes = []; 
  bool _isAluno = false;
  // =======================================================

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndPermissions(); 
  }

  // ===== FUNÇÃO DE CARREGAMENTO ATUALIZADA =====
  Future<void> _loadUserProfileAndPermissions() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Busca o perfil básico (Role e Nome)
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('role, full_name')
          .eq('id', user.id)
          .maybeSingle(); // maybeSingle evita erro se não existir perfil

      // 2. Busca se o email existe na tabela de ALUNOS para pegar permissões
      final alunoData = await Supabase.instance.client
          .from('alunos')
          .select('permissoes')
          .eq('email', user.email!) // Liga pelo email
          .maybeSingle();

      if (mounted) {
        setState(() {
          // Configuração do Perfil
          if (profileData != null) {
            _userRole = profileData['role'] ?? 'Usuário';
            _fullName = profileData['full_name'] ?? '';
          }
          
          // Configuração de Aluno
          if (alunoData != null) {
            _isAluno = true;
            // Converte a lista do JSON para List<String>
            _alunoPermissoes = List<String>.from(alunoData['permissoes'] ?? []);
          } else {
            _isAluno = false;
            _alunoPermissoes = [];
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar perfil/permissões: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // =============================================

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao sair: ${e.message}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const SplashScreen()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? '';
    
    final userInitial = _fullName.isNotEmpty 
        ? _fullName[0].toUpperCase() 
        : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?');

    // --- LÓGICA DE PERMISSÃO DINÂMICA ---
    
    // Listas base vazias, vamos preencher conforme a permissão
    final List<Widget> finalPages = [];
    final List<NavigationRailDestination> finalDestinations = [];

    // Função auxiliar para adicionar páginas
    void addPage(String key, Widget page, IconData icon, String label) {
      finalPages.add(page);
      finalDestinations.add(NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 24), // Ícone normal
        selectedIcon: Icon(icon, size: 28), // Ícone selecionado um pouco maior
        label: Text(label),
      ));
    }

    // 1. Verifica se é ADMIN ou COORDENAÇÃO (Vê tudo)
    bool isAdmin = _userRole == 'Coordenação' || _userRole == 'Administrador';

    // 2. Lógica para montar o menu
    
    // DASHBOARD
    if (isAdmin || _alunoPermissoes.contains('dashboard')) {
      addPage('dashboard', const DashboardMetricsScreen(), Icons.dashboard_outlined, 'Dashboard');
    }

    // INSCRITOS (Triagem)
    if (isAdmin || _alunoPermissoes.contains('inscritos')) {
      addPage('inscritos', const TriagemScreen(), Icons.inbox_outlined, 'Inscritos');
    }

    // PACIENTES
    if (isAdmin || _alunoPermissoes.contains('pacientes')) {
      addPage('pacientes', const ListaPacientesScreen(), Icons.people_outline, 'Pacientes');
    }

    // AGENDAMENTOS
    if (isAdmin || _alunoPermissoes.contains('agendamentos')) {
      addPage('agendamentos', const AgendamentoScreen(), Icons.calendar_month_outlined, 'Agendamentos');
    }

    // FINANCEIRO (Apenas Admin)
    if (isAdmin) {
      addPage('financeiro', const FinanceiroScreen(), Icons.attach_money_outlined, 'Financeiro');
    }

    // ALUNOS (Apenas Admin)
    if (isAdmin) {
      addPage('alunos', const AlunosScreen(), Icons.school_outlined, 'Alunos');
    }

    // Se não tiver permissão para nada (ex: aluno novo sem checkbox marcado)
    if (finalPages.isEmpty) {
      finalPages.add(const Center(child: Text("Sem permissões de acesso. Contate a coordenação.")));
      finalDestinations.add(const NavigationRailDestination(icon: Icon(Icons.lock), label: Text("Bloqueado")));
    }
    
    // Garante índice válido
    if (_selectedIndex >= finalPages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              extended: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              leading: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.psychology,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              destinations: finalDestinations,
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: InkWell(
                      onTap: _signOut,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            child: Text(userInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: _isLoading
                                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_userRole, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(_fullName.isNotEmpty ? _fullName : userEmail, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.logout, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: finalPages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}