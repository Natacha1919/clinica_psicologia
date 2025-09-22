// lib/app_scaffold.dart

import 'package:flutter/material.dart';
import 'features/dashboard/screens/dashboard_metrics_screen.dart';
import 'features/triagem/screens/triagem_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  // Lista de todas as páginas que nosso app terá
  final List<Widget> _pages = [
    const TriagemScreen(),        // Página de índice 0
    const DashboardMetricsScreen(), // Página de índice 1
    // Adicione futuras páginas aqui. Ex: Agendamentos, Pagamentos, etc.
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ===================================
          //  O MENU LATERAL FIXO E PERMANENTE
          // ===================================
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).canvasColor,
            elevation: 2,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircleAvatar(
                radius: 30,
                child: Icon(Icons.psychology, size: 30), // Ícone representativo
              ),
            ),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.person_search_outlined),
                selectedIcon: Icon(Icons.person_search),
                label: Text('Triagem'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Dashboard'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // =========================================================
          //  A ÁREA DE CONTEÚDO QUE MUDA CONFORME O MENU
          // =========================================================
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}