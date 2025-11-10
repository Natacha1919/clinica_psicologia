// lib/features/financeiro/models/pagamento_model.dart
import '../../pacientes/models/paciente_dropdown_model.dart'; // Importamos o modelo leve de paciente

class PagamentoModel {
  final String id;
  final DateTime dataPagamento;
  final double valor;
  final String formaDePagto;
  
  // Opcional: Armazena os dados do paciente se eles vierem na consulta
  final PacienteDropdownModel? paciente; 

  PagamentoModel({
    required this.id,
    required this.dataPagamento,
    required this.valor,
    required this.formaDePagto,
    this.paciente, // Adicionado ao construtor
  });

  factory PagamentoModel.fromJson(Map<String, dynamic> json) {
    return PagamentoModel(
      id: json['id'] as String,
      dataPagamento: DateTime.parse(json['data_pagamento'] as String),
      valor: (json['valor'] as num).toDouble(),
      formaDePagto: json['forma_de_pagto'] as String? ?? 'Não informada',

      // Verifica se o JSON da consulta inclui o objeto 'paciente' aninhado
      // O nome 'pacientes_historico_temp' deve corresponder ao nome usado no SELECT
      // Ex: .select('*, pacientes_historico_temp:paciente_id ( id, nome_completo )')
      paciente: json['pacientes_historico_temp'] != null
          ? PacienteDropdownModel.fromJson(json['pacientes_historico_temp'])
          : null,
    );
  }
}