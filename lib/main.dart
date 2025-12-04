// lib/main.dart

import 'package:clinica_psicologi/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ===== ADIÇÃO 1: Importar o SessionGuard =====
import 'core/widgets/session_guard.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nwjrdmnlkdlfcgtvcsux.supabase.co', // Mantenha seu URL atual
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53anJkbW5sa2RsZmNndHZjc3V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTQxNDgsImV4cCI6MjA3NjYzMDE0OH0.eQa1p9YtSlvR9AXw-ZJgaE9xHROy1qJY9IWaPvZgUJU', // Mantenha sua Anon Key atual
  );

runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Escola de Psicologia',
      debugShowCheckedModeBanner: false,
      
      // ===== AQUI ESTÁ A MUDANÇA =====
      // Em vez de definir o tema aqui, usamos a classe AppTheme
      theme: AppTheme.lightTheme, 
      // ===============================

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), 
      ],

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return SessionGuard(
            timeoutDuration: const Duration(minutes: 15), 
            child: const AppScaffold(),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}