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
    url: 'https://szklbkdgzrvqyndtxxzb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6a2xia2RnenJ2cXluZHR4eHpiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODI5MjQ1MSwiZXhwIjoyMDczODY4NDUxfQ.9vnkeqo1YLoRtCkNNhznw3aixSaiQF-LsrKgoWwOb08',
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