// lib/core/widgets/session_guard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionGuard extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const SessionGuard({
    super.key,
    required this.child,
    // Define o tempo padrão para 15 minutos (ajuste conforme necessário)
    this.timeoutDuration = const Duration(minutes: 15),
  });

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Inicia ou Reinicia o cronômetro de inatividade
  void _startTimer() {
    _timer?.cancel(); // Cancela o anterior se existir
    
    // Só inicia o timer se houver um usuário logado
    if (Supabase.instance.client.auth.currentUser != null) {
      _timer = Timer(widget.timeoutDuration, _handleTimeout);
    }
  }

  /// Detecta interação do usuário e reseta o tempo
  void _handleInteraction([dynamic _]) {
    // Se o usuário tocou ou moveu o mouse, reiniciamos a contagem
    _startTimer();
  }

  /// Ocorre quando o tempo acaba
  Future<void> _handleTimeout() async {
    final user = Supabase.instance.client.auth.currentUser;
    
    // Se ainda houver usuário, fazemos logout
    if (user != null) {
      try {
        await Supabase.instance.client.auth.signOut();
        
        // Opcional: Mostrar um aviso (Snackbar)
        // Nota: Como o AuthGate vai mudar a tela imediatamente, 
        // pode ser que o snackbar apareça na tela de login.
        debugPrint("Sessão expirada por inatividade.");
      } catch (e) {
        debugPrint("Erro ao fazer logout automático: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // O Listener envolve toda a aplicação e detecta toques/cliques
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleInteraction, // Clique/Toque
      onPointerMove: _handleInteraction, // Movimento do mouse/arrastar
      onPointerHover: _handleInteraction, // Mouse passando por cima (Web)
      child: widget.child,
    );
  }
}