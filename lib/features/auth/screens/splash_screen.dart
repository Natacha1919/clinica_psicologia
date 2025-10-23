// lib/features/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app_scaffold.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Espera um pouco para a UI não piscar
    // Remover ou ajustar o delay se preferir um redirecionamento mais instantâneo
    await Future.delayed(Duration.zero);
    
    final session = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;

    if (session != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppScaffold()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}