import 'package:flutter/material.dart';

enum StatusPaciente {
  triagem('Encerrou com a Clínica', Color.fromARGB(255, 0, 17, 255)),
  emAtendimento('EM ATENDIMENTO', Colors.teal),
  aguardandoVaga('AGUARDANDO VAGA', Colors.blueAccent),
  alta('ALTA', Colors.grey),
  espera('ESPERA', Colors.amber),
  desistencia('DESISTÊNCIA', const Color(0xFFD32F2F)); // Corrigido para ser constante

  const StatusPaciente(this.valor, this.cor);
  final String valor;
  final Color cor;
}