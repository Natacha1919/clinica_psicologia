// lib/app_scaffold.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/dashboard/screens/dashboard_metrics_screen.dart';
import 'features/triagem/screens/triagem_screen.dart';
import 'features/agendamento/screens/agendamento_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;
  Future<Map<String, dynamic>?>? _userProfileFuture;

  final List<Widget> _pages = [
    const DashboardMetricsScreen(),
    const TriagemScreen(),
    const AgendamentoScreen(),
    const Center(child: Text('Tela de Financeiro em construção')),
  ];

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile();
  }

  // NOVO: Função para buscar o perfil do usuário na tabela 'profiles'
  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role, full_name')
          .eq('id', user.id)
          .single();
      return response;
    } catch (e) {
      debugPrint("Erro ao buscar perfil: $e");
      return null;
    }
  }

  Future<void> _signOut() async {
    // ... (código do signOut não muda)
  }

  @override
  Widget build(BuildContext context) {
    // A lógica das páginas e destinos dinâmicos foi movida para dentro do FutureBuilder
    // para garantir que temos o 'role' antes de construir o menu.

    return Scaffold(
      body: Row(
        children: [
          // O FutureBuilder agora constrói o NavigationRail
          FutureBuilder<Map<String, dynamic>?>(
            future: _userProfileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Mostra uma versão simplificada do menu enquanto carrega o perfil
                return Container(width: 250, color: Theme.of(context).colorScheme.primary, child: const Center(child: CircularProgressIndicator()));
              }

              final userProfile = snapshot.data;
              final userRole = userProfile?['role'] as String? ?? 'Usuário';

              final user = Supabase.instance.client.auth.currentUser;
              final userEmail = user?.email ?? 'carregando...';
              final userInitial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?';

              // --- LÓGICA DE PERMISSÃO ---
              final List<Widget> availablePages = [
                const DashboardMetricsScreen(),
                const TriagemScreen(),
                const AgendamentoScreen(),
              ];
              final List<NavigationRailDestination> availableDestinations = [
                const NavigationRailDestination(padding: EdgeInsets.zero, icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                const NavigationRailDestination(padding: EdgeInsets.zero, icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Pacientes')),
                const NavigationRailDestination(padding: EdgeInsets.zero, icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Agendamentos')),
              ];

              if (userRole == 'Coordenação' || userRole == 'Administrador') {
                availablePages.add(const Center(child: Text('Tela de Financeiro em construção')));
                availableDestinations.add(const NavigationRailDestination(padding: EdgeInsets.zero, icon: Icon(Icons.attach_money_outlined), selectedIcon: Icon(Icons.attach_money), label: Text('Financeiro')));
              }
              
              // Garante que o índice selecionado não cause erro
              if (_selectedIndex >= availablePages.length) {
                _selectedIndex = 0;
              }

              return SizedBox(
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
                            child: Icon(Icons.psychology, size: 24, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  destinations: availableDestinations,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(userRole, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(userEmail, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12), overflow: TextOverflow.ellipsis),
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
              );
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}