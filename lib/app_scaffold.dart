// lib/app_scaffold.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/dashboard/screens/dashboard_metrics_screen.dart';
import 'features/triagem/screens/triagem_screen.dart';
import 'features/agendamento/screens/agendamento_screen.dart';
import 'features/pacientes/screens/lista_pacientes_screen.dart';

// ===== ADIÇÃO 1: Importar as telas de Alunos e Financeiro =====
import 'package:clinica_psicologi/features/alunos/screens/alunos_screen.dart';
import 'package:clinica_psicologi/features/financeiro/screens/financeiro_screen.dart'; // <-- LINHA ADICIONADA

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  // Variáveis de estado para guardar as informações do perfil
  bool _isProfileLoading = true;
  String _userRole = 'Usuário';
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Chama a função para buscar o perfil ao iniciar a tela
  }

  // Nova função para buscar os dados na tabela 'profiles'
  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isProfileLoading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role, full_name')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userRole = data['role'] ?? 'Usuário';
          _fullName = data['full_name'] ?? '';
          _isProfileLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao buscar perfil do usuário: $e');
      if (mounted) {
        setState(() {
          // Mantém os valores padrão em caso de erro
          _isProfileLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao sair: ${e.message}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );
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

    // --- LÓGICA DE PERMISSÃO ---
    final List<Widget> availablePages = [
      const DashboardMetricsScreen(),
      const TriagemScreen(), // Tela de "Inscritos"
      const ListaPacientesScreen(),
      const AgendamentoScreen(),
    ];
    final List<NavigationRailDestination> availableDestinations = [
      const NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
        label: Text('Inscritos'),
      ),
      const NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Pacientes'),
      ),
      const NavigationRailDestination(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: Text('Agendamentos'),
      ),
    ];

    // ===== ADIÇÃO 2: Lógica de permissão para Alunos e Financeiro =====
    // Adicionamos as novas telas se o usuário for Admin ou Coordenação
    if (_userRole == 'Coordenação' || _userRole == 'Administrador') {
      
      // Tela de Financeiro (Substituído o placeholder)
      availablePages.add(const FinanceiroScreen()); // <-- ESTA É A CORREÇÃO
      availableDestinations.add(
        const NavigationRailDestination(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.attach_money_outlined),
          selectedIcon: Icon(Icons.attach_money),
          label: Text('Financeiro'),
        ),
      );

      // Tela de Cadastro de Aluno
      availablePages.add(const AlunosScreen()); // Adiciona a tela
      availableDestinations.add(
        const NavigationRailDestination(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.school_outlined), // Ícone para "Alunos"
          selectedIcon: Icon(Icons.school),
          label: Text('Alunos'), // Texto do menu
        ),
      );
      // =======================================================
    }
    
    // Garantia para não quebrar o índice caso o usuário mude
    if (_selectedIndex >= availablePages.length) {
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
              destinations: availableDestinations, // <- A lista já está atualizada
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
                            child: _isProfileLoading
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
          // O corpo da tela agora é dinâmico, baseado na lista
          Expanded(
            child: availablePages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}