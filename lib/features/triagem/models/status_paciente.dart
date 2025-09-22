// lib/features/triagem/models/status_paciente.dart

import 'dart:ui';

import 'package:flutter/material.dart';

// Agora nosso enum também carrega a cor associada a cada status
enum StatusPaciente {
  triagem('TRIAGEM', Colors.orange),
  emAtendimento('EM ATENDIMENTO', Colors.teal),
  aguardandoVaga('AGUARDANDO VAGA', Colors.blueAccent),
  alta('ALTA', Colors.grey),
  espera('ESPERA', Colors.red);

  const StatusPaciente(this.valor, this.cor);
  final String valor;
  final Color cor;
}
