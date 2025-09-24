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

  final Color _primaryDark = const Color(0xFF122640);

  final List<Widget> _pages = [
    const DashboardMetricsScreen(),
    const TriagemScreen(),
    const AgendamentoScreen(),
  ];

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair: ${e.message}'),
            backgroundColor: Colors.red,
          ),
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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            minWidth: 100.0,
            selectedIndex: _selectedIndex,
            // ALTERADO: A lógica agora é mais simples, pois o botão de sair não está mais aqui
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: _primaryDark,
            elevation: 4,
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.psychology, size: 30, color: _primaryDark),
              ),
            ),
            // ALTERADO: A lista de destinos agora contém apenas as páginas de navegação
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_search_outlined),
                selectedIcon: Icon(Icons.person_search),
                label: Text('Inscritos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Agendar'),
              ),
            ],
            // NOVO: Usamos a propriedade 'trailing' para posicionar o botão de sair
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    tooltip: 'Sair',
                    onPressed: _signOut, // Ação de logout é chamada aqui
                  ),
                ),
              ),
            ),
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