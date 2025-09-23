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

  final Color _primaryDark = const Color(0xFF122640);

  // 👈 MUDANÇA AQUI: A ORDEM DA LISTA DE PÁGINAS FOI ALTERADA
  final List<Widget> _pages = [
    const DashboardMetricsScreen(), // Página de índice 0 (AGORA É O DASHBOARD)
    const TriagemScreen(),        // Página de índice 1 (AGORA É A TRIAGEM)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            minWidth: 100.0,
            selectedIndex: _selectedIndex,
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
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.psychology, size: 30, color: _primaryDark),
              ),
            ),
            // 👈 MUDANÇA AQUI: A ORDEM DOS BOTÕES DO MENU FOI ALTERADA PARA CORresponder
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
            ],
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