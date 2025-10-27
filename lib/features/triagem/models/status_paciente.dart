import 'package:flutter/material.dart';

enum StatusPaciente {
  atendimentoEncerrado('ATENDIMENTO ENCERRADO', Color.fromARGB(255, 0, 17, 255)),
  emAtendimento('EM ATENDIMENTO', Colors.teal),
  triagemRealizada('TRIAGEM REALIZADA', Color.fromARGB(255, 68, 255, 143)),
  espera('EM ESPERA', Colors.amber),
  filaDeEsperaRemanescente('FILA DE ESPERA REMANESCENTE', const Color(0xFFD32F2F)); // Corrigido para ser constante

  const StatusPaciente(this.valor, this.cor);
  final String valor;
  final Color cor;
}