// lib/features/triagem/models/status_paciente.dart

import 'package:flutter/material.dart';

// O enum agora carrega a cor e o valor de texto associado a cada status
enum StatusPaciente {
  triagem('TRIAGEM', Colors.orange),
  emAtendimento('EM ATENDIMENTO', Colors.teal),
  aguardandoVaga('AGUARDANDO VAGA', Colors.blueAccent),
  alta('ALTA', Colors.grey),
  espera('ESPERA', Colors.amber),

  desistencia('DESISTÊNCIA', const Color(0xFFD32F2F)); // <-- Linha corrigida

  const StatusPaciente(this.valor, this.cor);
  final String valor;
  final Color cor;
}