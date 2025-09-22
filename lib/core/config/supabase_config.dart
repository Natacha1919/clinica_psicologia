// lib/core/config/supabase_config.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      // Cole a URL do seu projeto Supabase aqui
      url: 'https://szklbkdgzrvqyndtxxzb.supabase.co',
      
      // Cole a chave 'anon' (pública) do seu projeto aqui
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6a2xia2RnenJ2cXluZHR4eHpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyOTI0NTEsImV4cCI6MjA3Mzg2ODQ1MX0.fKziHJmYDOEwEh1XlOs9OhQwOTvPSViqd7LDkCV1t1Y',
    );
  }

  // Atalho para acessar o cliente do Supabase de qualquer lugar do app
  static SupabaseClient get client => Supabase.instance.client;
}