import 'package:clinica_psicologi/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase
  await Supabase.initialize(
    url: 'https://szklbkdgzrvqyndtxxzb.supabase.co', // substitua pelo seu URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6a2xia2RnenJ2cXluZHR4eHpiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODI5MjQ1MSwiZXhwIjoyMDczODY4NDUxfQ.9vnkeqo1YLoRtCkNNhznw3aixSaiQF-LsrKgoWwOb08',                     // substitua pela sua anon key
  );

   // Inicia o app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Escola Psicologia',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        navigationRailTheme: const NavigationRailThemeData(
          indicatorColor: Color(0xFFB2DFDB),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AppScaffold(),
    );
  }
}