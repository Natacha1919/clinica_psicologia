// lib/main.dart

import 'package:clinica_psicologi/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart'; // NOVO: Importa nosso arquivo de tema
import 'features/auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  await Supabase.initialize(
    url: 'https://nwjrdmnlkdlfcgtvcsux.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53anJkbW5sa2RsZmNndHZjc3V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTQxNDgsImV4cCI6MjA3NjYzMDE0OH0.eQa1p9YtSlvR9AXw-ZJgaE9xHROy1qJY9IWaPvZgUJU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Escola Psicologia',
      // ALTERADO: Aplicando nosso novo tema
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}